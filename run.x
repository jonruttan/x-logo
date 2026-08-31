; # x-logo -- Logo turtle graphics for x-lang
;
; ## run.x -- THE entry
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
; THIS FILE KNOWS NO PATHS, and the change is worth naming because the file it
; replaces was three quarters path handling.  As apps/logo/run.x it opened
; with (include "lib/x-core.x") to self-boot and then derived %logo-app-root
; from %install-root with a guard, because an in-tree app is loaded by its
; filename and has to find both the platform and itself.
;
; A bundle is loaded by NAME.  x.sh reads lang.xon, boots the dialect declared
; there, arms this directory with import-path!, defines %lang-root to it, and
; only then cats this file -- so by the time anything below runs the platform
; is up, `import logo/...` resolves, and logo/serve.x has an absolute root to
; join viewer.html onto.  Every line of the old boot was a workaround for `-l`
; not knowing about bundles.  It does now.
; ONE IMPORT, AND IT MUST BE AN IMPORT.  logo/main is boot glue -- it forks
; the viewer server, wires the bytecode hooks, arranges for the child to be
; reaped -- and it re-exports the language's two launchers so this file names
; one thing rather than three.
;
; NOT a ./-relative include-once, which is how a bundle's modules reach their
; siblings and is wrong here: x.sh cats THIS file onto the engine's stdin
; after the dialect, so it has no file directory, and `./logo/main.x` would
; resolve against whatever directory the user was standing in.  `import` goes
; through the root x.sh armed, which is the bundle wherever it sits.
(import logo/main)

(set! %lang-name "Logo")
(set! %lang-version logo-version)

; THE LOOP IS OURS, not the launcher's, and it always was: a Logo "unit" is a
; line of Logo, not an s-expression, so logo-repl reads with the Logo reader
; and logo-batch consumes the whole of stdin as a program.  x.sh appends its
; own launcher only when the entry does not end in one, which is why this line
; is last and nothing structural may follow it.
;
; Batch (-f): stdin holds a Logo program, not a session -- and logo-repl's fd
; swap would discard it unread, the same bug the dialect entries had (see the
; platform's repl/banner.x).  %batch? comes from the seam.
(if %batch? (logo-batch) (logo-repl))
