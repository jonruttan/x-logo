# x-logo card

## Run

```sh
x -l logo
x -l logo -f PROGRAM.logo
x -l logo -f tests/card/euclid.logo -> 72
```

```logo
TO EUCLID N R
    IF N = R THEN RETURN N
    IF N > R THEN RETURN EUCLID(N - R, R)
    IF N < R THEN RETURN EUCLID(N, R - N)

PRINT EUCLID(360, 144)          ; -> 72
```

| Run                     | Is                                              |
|-------------------------|-------------------------------------------------|
| `x -l logo`             | the `?` prompt, and the viewer in a browser     |
| `x -l logo -f FILE`     | a program in a file: no prompt, no viewer       |
| `viewer: http://...`    | printed by a session: where the turtle draws    |

## Turtle

### Moving

| Command              | Does                                          |
|----------------------|-----------------------------------------------|
| `FORWARD N` `FD N`   | moves N steps the way the turtle faces        |
| `BACK N` `BK N`      | moves N steps backward                        |
| `RIGHT A` `RT A`     | turns A degrees clockwise                     |
| `LEFT A` `LT A`      | turns A degrees the other way                 |
| `SETXY X Y`          | moves to a point                              |
| `SETX X` `SETY Y`    | moves along one axis                          |
| `SETHEADING A` `SETH A` | faces A degrees                            |
| `HOME`               | goes to 0 0, facing 0                         |

```logo
FD 100
PRINT YCOR                      ; -> -100.0
RT 90
FD 50
PRINT XCOR                      ; -> 50.0
PRINT HEADING                   ; -> 90.0
LT 45
PRINT HEADING                   ; -> 45.0
HOME
PRINT TURTLE.STATE              ; -> (0.0 0.0 0.0 #t)
```

```logo
SETXY 30 40
PRINT DISTANCE(0, 0)            ; -> 50.0
SETX 5
SETY 6
PRINT XCOR                      ; -> 5.0
PRINT YCOR                      ; -> 6.0
SETH 180
BK 10
PRINT YCOR                      ; -> -4.0
```

### Pen and screen

| Command               | Does                                         |
|-----------------------|----------------------------------------------|
| `PENUP` `PU`          | moves without drawing                        |
| `PENDOWN` `PD`        | draws again                                  |
| `PENCOLOR C` `PC C`   | the line's colour: `"red"`, `"#FF0000"`      |
| `PENWIDTH N` `PW N`   | the line's width                             |
| `HIDETURTLE` `HT`     | hides the turtle                             |
| `SHOWTURTLE` `ST`     | shows it                                     |
| `CLEARSCREEN` `CS`    | clears the drawing, and sends the turtle home |

```logo
PC "red"
PW 2
PU
FD 10
PD
FD 10
HT
PRINT YCOR                      ; -> -20.0
CS
PRINT TURTLE.STATE              ; -> (0.0 0.0 0.0 #t)
```

### Asking

| Function          | Gives                                            |
|-------------------|--------------------------------------------------|
| `XCOR` `YCOR`     | where the turtle is                              |
| `HEADING`         | the way it faces, in degrees                     |
| `DISTANCE(X, Y)`  | how far the point is                             |
| `TOWARDS(X, Y)`   | the heading that faces the point                 |
| `TURTLE.STATE`    | x, y, the heading, and whether the pen is down   |

### Scaled

| Command               | Does                                         |
|-----------------------|----------------------------------------------|
| `GROW F`              | multiplies the scale by F                    |
| `S.FORWARD N` `S.FD N` | moves N steps times the scale               |

```logo
GROW 2
S.FD 10
PRINT YCOR                      ; -> -20.0
```

## Expressions

| Form                    | Is                                           |
|-------------------------|----------------------------------------------|
| `42` `3.7` `-1.5`       | a number                                     |
| `"text"`                | a string                                     |
| `[ ... ]`               | a block: a list, or commands to run          |
| `+ - * /`               | arithmetic; `/` gives a decimal              |
| `^`                     | a power                                      |
| `= <> < > <= >=`        | comparison: `TRUE` or `FALSE`                |
| `( )`                   | grouping                                     |
| `; text`                | a comment, to the end of the line            |

```logo
PRINT 2 + 3 * 4                 ; -> 14
PRINT (2 + 3) * 4               ; -> 20
PRINT 10 - 3 - 2                ; -> 5
PRINT 7 / 2                     ; -> 3.5
PRINT 2 ^ 10                    ; -> 1024.0
PRINT 1.5 + 1                   ; -> 2.5
PRINT -5 + 2                    ; -> -3
PRINT 3 > 2                     ; -> TRUE
PRINT 3 = 4                     ; -> FALSE
PRINT 3 <> 4                    ; -> TRUE
PRINT 2 >= 2                    ; -> TRUE
```

### Functions

| Function              | Gives                                        |
|-----------------------|----------------------------------------------|
| `SQRT(N)` `ABS(N)`    | the square root; the size without the sign   |
| `SIN(A)` `COS(A)` `TAN(A)` | of an angle in degrees                  |
| `ARCTAN(N)`           | the angle, in degrees                        |
| `POWER(N, P)`         | N to the power P                             |
| `REMAINDER(N, D)`     | what is left of N divided by D               |
| `ROUND(N)` `INT(N)`   | the nearest whole number; the one below      |
| `RAND(LOW, HIGH)`     | a whole number from LOW to HIGH              |
| `PI`                  | 3.14159...                                   |
| `NOT(T)`              | the other truth value                        |
| `MEMBER(X, [LIST])`   | whether X is in the list                     |

