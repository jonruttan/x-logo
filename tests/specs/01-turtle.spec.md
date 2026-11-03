# @weight 7
## turtle state

### starts at origin

```scheme
(list (Turtle x) (Turtle y))
```
---
    (0.0 0.0)

### starts heading north

```scheme
(Turtle heading)
```
---
    0.0

### pen starts down

```scheme
(Turtle pen)
```
---
    #t

## Turtle forward

### moves north from origin

```scheme
(Turtle forward 100)
(list (Turtle x) (Turtle y))
```
---
    (0.0 -100.0)

### creates bytecode entries

```scheme
(Turtle clearscreen)
(Turtle forward 50)
(List length (Turtle bc))
```
---
    2

## Turtle back

### moves south from origin

```scheme
(Turtle clearscreen)
(Turtle back 100)
(list (Turtle x) (Turtle y))
```
---
    (0.0 100.0)

## Turtle right

### changes heading clockwise

```scheme
(Turtle clearscreen)
(Turtle right 90)
(Turtle heading)
```
---
    90.0

## Turtle left

### changes heading counterclockwise

```scheme
(Turtle clearscreen)
(Turtle left 45)
(Turtle heading)
```
---
    -45.0

## Turtle penup

### disables drawing

```scheme
(Turtle clearscreen)
(Turtle penup)
(Turtle pen)
```
---
    #f

## Turtle pendown

### re-enables drawing

```scheme
(Turtle clearscreen)
(Turtle penup)
(Turtle pendown)
(Turtle pen)
```
---
    #t

### pen-up forward emits U then F bytecodes

```scheme
(Turtle clearscreen)
(Turtle penup)
(Turtle forward 50)
(def bc (List reverse (Turtle bc)))
(first bc)
```
---
    "U"

## Turtle clearscreen

### resets position

```scheme
(Turtle forward 100)
(Turtle clearscreen)
(list (Turtle x) (Turtle y))
```
---
    (0.0 0.0)

### resets heading

```scheme
(Turtle right 90)
(Turtle clearscreen)
(Turtle heading)
```
---
    0.0

### clears segments

```scheme
(Turtle forward 100)
(Turtle clearscreen)
(List length (Turtle bc))
```
---
    0

## tokenizer

### tokenizes uppercase word

```scheme
(Turtle clearscreen)
(def toks (Tok read-str (Logo base) "FD "))
(Type ? (first toks) (Logo word-type))
```
---
    #t

### tokenizes lowercase word

```scheme
(def toks (Tok read-str (Logo base) "fd "))
(Type ? (first toks) (Logo word-type))
```
---
    #t

### tokenizes mixed case

```scheme
(def toks (Tok read-str (Logo base) "Forward "))
(logo-word (first toks))
```
---
    "Forward"

### tokenizes number

```scheme
(def toks (Tok read-str (Logo base) "100 "))
(first toks)
```
---
    100

### tokenizes brackets into block

```scheme
(def toks (Tok read-str (Logo base) "[ fd 100 ] "))
(is-block? (first toks))
```
---
    #t

### block contains tokens

```scheme
(def toks (Tok read-str (Logo base) "[ fd 100 ] "))
(List length (block-contents (first toks)))
```
---
    2

## command dispatch

### fd creates segment

```scheme
(Turtle clearscreen)
(def toks (Tok read-str (Logo base) "fd 100 "))
(logo-process-tokens toks)
(List length (Turtle bc))
```
---
    2

### repeat draws square

```scheme
(Turtle clearscreen)
(def toks (Tok read-str (Logo base) "repeat 4 [ fd 100 rt 90 ] "))
(logo-process-tokens toks)
(List length (Turtle bc))
```
---
    16

### case insensitive lookup

```scheme
(Turtle clearscreen)
(def toks (Tok read-str (Logo base) "Forward 50 "))
(logo-process-tokens toks)
(List length (Turtle bc))
```
---
    2

### a zero-argument command keeps dispatching what follows

