;;; -*- Mode: Lisp -*-

;; 簡単なトレースルーチン
;; COMMON LISP 第2版 の `evalhook' より
;; 参考: xyzzy Part11 >>233

(provide "trace")

;; (in-package :lisp)

;; (export '(hook))

(defvar *hooklevel* 0)

(defmacro hook (form)
  `(let ((*hooklevel* 0)
	 (*evalhook* #'eval-hook-function))
     ,form))

(defun eval-hook-function (form env)
  (let ((*hooklevel* (1+ *hooklevel*)))
    (format t "~&~V@TForm: ~S" (* *hooklevel* 2) form)
    (let ((values (multiple-value-list
		   (evalhook form #'eval-hook-function nil env))))
      (format t "~&~V@TValue: ~{~S~^ ~}" (* *hooklevel* 2) values)
      (values-list values))))

#|
(hook (cons (floor *print-base* 2) 'b))
  Form: (cons (floor *print-base* 2) 'b)
    Form: (floor *print-base* 2)
      Form: *print-base*
      Value:  10
      Form: 2
      Value:  2
    Value:  5 0
    Form: 'b
    Value:  b
  Value:  (5 . b)
(5 . b)
|#
