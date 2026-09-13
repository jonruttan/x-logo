; # x-logo -- Logo turtle graphics for x-lang
;
; ## run.x -- the entry point
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
; This file contains no path literals and no boot code. x.sh reads lang.xon,
; boots the dialect, arms this directory with import-path!, defines %lang-root
; to it, and only then cats this file -- so `import logo/...` resolves and
; logo/serve.x has an absolute root to join viewer.html onto.
;
; The one import must be an import, not a ./-relative include-once: logo/main
; is boot glue (it forks the viewer server, wires the bytecode hooks, reaps the
; child) and re-exports the two launchers. x.sh cats this file onto stdin, so it
; has no file directory; `import` goes through the root x.sh armed.
(import logo/main)

(set! %lang-name "Logo")
(set! %lang-version logo-version)

; The loop is ours, not the launcher's: a Logo unit is a line of Logo, not an
; s-expression, so logo-repl reads with the Logo reader and logo-batch consumes
; the whole of stdin. x.sh appends its own launcher only when the entry does not
; end in one, which is why this line is last and nothing structural may follow.
;
; Batch (-f): stdin holds a Logo program, not a session, and logo-repl's fd swap
; would discard it unread; %batch? comes from the seam. The run's own decisions
; -- the bytecode file, and the viewer server for a session -- are made here,
; not by the import, so a boot from a state image makes them too. See
; %logo-start! in logo/main.x.
(%logo-start!)
(if %batch? (logo-batch) (logo-repl))