A match clause evaluates ONE body expression, so the arity-0 branch must
do-wrap its handler call and the recursion -- bare, PU/PD/HOME executed and
then silently dropped every command after them.

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "pu fd 100 pd fd 50 "))
(List length (Turtle bc))
```
---
    6

### reassignment updates a variable in place

The same one-body-expression rule stalks (Logo var-set!)'s update clause: its
trailing #t is only reachable through a do-wrap, and without it the update
leans on %set-rest!'s return value to avoid prepending a duplicate entry.

```scheme
(logo-process-tokens (Tok read-str (Logo base) "qq <- 1 qq <- 2 "))
(def %qq-count
  (fn (self vars)
    (match
      ((null? vars) 0)
      ((str=? (first (first vars)) "QQ") (+ 1 (self (rest vars))))
      (#t (self (rest vars))))))
(%qq-count (Logo vars))
```
---
    1

## TO procedure definition

### defines and calls procedure

```scheme
(Turtle clearscreen)
(def t1 (Tok read-str (Logo base) "to sq size [ repeat 4 [ fd size rt 90 ] ] "))
(logo-process-tokens t1)
(def t2 (Tok read-str (Logo base) "sq 60 "))
(logo-process-tokens t2)
(List length (Turtle bc))
```
---
    16

### multi-parameter procedure

```scheme
(Turtle clearscreen)
(def t1 (Tok read-str (Logo base) "to arcr r deg [ repeat deg [ fd r rt 1 ] ] "))
(logo-process-tokens t1)
(def t2 (Tok read-str (Logo base) "arcr 1 10 "))
(logo-process-tokens t2)
(List length (Turtle bc))
```
---
    40

## indent preprocessing

### flat tokens pass through

```scheme
(def toks (Tok read-str (Logo base) "fd 100 rt 90 "))
(List length (logo-indent-to-blocks toks))
```
---
    4

### indentation creates block

```scheme
(def toks (Tok read-str (Logo base) "\nrepeat 4\n    fd 100\n    rt 90\n "))
(def processed (logo-indent-to-blocks toks))
(List length processed)
```
---
    3

### indented repeat draws square

```scheme
(Turtle clearscreen)
(def toks (Tok read-str (Logo base) "\nrepeat 4\n    fd 100\n    rt 90\n "))
(logo-process-tokens (logo-indent-to-blocks toks))
(List length (Turtle bc))
```
---
    16

### indented THEN body executes

```scheme
(Turtle clearscreen)
(def toks (Tok read-str (Logo base) "\nif 5 > 3 then\n    fd 100\n "))
(logo-process-tokens (logo-indent-to-blocks toks))
(List length (Turtle bc))
```
---
    2

### indented THEN body skipped when false

```scheme
(Turtle clearscreen)
(def toks (Tok read-str (Logo base) "\nif 5 < 3 then\n    fd 100\n "))
(logo-process-tokens (logo-indent-to-blocks toks))
(List length (Turtle bc))
```
---
    0

### multi-line indented THEN body

```scheme
(Turtle clearscreen)
(def toks (Tok read-str (Logo base) "\nif 5 > 3 then\n    fd 100\n    rt 90\n    fd 100\n "))
(logo-process-tokens (logo-indent-to-blocks toks))
(List length (Turtle bc))
```
---
    6

### indented ELSE body executes

```scheme
(Turtle clearscreen)
(def toks (Tok read-str (Logo base) "\nif 5 < 3 then\n    fd 100\nelse\n    bk 50\n "))
(logo-process-tokens (logo-indent-to-blocks toks))
(List length (Turtle bc))
```
---
    2

## JSON output

### bytecode JSON output

```scheme
(Turtle clearscreen)
(Turtle forward 100)
(turtle-bc-str)
```
---
    "[\"F\",100.0]"

## expressions

### arithmetic precedence

```scheme
(Turtle clearscreen)
(def r (logo-parse-one-expr (Tok read-str (Logo base) "2 + 3 * 4 ")))
(first r)
```
---
    14

### parenthesized expression

```scheme
(def r (logo-parse-one-expr (Tok read-str (Logo base) "(2 + 3) * 4 ")))
(first r)
```
---
    20

### power operator

```scheme
(def r (logo-parse-one-expr (Tok read-str (Logo base) "2 ^ 3 ")))
(first r)
```
---
    8.0

### unary minus

```scheme
(def r (logo-parse-one-expr (Tok read-str (Logo base) "-5 ")))
(first r)
```
---
    -5

### comparison greater

```scheme
(def r (logo-parse-one-expr (Tok read-str (Logo base) "5 > 3 ")))
(first r)
```
---
    #t

### comparison equal

```scheme
(def r (logo-parse-one-expr (Tok read-str (Logo base) "5 = 5 ")))
(first r)
```
---
    #t

### string equality

```scheme
(def r (logo-parse-one-expr (Tok read-str (Logo base) "\"hello\" = \"hello\" ")))
(first r)
```
---
    #t

### variable in expression

```scheme
(Turtle clearscreen)
(Logo var-set! "X" 10)
(def r (logo-parse-one-expr (Tok read-str (Logo base) "x + 5 ")))
(first r)
```
---
    15

### function call in expression

```scheme
(def r (logo-parse-one-expr (Tok read-str (Logo base) "sqrt(16) ")))
(first r)
```
---
    4.0

## control flow

### if then true

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "if 5 > 3 then fd 100 "))
(List length (Turtle bc))
```
---
    2

### if then false

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "if 5 < 3 then fd 100 "))
(List length (Turtle bc))
```
---
    0

### if then else true branch

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "if 5 > 3 then fd 100 else fd 50 "))
(Turtle x)
```
---
    0.0

### if not

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "if not 5 < 3 then fd 100 "))
(List length (Turtle bc))
```
---
    2

### stop exits procedure

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "to t [ fd 100 stop fd 100 ] "))
(logo-process-tokens (Tok read-str (Logo base) "t "))
(List length (Turtle bc))
```
---
    2

