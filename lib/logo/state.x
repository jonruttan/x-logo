; state.x -- Turtle state and movement primitives
(module logo/state)
(import logo/types)
(import x/num/float)

; The platform values this bundle reads, each through its public door:
; the type handles convert is asked for, and pi.  logo/math.x and
; logo/tstate.x read logo-pi too.
(def %logo-int-type (Type named INTEGER))
(def %logo-float-type (Type named FLOAT))
(def logo-pi (Float pi))

(def deg->rad
  (fn (_ deg) (Float / (Float * (as-float deg) logo-pi) (Float from 180))))

; Coercion doors: probe via the non-raising Convert dispatcher and check the
; RESULT, so strings keep coercing but an unconvertible token (e.g. a block
; in a numeric slot) raises here instead of crashing in the float FFI.
(def as-float
  (fn (_ n)
    (if (Float float? n) n
      (let ((f (Convert to n %logo-float-type)))
        (if (Float float? f) f
          (Err raise 'type "Logo: expected a number" n))))))

(def as-int
  (fn (_ n)
    (match
      ((Float float? n) (Float ->int n))
      ((Float integer? n) n)
      (#t (let ((k (Convert to n %logo-int-type)))
            (if (Float integer? k) k
              (Err raise 'type "Logo: expected a number" n)))))))

; ============================================================
; The turtle
; ============================================================

; The turtle's state lives in the static fields of one class, so every module
; that names Turtle reads the current value. A rebound global would not do:
; a selective import copies the value the global had when it was imported.
(def-class Turtle ()
  (static
    (x () "Position east of the origin, a FLOAT")
    (y () "Position south of the origin, a FLOAT: a move north decreases it")
    (heading () "Degrees clockwise from north, a FLOAT")
    (pen () "#t while the pen is down")
    (pen-color () "The pen colour, a CSS colour string")
    (pen-width () "The pen width, a FLOAT")
    (bc () "The bytecode emitted since the last clearscreen, newest first")
    (visible #t "#t while the turtle is shown")
    (scale () "The factor S.FORWARD multiplies its distance by, a FLOAT")
    (on-bc () "Called with each emitted opcode and its arguments; set by logo/main")
    (on-clear () "Called after clearscreen; set by logo/main")

    ; Prepends op and then its arguments, so the list read in reverse is the
    ; bytecode in the order emitted.
    (method emit (self op . args)
      (self bc (List append (List reverse args) (pair op (self bc))))
      (unless (null? (self on-bc)) (apply (self on-bc) (pair op args))))

    (method forward (self n)
      (def dist (as-float n))
      (self emit "F" dist)
      (def rad (deg->rad (self heading)))
      (self x (Float + (self x) (Float * dist (Float sin rad))))
      (self y (Float - (self y) (Float * dist (Float cos rad)))))

    (method back (self n) (self forward (- n)))

    (method right (self n)
      (def deg (as-float n))
      (self heading (Float + (self heading) deg))
      (self emit "R" deg))

    (method left (self n)
      (def deg (as-float n))
      (self heading (Float - (self heading) deg))
      (self emit "L" deg))

    (method penup (self) (self pen #f) (self emit "U"))
    (method pendown (self) (self pen #t) (self emit "D"))

    (method pencolor (self color)
      (self pen-color color)
      (self emit "K" color))

    (method penwidth (self width)
      (self pen-width (as-float width))
      (self emit "W" (as-float width)))

    (method setheading (self n)
      (self heading (as-float n))
      (self emit "H" (as-float n)))

    (method setxy (self px py)
      (def nx (as-float px))
      (def ny (as-float py))
      (self emit "M" nx ny)
      (self x nx)
      (self y ny))

    (method home (self)
      (self emit "O")
      (self x (Float from 0))
      (self y (Float from 0))
      (self heading (Float from 0)))

    (method distance (self px py)
      (def dx (Float - (as-float px) (self x)))
      (def dy (Float - (as-float py) (self y)))
      (Float sqrt (Float + (Float * dx dx) (Float * dy dy))))

    (method towards (self px py)
      (def dx (Float - (as-float px) (self x)))
      (def dy (Float - (self y) (as-float py)))
      (Float / (Float * (Float atan2 dx dy) (Float from 180)) logo-pi))

    ; TURTLE.STATE and SETTURTLE: position, heading and pen as one list.
    (method state (self)
      (list (self x) (self y) (self heading) (self pen)))

    (method setturtle (self lst)
      (self x (first lst))
      (self y (first (rest lst)))
      (self heading (first (rest (rest lst))))
      (self pen (first (rest (rest (rest lst))))))

    (method clearscreen (self)
      (self x (Float from 0))
      (self y (Float from 0))
      (self heading (Float from 0))
      (self pen #t)
      (self pen-color "#222")
      (self pen-width (Float from 1))
      (self bc ())
      (unless (null? (self on-clear)) ((self on-clear))))))

; The starting state is the cleared one; the scale is not reset by a clear.
(Turtle clearscreen)
(Turtle scale (Float from 1))

(provide logo/state
  Turtle as-float as-int deg->rad logo-pi)
