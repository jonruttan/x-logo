; main.x -- Logo turtle graphics with live browser viewer
;
; Usage:  x -l logo
;
; Starts a server on localhost:8080. Open the URL in your browser and type Logo
; commands; the browser updates live.
;
; This file is boot glue -- its point is its effects, in order: fork the viewer
; server, wire the bytecode hooks, arrange for the child to be reaped. It is a
; module rather than an include because a bundle entry has no file directory
; (x.sh cats run.x onto stdin after the dialect), so a ./-relative include-once
; would resolve against the user's cwd; `import` is the only addressing that
; works, and it needs a (provide ...). Nothing arms a module root here -- x.sh
; did that from lang.xon before run.x was read.
(def %bigint ())
(import x/num/float)
(import logo/turtle)
(import x/sys/posix)
(import logo/serve)
; Fetch the ptr/ffi prims from the catalog (ns `ptr`/`ffi` are de-registered, R5).
(def %ptr-call (prim-ref 'ptr 'call))
(def %dlopen (prim-ref 'ffi 'dlopen))
(def %dlsym (prim-ref 'ffi 'dlsym))


; --- The server, and everything else a run decides for itself ---------------
(def %logo-port 8080)
(def %server-pid ())

; Started by the entry, not by this import. Everything here answers a question
; only the running process can answer -- is this an interactive session? -- and
; an import is carried by a state image, so a fork decided here would be decided
; once, in the image writer's batch child, and inherited by every later boot.
; run.x calls this after the boot, where %batch? is the session's own; a source
; boot reaches the same call on the same line.
(def %logo-start!
  (fn (_)
    (do
      ; The bytecode file is this run's artifact: emptied per run, in batch too,
      ; which is why it sits outside the unless.
      (%bc-write)
      (unless %batch?
        (set! %server-pid
          ; One expression, so the child does not race for the pipe.
          (let ((pid (Sys fork)))
            (if (= pid 0)
              ; Ignore SIGINT in the server child so ctrl-c doesn't throw
              ; STOP errors in the request handler (#226: named surface, no
              ; more dlsym'd magic numbers)
              (do (Sys close 0) (Sys open-read "/dev/null")
                  (Sys signal (Sys sigint) (Sys sig-ign))
                  (turtle-serve %logo-port))
              pid)))
        ; Kill the server child when the REPL exits.  No server in batch:
        ; %logo-on-exit stays nil and logo-batch's unless skips it.
        (set! %logo-on-exit
          (fn ()
            ; Kill politely, then reap: the child was never waited on
            ; before, leaving a zombie for the parent's remaining
            ; lifetime (#226).
            (Sys kill %server-pid (Sys sigterm))
            (Sys wait %server-pid)))
        (display "http://localhost:" %logo-port "\n"))
      ())))

; --- Hooks: append bytecodes, clear file on clearscreen ---
(set! %turtle-on-bc %bc-append)
(set! %turtle-on-clear %bc-clear)

; RE-EXPORTED, so the entry imports ONE thing.  logo-repl and logo-batch are
; logo/repl's, reached here through logo/turtle; run.x wants the language and
; its plumbing together, and listing them here is what lets it say so in one
; line instead of three.
(provide logo/main
  logo-version logo-repl logo-batch %logo-port %logo-start!)