### return value from procedure

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "to add a b [ return a + b ] "))
(def r (logo-parse-one-expr (Tok read-str (Logo base) "add(3, 4) ")))
(first r)
```
---
    7

### repeat until

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "x <- 0 repeat [ x <- x + 1 ] until x > 5 "))
(def r (logo-parse-one-expr (Tok read-str (Logo base) "x ")))
(first r)
```
---
    6

## assignment

### basic assignment

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "x <- 42 "))
(def r (logo-parse-one-expr (Tok read-str (Logo base) "x ")))
(first r)
```
---
    42

### assignment with expression

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "x <- 2 + 3 "))
(def r (logo-parse-one-expr (Tok read-str (Logo base) "x ")))
(first r)
```
---
    5

## math functions

### sqrt

```scheme
(def r (logo-parse-one-expr (Tok read-str (Logo base) "sqrt(144) ")))
(first r)
```
---
    12.0

### abs

```scheme
(def r (logo-parse-one-expr (Tok read-str (Logo base) "abs(-7) ")))
(first r)
```
---
    7

### sin 90

```scheme
(def r (logo-parse-one-expr (Tok read-str (Logo base) "sin(90) ")))
(first r)
```
---
    1.0

### cos 0

```scheme
(def r (logo-parse-one-expr (Tok read-str (Logo base) "cos(0) ")))
(first r)
```
---
    1.0

### remainder

```scheme
(def r (logo-parse-one-expr (Tok read-str (Logo base) "remainder(17, 5) ")))
(first r)
```
---
    2

### pi constant

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "x <- pi "))
(def r (logo-parse-one-expr (Tok read-str (Logo base) "x > 3 ")))
(first r)
```
---
    #t

## turtle state commands

### setxy

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "setxy 100 50 "))
(list (Turtle x) (Turtle y))
```
---
    (100.0 50.0)

### home

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "fd 100 home "))
(list (Turtle x) (Turtle y) (Turtle heading))
```
---
    (0.0 0.0 0.0)

### distance

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "setxy 3 4 "))
(def r (logo-parse-one-expr (Tok read-str (Logo base) "distance(0, 0) ")))
(first r)
```
---
    5.0

