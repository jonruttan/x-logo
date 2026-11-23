; # x-logo -- Logo turtle graphics for x-lang
;
; ## lib/logo/run.x -- the entry
;
; @description A Logo interpreter with a live browser viewer: its own
;   tokenizer types, an infix expression parser, an HTTP server and an
;   animated SVG turtle, all in x-lang.
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
; Usage:
;   x -l logo                 REPL, plus the viewer at http://localhost:8080
;   x -l logo -f prog.logo    batch -- runs the program, writes the bytecode,
;                             starts no server
;
; The module logo/run.  x.sh reads bundle.xon, boots the dialect, arms the
; bundle's lib/ with import-path!, imports this module and then calls its
; main, so `import logo/...` resolves and logo/serve.x finds viewer.html
; through (Bundle root "logo").
;
; logo/main is boot glue (it forks the viewer server, wires the bytecode
; hooks, reaps the child) and re-exports the two launchers.
(module logo/run)
(import logo/main logo-start!)
(import logo/turtle logo-version logo-repl logo-batch)

(set! %lang-name "Logo")
(set! %lang-version logo-version)

; The loop is ours, not the launcher's: a Logo unit is a line of Logo, not an
; s-expression, so logo-repl reads with the Logo reader and logo-batch consumes
; the whole of stdin.  x.sh calls main at the top of the stream, never inside
; the import, so the rest of the stream is this loop's to read.
;
; Batch (-f): stdin holds a Logo program, not a session, and logo-repl's fd swap
; would discard it unread; %batch? comes from the seam. The run's own decisions
; -- the bytecode file, and the viewer server for a session -- are made here,
; not by the import, so a boot from a state image makes them too. See
; logo-start! in lib/logo/main.x.
(def main
  (fn (_)
    (logo-start!)
    (if %batch? (logo-batch) (logo-repl))))

(provide logo/run main)
