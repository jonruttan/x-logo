; turtle.x -- Logo turtle graphics interpreter (aggregator)

(module logo/turtle)
(import logo/indent logo-indent-to-blocks)
(import logo/dispatch logo-process-tokens)
(import logo/repl logo-batch logo-repl)
(import logo/json turtle-bc-str turtle-json turtle-json-str)
(import logo/state)
(import logo/types)
(import logo/expr)
(import logo/math)
(import logo/tstate)
(import logo/entry)
(import logo/serve)

; The surface's version, not the bundle's. %lang-version puts this beside
; "Logo" on the banner and moves when the language does (a new command, a
; changed precedence). What `make install` writes to <dest>/version is a
; different fact -- `git describe` of the repository, which moves on every
; commit.
(def logo-version "0.1.0")

(provide logo/turtle
  logo-version Turtle Logo logo-repl logo-batch logo-process-tokens
  logo-indent-to-blocks turtle-json turtle-json-str turtle-bc-str)
