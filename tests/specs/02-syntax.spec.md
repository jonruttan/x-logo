# @weight 1
## logo/syntax -- the Logo highlighting grammar

The bundle's bundle.xon declares a grammar, `logo`, that x/tool/syntax colours
Logo programs with. Its module, `logo/syntax`, imports x-lang libraries
only, and registers the grammar as it loads.

The cases share one process, and a registered grammar stays registered, so
the catalogue's case comes first: it finds the grammar through bundle.xon,
before anything has imported the module.

### the catalogue finds logo by suffix, by #! and by modeline

```scheme
(do (import x/sys/posix) (import x/sys/file) (import x/tool/syntax)
    (def root (Str8 replace "/lib/logo/syntax.x" "" (%module-resolve-file "logo/syntax.x")))
    (def tmp (File temp "/tmp/x-logo-spec-langs-"))
    (File close (first tmp))
    (def d (rest tmp))
    (File unlink d)
    (File mkdir d)
    (File symlink root (Str8 append d "/logo"))
    (def was (Sys getenv "X_BUNDLE_DIR"))
    (Sys setenv "X_BUNDLE_DIR" d)
    (Syntax forget!)
    (def row (List find (fn (_ r) (eq? (first r) (lit logo))) (Syntax catalogue)))
    (def grammar-of (fn (_ path . text)
      (let ((g (apply Syntax (pair (lit for-file) (pair path text))))) (if (null? g) () (g name)))))
    (def seen
      (list (List ref 1 row)
            (grammar-of "x.logo") (grammar-of "x.lg")
            (grammar-of "run" "#!/usr/bin/env logo\nfd 10\n")
            (grammar-of "run" "fd 10\n; vi: set ft=logo:\n")
            (grammar-of "x.txt")
            (let ((g (Syntax named (lit logo)))) (list (g files) (g interpreters)))))
    (File unlink (Str8 append d "/logo"))
    (File rmdir d)
    (Sys setenv "X_BUNDLE_DIR" (if (null? was) "" was))
    (Syntax forget!)
    seen)
```
---
    ('logo/syntax 'logo 'logo 'logo 'logo () ((".logo" ".lg") ("logo")))

### a program's spans: control words, commands, numbers, strings

Words are read without regard to case.  A control word is a keyword, a
command a name, a bracket punctuation and `<-` an operator.

```scheme
(do (import x/tool/syntax) (import logo/syntax)
    ((Syntax named (lit logo)) spans
      "; c\nto square n\n  repeat 4 [fd 100 rt 90]\nx <- \"hi\" + 1.5\n"))
```
---
    ((0 3 'comment) (4 2 'keyword) (18 6 'keyword) (25 1 'number) (27 1 'punct) (28 2 'name) (31 3 'number) (35 2 'name) (38 2 'number) (40 1 'punct) (44 2 'operator) (47 4 'string) (52 1 'operator) (54 3 'number))

### a boolean, a word inside a form, an open string

```scheme
(do (import x/tool/syntax) (import logo/syntax)
    ((Syntax named (lit logo)) spans "IF true THEN print \"open"))
```
---
    ((0 2 'keyword) (3 4 'constant) (8 4 'keyword) (13 5 'keyword) (19 5 'string))

### the grammar's words are the interpreter's commands and functions

Each special form of the command table is a keyword.  Every other command,
and every function an expression can call, is in the grammar's commands,
which name nothing else.

```scheme
(do (import logo/syntax logo-syntax-keywords logo-syntax-commands)
    (let ((cs (Logo commands)) (fs (Logo functions)))
      (let ((names (List append (List map first cs) (List map first fs))))
        (list (List filter
                (fn (_ c) (not (List includes? (first c)
                                 (if (= (first (rest c)) -1) logo-syntax-keywords logo-syntax-commands))))
                cs)
              (List filter (fn (_ f) (not (List includes? (first f) logo-syntax-commands))) fs)
              (List filter (fn (_ w) (not (List includes? w names))) logo-syntax-commands)))))
```
---
    (() () ())
