; # x-logo -- Logo on x-lang
;
; ## logo/syntax.x -- the Logo highlighting grammar
;
; @description The grammar x/tool/syntax colours Logo programs with:
;   comments, strings, numbers, control words, commands and the booleans.
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
; bundle.xon's (grammar logo ...) form names this module, and x/tool/syntax
; imports it the first time a file needs the grammar, in whatever process is
; colouring: vi's, a REPL's, an HTML renderer's.  So it imports x-lang
; libraries only, never the interpreter, and its words are its own copy of
; the interpreter's command and function tables.  A spec holds them to the
; same words.
;
; Logo's words are read without regard to case.  A control word -- a special
; form of the command table, or a word the dispatcher reads inside one -- is
; a keyword, any other command or function a name, TRUE and FALSE
; constants.  END, which
; this Logo's indented blocks do not need, is a keyword for the files of
; Logos that close TO with it.  A bracket or a comma is punctuation, every
; other operator an operator.  A string still open at the end of the text
; runs to it.  A line starting with a word at its first column starts
; outside any string.

(module logo/syntax)
(import x/type/list)
(import x/type/str)
(import x/reader/lexer)
(import x/tool/syntax)
(import x/core/doors str-byte-ref char->int str-byte-len int+)

; The special forms of (Logo commands), then the words the dispatcher reads
; inside them, then END
(def logo-syntax-keywords
  (list "TO" "REPEAT" "IF" "STOP" "RETURN" "PRINT" "TYPE" "EXECUTE" "LOAD"
        "THEN" "ELSE" "EITHER" "UNTIL" "FOREVER" "END"))

; The other commands of (Logo commands) and the functions of (Logo
; functions)
(def logo-syntax-commands
  (list "FORWARD" "FD" "BACK" "BK" "RIGHT" "RT" "LEFT" "LT" "PENUP" "PU"
        "PENDOWN" "PD" "CLEARSCREEN" "CS" "HEADING" "XCOR" "YCOR" "SQRT" "ABS"
        "SIN" "COS" "TAN" "ARCTAN" "ROUND" "INT" "NOT" "REMAINDER" "RAND"
        "POWER" "SETXY" "HOME" "HIDETURTLE" "HT" "SHOWTURTLE" "ST" "PENCOLOR"
        "PC" "PENWIDTH" "PW" "SETX" "SETY" "SETHEADING" "SETH" "DISTANCE"
        "TOWARDS" "TURTLE.STATE" "SETTURTLE" "FACE" "MEMBER" "GROW" "S.FORWARD"
        "S.FD"))

(def logo-syntax-constants (list "TRUE" "FALSE"))

(def %logo-sx-word
  (list (pair 97 122) (pair 65 90) (pair 48 57) 95 46 63))
(def %logo-sx-word-start (list (pair 97 122) (pair 65 90) 95 46 63))

(def logo-syntax-rules
  (fn (_)
    (list (Lexer until (lit comment) ";" "\n" (lit to-end))
          (Lexer until (lit string) "\"" "\"" (lit take) (lit to-end))
          (Lexer run (lit blank) " \t\r\n" " \t\r\n")
          (Lexer number (lit number) ())
          (Lexer run (lit word) %logo-sx-word-start %logo-sx-word)
          (Lexer table (lit punct) (list "[" "]" "(" ")" ","))
          (Lexer table (lit op) (list "<-" "<=" ">=" "<>" "=" "<" ">" "+" "-" "*" "/" "^"))
          (Lexer any (lit plain)))))

(def %logo-sx-byte (fn (_ s i) (char->int (str-byte-ref s i))))
(def %logo-sx-up (fn (_ b) (if (if (>= b 97) (<= b 122) #f) (- b 32) b)))

; Is A the same word as B, case aside
(def %logo-sx-same?
  (fn (_ a b)
    (if (= (str-byte-len a) (str-byte-len b)) (%logo-sx-same-from? a b 0) #f)))
(def %logo-sx-same-from?
  (fn (self a b i)
    (if (>= i (str-byte-len a)) #t
      (if (= (%logo-sx-up (%logo-sx-byte a i)) (%logo-sx-byte b i))
        (self a b (int+ i 1))
        #f))))

(def %logo-sx-in? (fn (_ w ws) (if (null? (List find (fn (_ u) (%logo-sx-same? w u)) ws)) #f #t)))

(def %logo-sx-word-class
  (fn (_ text)
    (match
      ((%logo-sx-in? text logo-syntax-keywords) (lit keyword))
      ((%logo-sx-in? text logo-syntax-commands) (lit name))
      ((%logo-sx-in? text logo-syntax-constants) (lit constant))
      (#t ()))))

(def %logo-sx-sync
  (fn (_ s ls)
    (if (>= ls (str-byte-len s)) #f
      (let ((b (%logo-sx-byte s ls)))
        (if (if (>= b 65) (<= b 90) #f) #t (if (>= b 97) (<= b 122) #f))))))

(Syntax register!
  (let ((g (Syntax make (lit logo) (logo-syntax-rules)
             (list (pair (lit comment) (lit comment))
                   (pair (lit string) (lit string))
                   (pair (lit number) (lit number))
                   (pair (lit word) %logo-sx-word-class)
                   (pair (lit punct) (lit punct))
                   (pair (lit op) (lit operator))))))
    (g sync %logo-sx-sync)
    g))

(provide logo/syntax logo-syntax-rules logo-syntax-keywords logo-syntax-commands logo-syntax-constants)
