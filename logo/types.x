; types.x -- Logo tokenizer base and type definitions
(import logo/state)
; Fetch the tokenizer prims from the catalog (ns `buf`/`tok` are de-registered, R5).
(def %buffer-token (prim-ref 'buf 'tok))
(def %token-read (prim-ref 'tok 'read))

; Fetch the type-system helpers from the catalog (registered by sys/type.x).
(def %type-io (prim-ref 'type 'io))

; The analyser states are realized by the platform's lexer (x/reader/lexer):
; native code when the assembler lane is open, interpreted twins otherwise.
(import x/reader/lexer)
; #520: the leading-whitespace measurement is shared now. Reader-context, so the
; raw ref is cached rather than dispatched.
(import x/reader/indent)
(def %indent-scan-ref (prim-ref 'indent 'scan))
(import x/type/str)
; Fetch the type prims from the catalog (ns `type` is de-registered, R5).
(def %make-instance (prim-ref 'type 'make-instance))
(def %make-type (prim-ref 'type 'make))
(def %type-of (prim-ref 'type 'of))
(def %type? (prim-ref 'type '?))
; Fetch the char/int casts from the catalog (ns `char`/`int` utility members de-registered, R5).
(def %char->integer (prim-ref 'char '->int))



; ============================================================
; Type helpers
; ============================================================

