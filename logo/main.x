; main.x -- Logo turtle graphics with live browser viewer
;
; Usage:  x -l logo
;
; Starts a server on localhost:8080. Open the URL in your browser.
; Type Logo commands — the browser updates live.
;
; BOOT GLUE THAT IS NEVERTHELESS A MODULE, and the "nevertheless" is the
; interesting part.  What this file is for is its EFFECTS, in order: fork the
; viewer server, wire the bytecode hooks, arrange for the child to be reaped.
; That reads like something to `include`, and as an in-tree app it was.
;
; A BUNDLE ENTRY HAS NO FILE DIRECTORY.  x.sh cats run.x onto the engine's
; stdin after the dialect, so a ./-relative include-once in it resolves
; against the CWD -- wherever the user happened to be -- rather than against
; the bundle.  `import` is the only addressing that works from there, and
; `import` needs a (provide ...).  So the module registration below is not a
; claim that this is a library; it is what makes the entry able to name it.
;
; Nothing arms a module root here -- x.sh did that from lang.xon before run.x
; was read, which is what makes `import logo/...` below resolve.
(def %bigint ())
(import x/num/float)
(import logo/turtle)
(import x/sys/posix)
(import logo/serve)
; Fetch the ptr/ffi prims from the catalog (ns `ptr`/`ffi` are de-registered, R5).
(def %ptr-call (prim-ref 'ptr 'call))
(def %dlopen (prim-ref 'ffi 'dlopen))
(def %dlsym (prim-ref 'ffi 'dlsym))


; --- Fork the server, continue with the REPL in the parent ---
(def %logo-port 8080)

; Write empty bytecode file before starting
(%bc-write)

; Fork server — must be one expression so child doesn't race for the pipe.
; Skipped in batch (-f): the run exits as soon as the program is processed,
; so a server would be killed before its URL could ever be visited.  The
; bytecode file is still written -- it is the batch run's artifact.
(def %server-pid
  (unless %batch?
    (let ((pid (Sys fork)))
      (if (= pid 0)
        ; Ignore SIGINT in the server child so ctrl-c doesn't throw
        ; STOP errors in the request handler (#226: named surface, no
        ; more dlsym'd magic numbers)
        (do (Sys close 0) (Sys open-read "/dev/null")
            (Sys signal (Sys sigint) (Sys sig-ign))
            (turtle-serve %logo-port))
        pid))))

; --- Hooks: append bytecodes, clear file on clearscreen ---
(set! %turtle-on-bc %bc-append)
(set! %turtle-on-clear %bc-clear)

; Kill server child when the REPL exits.  No server in batch: %logo-on-exit
; stays nil and logo-batch's unless skips it.
(unless %batch?
  (set! %logo-on-exit
    (fn ()
      ; Kill politely, then reap: the child was never waited on before,
      ; leaving a zombie for the parent's remaining lifetime (#226).
      (Sys kill %server-pid (Sys sigterm))
      (Sys wait %server-pid)))
  (display "http://localhost:" %logo-port "\n"))

; RE-EXPORTED, so the entry imports ONE thing.  logo-repl and logo-batch are
; logo/repl's, reached here through logo/turtle; run.x wants the language and
; its plumbing together, and listing them here is what lets it say so in one
; line instead of three.
(provide logo/main
  logo-version logo-repl logo-batch %logo-port)
