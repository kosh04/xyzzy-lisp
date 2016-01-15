;;; with-alist-access.el --- a better alist macro

;; This is free and unencumbered software released into the public domain.

;; original: https://gist.github.com/skeeto/7edbedfdec3444925451

;;; Commentary:

;;; Example:

#|
(let ((student '((id . 1332412)
                 (name . ((first . "Student")
                          (last  . "Example")))))
      (teacher '(("subject" . math)
                 ("full-name" . "Teacher Example"))))
  (with-alist-access
    (list student.name.first teacher.full-name)))
|#
;; Result:

;;     => ("Student" "Teacher Example")

;;; Code:

(provide "with-alist-access")

#+common-lisp
(defun split-string (string &optional (separator " "))
  (labels ((split-str-1 (string &optional (separator " ") (r nil))
             (let ((n (position separator string
                                :from-end t
                                :test #'(lambda (x y)
                                          (find y x :test #'string=)))))
               (if n
                   (split-str-1 (subseq string 0 n) separator (cons (subseq string (1+ n)) r))
                 (cons string r)))))
    (split-str-1 string separator)))


(defun with-alist-access--transform-symbol (symbol)
  "Convert a symbol containing dots into an alist lookup."
  (let ((split (mapcar #'intern (split-string (symbol-name symbol) "."))))
    (if (= 1 (length split))
        symbol
      (reduce (lambda (object key)
                `(cdr (or (assoc ',key ,object :test #'eq)
                          (assoc ',(symbol-name key) ,object :test #'string=))))
              split))))

(defun with-alist-access--transform-sexp (sexp)
  "Transform a single s-expression for `with-alist-access'."
  (cons (car sexp)
        (loop for arg in (cdr sexp)
              collect (case (type-of arg)
                        (list   (with-alist-access--transform-sexp arg))
                        (symbol (with-alist-access--transform-symbol arg))
                        (otherwise arg)))))

(defmacro with-alist-access (&rest body)
  "Convert all variables of the form foo.bar into an alist lookup on foo.
This macro works on nested"
  (declare (indent 0))
  `(progn
     ,@(mapcar #'with-alist-access--transform-sexp body)))

#+xyzzy
(setf (get 'with-alist-access 'ed:lisp-indent-hook) 'progn)


#+COMMON-LISP
(let ((student '((id . 1332412)
                 (name . (("first" . "Student")
                          ("last"  . "Example")))))
      (teacher '(("subject" . math)
                 ("full-name" . "Teacher Example"))))
  (with-alist-access
    (print (list student.name.first teacher.full-name))
    ;;(print (macroexpand '(with-alist-access student.name.first))))
    ))

;;    (or (assoc 'full-name teacher :test #'eq)
;;        (assoc '"full-name" teacher :test #'equal))

;;; with-alist-access.el ends here
