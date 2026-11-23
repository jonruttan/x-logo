; tstate.x -- Extended turtle state commands
(module logo/tstate)
(import logo/state as-float)
(import logo/types block-contents)
(import x/num/float)

; ============================================================
; Register commands in the command table
; ============================================================

(Logo commands
  (pair (list "SETXY"       2 (fn (_ x y) (Turtle setxy x y)))
  (pair (list "HOME"        0 (fn () (Turtle home)))
  (pair (list "HIDETURTLE"  0 (fn () (Turtle visible #f)))
  (pair (list "HT"          0 (fn () (Turtle visible #f)))
  (pair (list "SHOWTURTLE"  0 (fn () (Turtle visible #t)))
  (pair (list "ST"          0 (fn () (Turtle visible #t)))
  (pair (list "PENCOLOR"    1 (fn (_ c) (Turtle pencolor c)))
  (pair (list "PC"          1 (fn (_ c) (Turtle pencolor c)))
  (pair (list "PENWIDTH"    1 (fn (_ w) (Turtle penwidth w)))
  (pair (list "PW"          1 (fn (_ w) (Turtle penwidth w)))
  (pair (list "SETX"        1 (fn (_ x) (Turtle setxy x (Turtle y))))
  (pair (list "SETY"        1 (fn (_ y) (Turtle setxy (Turtle x) y)))
  (pair (list "SETHEADING"  1 (fn (_ n) (Turtle setheading n)))
  (pair (list "SETH"        1 (fn (_ n) (Turtle setheading n)))
  (Logo commands))))))))))))))))

; Register state query functions
(Logo functions
  (pair (list "DISTANCE"      2 (fn (_ x y) (Turtle distance x y)))
  (pair (list "TOWARDS"       2 (fn (_ x y) (Turtle towards x y)))
  (pair (list "TURTLE.STATE"  (fn () (Turtle state)))
  (Logo functions)))))

(Logo commands
  (pair (list "SETTURTLE" 1 (fn (_ lst) (Turtle setturtle lst)))
  (pair (list "FACE"      2 (fn (_ x y)
          (def bearing (Turtle towards x y))
          (Turtle left (Float - bearing (Turtle heading)))))
  (Logo commands))))

; MEMBER function
(Logo functions
  (pair (list "MEMBER" 2
    (fn (_ item lst)
      (def %search
        (fn (self l)
          (match
            ((null? l) #f)
            ((if (number? item) (= (first l) item) (eq? (first l) item)) #t)
            (#t (self (rest l))))))
      (%search (block-contents lst))))
  (Logo functions)))

; GROW and S.FORWARD
(Logo commands
  (pair (list "GROW"      1 (fn (_ factor)
          (Turtle scale (Float * (Turtle scale) (as-float factor)))))
  (pair (list "S.FORWARD" 1 (fn (_ dist)
          (Turtle forward (Float * (as-float dist) (Turtle scale)))))
  (pair (list "S.FD"      1 (fn (_ dist)
          (Turtle forward (Float * (as-float dist) (Turtle scale)))))
  (Logo commands)))))

