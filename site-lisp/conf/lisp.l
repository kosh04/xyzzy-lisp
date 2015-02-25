;;; conf.Lisp.l

;; Common Lisp ‚à‚Ç‚«Šg’£
(require "cl")

;; DESTRUCTURING-BIND
#+NIL
(progn
  (require "destructuring-bind")
  (import 'destructuring:destructuring-bind))
#+NIL
(require "dbind")

;; #?(printf debug)
(require "pp")
