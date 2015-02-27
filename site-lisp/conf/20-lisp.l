;;; conf.Lisp.l

;; Common Lisp もどき拡張
(require "cl")

;; DESTRUCTURING-BIND
#+NIL
(progn
  (require "destructuring-bind")
  (import 'destructuring:destructuring-bind))

(require "dbind")
;(require "defmac")

;; #?(printf debug)
(require "pp")

(require "disassemble")
(require "profile")

;; テストスイート
;; C:/home/lxuser/code/lisp/cl-ansi-tests-20071218/
