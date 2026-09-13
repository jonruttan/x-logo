; indent.x -- Indent-to-blocks pre-processor
;
; Converts indented lines to nested block structures. Flat tokens pass through
; unchanged; indented tokens are grouped into blocks by indent level. The
; column measurement and the pop/push stack live in x/reader/indent now; what
; is left here is Logo's own policy -- what a block is and where the tokens go.
;
; Two policy answers, stated rather than implied by a loop:
;
;   tab stop 1      a tab is one column. Set in logo/types.x, where the
;                   measuring happens.
;   mismatch open   a line dedenting to a column no open block sits at opens a
;                   block there -- a genuine choice, where Python raises and
;                   x-sweet unwinds past it.
(import logo/types)
(import x/reader/indent)
; Fetch the type prims from the catalog (ns `type` is de-registered, R5).
(def %type? (prim-ref 'type '?))


(def %logo-indent-to-blocks
  (fn (_ tokens)
    ; One accumulator per open level, innermost first, each holding its tokens
    ; reversed. The COLUMNS are the indenter's; only the tokens are ours.
    (def ind (Indent make 1 (lit open)))

    (def %close-one
      (fn (_ accs)
        (def block (%make-indent-block (List reverse (first accs))))
        (pair (pair block (first (rest accs))) (rest (rest accs)))))

    ; feed's contract -- zero or more `close`, then exactly one `open` or
    ; `same` -- is what lets this be a fold. The old %pop-to had to count the
    ; levels a dedent crossed and then ask separately whether it had landed on
    ; one; both questions are answered in the event list now.
    (def %apply
      (fn (self evs accs tok)
        (if (null? evs)
          accs
          (if (eq? (first evs) (lit close))
            (self (rest evs) (%close-one accs) tok)
            (if (eq? (first evs) (lit open))
              (self (rest evs) (pair (list tok) accs) tok)
              (self (rest evs)
                (pair (pair tok (first accs)) (rest accs)) tok))))))

    (def %process
      (fn (self toks accs)
        (if (null? toks)
          ; End of input closes what is still open. close-all reports the
          ; closes and nothing else -- there is no line to continue.
          (%apply (ind close-all) accs ())
          (let ((tok (first toks)))
            (if (%type? tok %logo-indent)
              (self (rest toks) (%apply (ind feed (first (first tok))) accs tok))
              ; Not an indent token: it joins the line already being built, and
              ; the indenter never hears about it.
              (self (rest toks)
                (pair (pair tok (first accs)) (rest accs))))))))

    (List reverse (first (%process tokens (list ()))))))

(provide logo/indent %logo-indent-to-blocks)