(def %logo-block-close (pair 'logo-block-close ()))
; Truncation marker: returned (never raised -- ops are banned inside
; x_token_read) by LOGO-OPEN when the stream ends inside a block.  The
; entry layer turns it into an "Unterminated input" raise OUTSIDE the
; reader; on read-str paths it lands in the token list, where dispatch
; skips it like any wordless token (no worse than the old silent close).
(def %logo-truncated (pair 'logo-truncated ()))
(def %logo-paren-label 'logo-paren)

(def %logo-alpha?
  (fn (_ chr)
    (or (and (>= chr 65) (<= chr 90))
        (and (>= chr 97) (<= chr 122)))))

; Forward declarations (set! by dispatch.x/expr.x)
(def %logo ())
(def %logo-indent ())
(def %logo-block ())
(def %logo-op ())
(def %logo-string ())
(def logo-process-tokens ())
(def logo-process-to ())
(def %logo-vars ())
(def %logo-commands ())

; ============================================================
; Whitespace type detection
; ============================================================

(def %is-ws-type?
  (fn (_ entry)
    (def io (%type-io (rest entry)))
    (def delimit (first (first (rest io))))
    (def read-h (first (first (rest (rest io)))))
    (if (null? delimit) #f (null? read-h))))

; ============================================================
; The analyser states, as forms
; ============================================================
;
; Every state is one (fn (me buffer score chr) ...) form in the assembler
; lane's dialect -- nested if, and, or, me for the self loop, the buffer and
; score doors, a free variable for another state -- handed to (Lexer state
; form fvars): native code when the lane is open, the interpreted twin of
; the same form otherwise.  The forms are data here; the states are made with
; the base below, since a compiled state is process state as the base is,
; and held in %logo-states, since the collector does not see a compiled
; state through the base.  Accepting unreads the byte that ended the token
; and scores; taking keeps it.

; the next byte ends the token, whatever it is
(def %logo-f-accept
  '(fn (me buffer score chr) (%seq (%buffer-unread buffer) (%score-set score 1 buffer))))

; one byte: ] [ newline ( )
(def %logo-f-byte
  (fn (_ b)
    (list 'fn '(me buffer score chr) (list 'if (list '= 'chr b) 'accept ()))))

; a word: letters, digits, . and ? after a letter
(def %logo-f-word
  '(fn (me buffer score chr)
     (if (or (and (>= chr 65) (<= chr 90)) (and (>= chr 97) (<= chr 122))
             (= chr 46) (= chr 63) (and (>= chr 48) (<= chr 57)))
       me
       (%seq (%buffer-unread buffer) (%score-set score 1 buffer)))))
(def %logo-f-word-open
  '(fn (me buffer score chr)
     (if (or (and (>= chr 65) (<= chr 90)) (and (>= chr 97) (<= chr 122))) word ())))

; spaces and tabs
(def %logo-f-ws
  '(fn (me buffer score chr)
     (if (or (= chr 32) (= chr 9)) me
       (%seq (%buffer-unread buffer) (%score-set score 1 buffer)))))
(def %logo-f-ws-open
  '(fn (me buffer score chr) (if (or (= chr 32) (= chr 9)) ws ())))

; a newline, then spaces and tabs, then a word
(def %logo-f-indent-after
  '(fn (me buffer score chr)
     (if (or (= chr 32) (= chr 9)) me
       (if (or (and (>= chr 65) (<= chr 90)) (and (>= chr 97) (<= chr 122))) word ()))))
(def %logo-f-indent-open
  '(fn (me buffer score chr) (if (= chr 10) after ())))

; operators: + - * / ^ = , alone; < may go on as <- <= <>; > as >=
(def %logo-f-op-open
  '(fn (me buffer score chr)
     (if (or (= chr 43) (= chr 45) (= chr 42) (= chr 47) (= chr 94) (= chr 61) (= chr 44))
       accept
       (if (= chr 60) lt (if (= chr 62) gt ())))))
(def %logo-f-op-lt
  '(fn (me buffer score chr)
     (if (or (= chr 45) (= chr 61) (= chr 62))
       (%score-set score 1 buffer)
       (%seq (%buffer-unread buffer) (%score-set score 1 buffer)))))
(def %logo-f-op-gt
  '(fn (me buffer score chr)
     (if (= chr 61)
       (%score-set score 1 buffer)
       (%seq (%buffer-unread buffer) (%score-set score 1 buffer)))))

; "...": the closing quote taken, a newline inside is no string
(def %logo-f-string-body
  '(fn (me buffer score chr)
     (if (= chr 34) (%score-set score 1 buffer) (if (= chr 10) () me))))
(def %logo-f-string-open
  '(fn (me buffer score chr) (if (= chr 34) body ())))

; ; to the end of the line, the newline left
(def %logo-f-semi-body
  '(fn (me buffer score chr)
     (if (= chr 10) (%seq (%buffer-unread buffer) (%score-set score 1 buffer)) me)))
(def %logo-f-semi-open
  '(fn (me buffer score chr) (if (= chr 59) body ())))

; the states the last base make realized, and how many the lane compiled
(def %logo-states ())
(def %logo-compiled 0)

(def %logo-st
  (fn (_ form fvars)
    (let ((r (Lexer state form fvars)))
      (do (set! %logo-states (pair (first r) %logo-states))
          (if (rest r) (set! %logo-compiled (+ %logo-compiled 1)) ())
          (first r)))))

; ============================================================
; Logo tokenizer base
; ============================================================

; The base is process state, so this is a builder, not just a build. (Base
; make) allocates a base on a chain of its own that the ambient heap cannot
; name, so a state image cannot carry %logo-base or its type handles: the
; writer nils them in its child (the transient below) and calls this again once
; the image is loaded (the recache hook), the same call that makes them here.
; entry.x's doors bind prims into whatever base this last returned.
(def %logo-base-make
  (fn (_)
  ; The RAW base: logo walks the spine directly (the %cell walk below,
  ; entry.x's filein path) and hands it to the raw tok/buf prims per
  ; token, so it holds the raw field; Base statics accept it as-is.
  (let ((%inst (Base make)))
    (def base (%inst raw))
    ; The type-alist CELL by its declared route, not by a layout walk: the
    ; walk encoded x-engine-c's spine, and decision L1 leaves each engine
    ; its own -- the route door resolves whichever engine is underneath.
    (def %cell (%inst cell 'type-alist))
    (def %int-name (%type-of 0))
    (def %float-name (%type-of (Float from 0)))
    ; Keep only INTEGER and FLOAT from the base. A local walker, renamed off the
    ; boot %filter it shadowed (#227): the alist walked here lives in the
    ; fresh child base, and type labels are per-base, so the canonical %filter's
    ; pair?/%as-list type-tests misclassify foreign-base objects. Raw first/rest
    ; access is the contract.
    (def %logo-type-keep
      (fn (self al)
        (if (null? al) ()
          (let ((name (first (first al))))
            (if (or (eq? name %int-name) (eq? name %float-name))
              (pair (first al) (self (rest al)))
              (self (rest al)))))))
    (%set-first! %cell (%logo-type-keep (first %cell)))

    ; The states, each made before the one that hands to it, since a form
    ; names another state as a free variable bound at make.
    (set! %logo-states ())
    (set! %logo-compiled 0)
    (def accept (%logo-st %logo-f-accept ()))
    (def word (%logo-st %logo-f-word ()))
    (def word-open (%logo-st %logo-f-word-open (list (pair 'word word))))
    (def ws (%logo-st %logo-f-ws ()))
    (def ws-open (%logo-st %logo-f-ws-open (list (pair 'ws ws))))
    (def indent-after (%logo-st %logo-f-indent-after (list (pair 'word word))))
    (def indent-open (%logo-st %logo-f-indent-open (list (pair 'after indent-after))))
    (def op-lt (%logo-st %logo-f-op-lt ()))
    (def op-gt (%logo-st %logo-f-op-gt ()))
    (def op-open
      (%logo-st %logo-f-op-open (list (pair 'accept accept) (pair 'lt op-lt) (pair 'gt op-gt))))
    (def string-body (%logo-st %logo-f-string-body ()))
    (def string-open (%logo-st %logo-f-string-open (list (pair 'body string-body))))
    (def semi-body (%logo-st %logo-f-semi-body ()))
    (def semi-open (%logo-st %logo-f-semi-open (list (pair 'body semi-body))))
    (def close-open (%logo-st (%logo-f-byte 93) (list (pair 'accept accept))))
    (def open-open (%logo-st (%logo-f-byte 91) (list (pair 'accept accept))))
    (def nl-open (%logo-st (%logo-f-byte 10) (list (pair 'accept accept))))
    (def paren-open-open (%logo-st (%logo-f-byte 40) (list (pair 'accept accept))))
    (def paren-close-open (%logo-st (%logo-f-byte 41) (list (pair 'accept accept))))

    ; LOGO-BLOCK
    (set! %logo-block
      (Base make-type base "LOGO-BLOCK"
        (list
          (pair 'write (fn (_ _) (display "[ ... ]")))
          (pair 'eval (fn (_ self) (logo-process-tokens (first self)))))))

    ; LOGO-CLOSE
    (Base make-type base "LOGO-CLOSE"
      (list
        (pair 'analyse close-open)
        (pair 'read (fn (_ . args) %logo-block-close))))

    ; LOGO-OPEN
    (Base make-type base "LOGO-OPEN"
      (list
        (pair 'analyse open-open)
        (pair 'read
          (fn (_ . args)
            (def buf (first args))
            (def %rb
              (fn (self acc)
                (def tok (%token-read buf))
                ; nil = the stream ended inside the block: truncation, not an
                ; implicit ]. Return the marker -- raising inside x_token_read
                ; is banned (it crashed) -- and the entry layer raises
                ; outside.
                (if (null? tok)
                  %logo-truncated
                  (if (eq? tok %logo-block-close)
                    (%make-instance %logo-block (List reverse acc))
                    (self (pair tok acc))))))
            (%rb ())))))

    ; LOGO (word type)
    (set! %logo
      (Base make-type base "LOGO"
        (list
          (pair 'analyse word-open)
          (pair 'read
            (fn (_ . args)
              (%make-instance %logo (%buffer-token (first args)))))
          (pair 'write
            (fn (_ self) (display (first self)))))))

    ; LOGO-WS: spaces and tabs only, discard
    (Base make-type base "LOGO-WS"
      (list
        (pair 'analyse ws-open)
        (pair 'delimit
          (fn (_ buffer score chr)
            (if (or (= chr 32) (= chr 9))
              (do (%buffer-unread buffer) buffer)
              ())))))

    ; LOGO-NEWLINE: bare newline, discard
    (Base make-type base "LOGO-NEWLINE"
      (list
        (pair 'analyse nl-open)))

    ; LOGO-INDENT: \n + spaces/tabs + word
    (set! %logo-indent
      (Base make-type base "LOGO-INDENT"
        (list
          (pair 'analyse indent-open)
          (pair 'read
            (fn (_ . read-args)
              (def text (%buffer-token (first read-args)))
              (def len (Str8 length text))
              ; TAB STOP 1 -- Logo's historical answer, now STATED. The loop
              ; this replaces stepped the index by one per space and per tab and
              ; handed the result back as a column, which is a tab stop of one
              ; written as an accident. x/reader/indent hands back the column and
              ; the end index separately, so this stays correct if that number
              ; ever changes. See #520.
              (def scanned (%indent-scan-ref text 1 1))
              (def indent (first scanned))
              (def indent-end (rest scanned))
              (def word (Str8 sub indent-end (- len indent-end) text))
              (%make-instance %logo-indent (pair indent word))))
          (pair 'write
            (fn (_ self)
              (display (first (rest (first self)))))))))

    ; LOGO-OP: operators and <- assignment
    (set! %logo-op
      (Base make-type base "LOGO-OP"
        (list
          (pair 'analyse op-open)
          (pair 'read
            (fn (_ . args)
              (%make-instance %logo-op (%buffer-token (first args)))))
          (pair 'write
            (fn (_ self) (display (first self)))))))

    ; LOGO-PAREN: ( and )
    (Base make-type base "LOGO-PAREN-OPEN"
      (list
        (pair 'analyse paren-open-open)
        (pair 'read (fn (_ . args) (pair %logo-paren-label "(")))))

    (Base make-type base "LOGO-PAREN-CLOSE"
      (list
        (pair 'analyse paren-close-open)
        (pair 'read (fn (_ . args) (pair %logo-paren-label ")")))))

    ; LOGO-STRING: "..."
    (set! %logo-string
      (Base make-type base "LOGO-STRING"
        (list
          (pair 'analyse string-open)
          (pair 'read
            (fn (_ . args)
              (def text (%buffer-token (first args)))
              (def len (Str8 length text))
              (%make-instance %logo-string (Str8 sub 1 (- len 2) text))))
          (pair 'write
            (fn (_ self)
              (display "\"" (first self) "\""))))))

    ; LOGO-SEMI: ; comment to end of line (discard)
    (Base make-type base "LOGO-SEMI"
      (list
        (pair 'analyse semi-open)))

    base)))

(def %logo-base (%logo-base-make))


; ============================================================
; Block and word accessors
; ============================================================

(def %indent-block-label (pair 'indent-block ()))

(def %is-block?
  (fn (_ tok)
    (match
      ((%type? tok %logo-block) #t)
      ((pair? tok) (eq? (first tok) %indent-block-label))
      (#t #f))))

(def %block-contents
  (fn (_ tok)
    (match
      ((%type? tok %logo-block) (first tok))
      (#t (rest tok)))))

(def %make-indent-block
  (fn (_ tokens)
    (pair %indent-block-label tokens)))

(def %logo-word
  (fn (_ tok)
    (match
      ((%type? tok %logo)        (first tok))
      ((%type? tok %logo-indent) (rest (first tok)))
      (#t ()))))

(def %logo-op-str
  (fn (_ tok)
    (if (%type? tok %logo-op) (first tok) ())))

(def %is-op?
  (fn (_ tok)
    (%type? tok %logo-op)))

(def %is-string?
  (fn (_ tok)
    (%type? tok %logo-string)))

(def %logo-string-val
  (fn (_ tok)
    (first tok)))

(def %is-paren?
  (fn (_ tok str)
    (and (pair? tok)
         (eq? (first tok) %logo-paren-label)
         (str=? (rest tok) str))))

; ============================================================
; Shared helpers (must be after accessors they depend on)
; ============================================================

; Case-insensitive alist lookup by first element
(def %logo-alist-find
  (fn (_ name alist)
    (def uname (Str upcase name))
    (def %find
      (fn (self entries)
        (match
          ((null? entries) ())
          ((str=? uname (first (first entries))) (first entries))
          (#t (self (rest entries))))))
    (%find alist)))

; Check if a token's word matches a keyword (case-insensitive)
(def %logo-word=?
  (fn (_ tok keyword)
    (let ((w (%logo-word tok)))
      (and (not (null? w))
           (str=? (Str upcase w) keyword)))))

; Command entry accessors
(def %cmd-name    (fn (_ entry) (first entry)))
(def %cmd-arity   (fn (_ entry) (first (rest entry))))
(def %cmd-handler (fn (_ entry) (first (rest (rest entry)))))



; ------------------------------------------------------------
; The base, across a state image
; ------------------------------------------------------------
; Nil in the writer's child (a reference into another base's heap is one the
; writer, which walks one chain, cannot place), remade after the load.  The
; type handles go with it: they are registered ON the base and mean nothing
; without it.
(set! %image-transients
  (pair (fn (_)
          (do (set! %logo-base ())
              (set! %logo-states ())
              (set! %logo ())
              (set! %logo-indent ())
              (set! %logo-block ())
              (set! %logo-op ())
              (set! %logo-string ())))
        %image-transients))
(set! %image-recache-hooks
  (pair (fn (_) (set! %logo-base (%logo-base-make))) %image-recache-hooks))

(provide logo/types
  %logo-base %logo-base-make %logo %logo-indent %logo-block %logo-op %logo-string
  %logo-truncated
  %logo-word %logo-word=? %is-block? %block-contents %make-indent-block
  %logo-op-str %is-op? %is-string? %logo-string-val %is-paren?
  %logo-alpha? logo-process-tokens logo-process-to
  %logo-vars %logo-commands
  %logo-alist-find %cmd-name %cmd-arity %cmd-handler)