## pen color and width

### pencolor sets state

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "pencolor \"red\" "))
(Turtle pen-color)
```
---
    "red"

### penwidth sets state

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "penwidth 3 "))
(Turtle pen-width)
```
---
    3.0

## repeat forever

### stop breaks repeat forever

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "to limited [ repeat forever [ fd 10 stop ] ] "))
(logo-process-tokens (Tok read-str (Logo base) "limited "))
(List length (Turtle bc))
```
---
    2

## comma-separated args

### two args in parens

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "to add a b [ return a + b ] "))
(def r (logo-parse-one-expr (Tok read-str (Logo base) "add(2 + 3, 10) ")))
(first r)
```
---
    15

### three args in parens

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "to sum3 a b c [ return a + b + c ] "))
(def r (logo-parse-one-expr (Tok read-str (Logo base) "sum3(1, 2, 3) ")))
(first r)
```
---
    6

## recursive procedures

### euclid gcd

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "to euclid n r [ if n = r then return n if n > r then return euclid(n - r, r) if n < r then return euclid(n, r - n) ] "))
(def r (logo-parse-one-expr (Tok read-str (Logo base) "euclid(360, 144) ")))
(first r)
```
---
    72

### factorial

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "to fact n [ if n <= 1 then return 1 return n * fact(n - 1) ] "))
(def r (logo-parse-one-expr (Tok read-str (Logo base) "fact(6) ")))
(first r)
```
---
    720

## if else

### else branch executes when false

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "if 1 > 5 then fd 100 else fd 50 "))
(Turtle y)
```
---
    -50.0

## execute

### execute runs string as logo

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "execute \"fd 100\" "))
(List length (Turtle bc))
```
---
    2

## member

### member finds element in list

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "to test.member [ return member(3, [1 2 3 4]) ] "))
(def r (logo-parse-one-expr (Tok read-str (Logo base) "test.member() ")))
(first r)
```
---
    #t

### member returns false for missing

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "to test.nomember [ return member(9, [1 2 3]) ] "))
(def r (logo-parse-one-expr (Tok read-str (Logo base) "test.nomember() ")))
(first r)
```
---
    #f

## setheading

### seth sets absolute heading

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "seth 180 "))
(Turtle heading)
```
---
    180.0

## bytecode format

### forward emits F bytecode

```scheme
(Turtle clearscreen)
(Turtle forward 100)
(first (List reverse (Turtle bc)))
```
---
    "F"

### right emits R bytecode

```scheme
(Turtle clearscreen)
(Turtle right 90)
(first (List reverse (Turtle bc)))
```
---
    "R"

### pencolor emits K bytecode

```scheme
(Turtle clearscreen)
(Turtle pencolor "red")
(first (List reverse (Turtle bc)))
```
---
    "K"

## grow and scaled forward

### grow scales s.forward

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "grow 2 s.fd 50 "))
(Turtle y)
```
---
    -100.0

## numeric argument guards

A block token in a numeric slot used to reach the float FFI unchecked and
segfault the engine; the %as-float/%as-int doors in state.x raise instead.

### a bracket block in a numeric slot raises type, not a crash

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "fd [ 1 2 ] "))
```
---
    Error: type: Logo: expected a number

### an indent block in a numeric slot raises type, not a crash

```scheme
(Turtle clearscreen)
(def toks (Tok read-str (Logo base) "\nfd\n    xcor\n "))
(logo-process-tokens (logo-indent-to-blocks toks))
```
---
    Error: type: Logo: expected a number

### a string distance still coerces

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "fd \"50\" "))
(Turtle y)
```
---
    -50.0

### a non-numeric repeat count raises type

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "repeat \"x\" [ fd 100 ] "))
```
---
    Error: type: Logo: expected a number

### a string repeat count coerces

```scheme
(Turtle clearscreen)
(logo-process-tokens (Tok read-str (Logo base) "repeat \"3\" [ fd 1 ] "))
(Turtle y)
```
---
    -3.0
