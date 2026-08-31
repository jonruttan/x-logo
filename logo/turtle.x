; turtle.x -- Logo turtle graphics interpreter (aggregator)

(import logo/state)
(import logo/types)
(import logo/expr)
(import logo/dispatch)
(import logo/math)
(import logo/tstate)
(import logo/indent)
(import logo/repl)
(import logo/json)

; THE SURFACE'S VERSION, which is not the bundle's.  %lang-version puts this
; beside "Logo" on the banner, and it moves when the LANGUAGE does -- a new
; command, a changed precedence.  What `make install` writes to <dest>/version
; is a different fact, `git describe` of the repository, and it moves on every
; commit.  A bundle carrying one number for both would have to choose which of
; the two questions to answer wrongly.
(def logo-version "0.1.0")

(provide logo/turtle
  logo-version
  ; state
  turtle-forward turtle-back turtle-right turtle-left
  turtle-penup turtle-pendown turtle-clearscreen
  %turtle-on-bc %turtle-on-clear %turtle-bc
  ; types
  %logo-base %logo
  ; expr
  %logo-functions
  ; dispatch
  logo-process-tokens
  ; indent
  %logo-indent-to-blocks
  ; repl -- logo-batch beside logo-repl: repl.x provides both, and the
  ; aggregator listing only one is why run.x could not reach it.
  logo-repl logo-batch %logo-on-exit %logo-on-command
  ; json
  turtle-json turtle-json-str turtle-bc-str)
