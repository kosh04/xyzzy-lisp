;;; conf.Lisp.l

;; Common Lisp ���ǂ��g��
(require "cl")

;; DESTRUCTURING-BIND
#+NIL
(progn
  (require "destructuring-bind")
  (import 'destructuring:destructuring-bind))

;(require "dbind")
;(require "defmac")

;; #?(printf debug)
(require "pp")

(require "disassemble")
(require "profile")

;; �e�X�g�X�C�[�g
;; C:/home/lxuser/code/lisp/cl-ansi-tests-20071218/