```logo
PRINT SQRT(144)                 ; -> 12.0
PRINT ABS(-7)                   ; -> 7
PRINT SIN(90)                   ; -> 1.0
PRINT COS(0)                    ; -> 1.0
PRINT TAN(45)                   ; -> 1.0
PRINT ARCTAN(1)                 ; -> 45.0
PRINT POWER(2, 10)              ; -> 1024.0
PRINT REMAINDER(17, 5)          ; -> 2
PRINT ROUND(3.7)                ; -> 4
PRINT INT(3.9)                  ; -> 3
PRINT RAND(1, 1)                ; -> 1
PRINT PI                        ; -> 3.14159265358979
PRINT NOT(1 > 2)                ; -> TRUE
PRINT MEMBER(2, [1 2 3])        ; -> TRUE
```

## Variables

| Form           | Does                                               |
|----------------|----------------------------------------------------|
| `X <- VALUE`   | sets X                                             |
| `X`            | its value                                          |
| `PRINT VALUE`  | prints the value and ends the line                 |
| `TYPE VALUE`   | prints the value and stays on the line             |

```logo
X <- 10
X <- X + 1
PRINT X                         ; -> 11
TYPE X
TYPE " "
PRINT "hello"                   ; -> 11 hello
```

## Control

| Form                             | Runs                                   |
|----------------------------------|----------------------------------------|
| `REPEAT N [ ... ]`               | the block N times                      |
| `REPEAT FOREVER [ ... ]`         | the block, until `STOP`                |
| `REPEAT [ ... ] UNTIL TEST`      | the block, until TEST holds            |
| `IF TEST THEN A`                 | A when TEST holds                      |
| `IF TEST THEN A ELSE B`          | A, or B                                |
| `IF NOT TEST THEN A`             | A when TEST does not hold              |
| lines indented under a line      | that line's block, in place of `[ ]`   |

```logo
REPEAT 3 [ TYPE "a" ]
PRINT ""                        ; -> aaa

N <- 0
REPEAT [ N <- N + 3 ] UNTIL N > 10
PRINT N                         ; -> 12

IF N > 5 THEN PRINT "big" ELSE PRINT "small"    ; -> big
IF NOT N < 0 THEN PRINT "positive"              ; -> positive

IF N > 5 THEN
    PRINT "yes"                 ; -> yes
    PRINT N                     ; -> 12
PRINT "after"                   ; -> after
```

## Procedures

| Form                        | Is                                          |
|-----------------------------|---------------------------------------------|
| `TO NAME ARG...`            | a procedure; its body is the indented lines |
| `TO NAME ARG... [ ... ]`    | the same, on one line                       |
| `NAME 1 2`                  | a call, as a command                        |
| `NAME(1, 2)`                | a call, for its value                       |
| `RETURN VALUE`              | leaves the procedure with a value           |
| `STOP`                      | leaves it                                   |

```logo
TO SQUARE SIZE
    REPEAT 4
        FD SIZE
        RT 90

SQUARE 20
PRINT HEADING                   ; -> 360.0

TO DOUBLE N [ RETURN N * 2 ]
PRINT DOUBLE(21)                ; -> 42

TO COUNTDOWN K
    IF K = 0 THEN STOP
    TYPE K
    COUNTDOWN K - 1

COUNTDOWN 3
PRINT ""                        ; -> 321
```

## Files

| Command             | Does                                            |
|---------------------|-------------------------------------------------|
| `LOAD "FILE"`       | runs the Logo in FILE                           |
| `EXECUTE "TEXT"`    | runs TEXT as Logo                               |

```logo
EXECUTE "print 6 * 7"           ; -> 42
LOAD "examples/ch1.logo"
ARCR 1 90
PRINT HEADING                   ; -> 90.0
```

## Differs

| Here                                  | In Berkeley Logo                     |
|---------------------------------------|--------------------------------------|
| `X <- 10`                             | `MAKE "X 10`                         |
| `X` is the variable's value           | `:X`                                 |
| `"text"`, closed by a quote           | `"word`, one word, no closing quote  |
| `NAME(1, 2)` for a value              | `NAME 1 2`                           |
| `RETURN VALUE`                        | `OUTPUT VALUE`                       |
| indented lines are a block            | a body ends at `END`                 |
| `FD 100` from home: `YCOR` is -100.0  | 100                                  |
| `PRINT [1 2 3]` prints `[ ... ]`      | `1 2 3`                              |
| four right turns: `HEADING` is 360.0  | 0                                    |

## More

| Where                       | What                                      |
|-----------------------------|-------------------------------------------|
| `README.md`                 | the viewer, the architecture, the tests   |
| `examples/ch1.logo`         | the programs of Turtle Geometry, chapter 1 |
| `examples/decimals.logo`    | decimal literals                          |
| `make card`                 | runs every program on this page           |
