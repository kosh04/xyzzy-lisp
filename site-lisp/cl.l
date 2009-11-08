;;; -*- Mode: Lisp; Package: USER; Encoding: Shift_JIS -*-

;;; cl.l --- xyzzy-lispにないCommonLisp関数群

;; This file is NOT part of xyzzy.

#|
TODO:
- その他関数などの補完
- パスネームオブジェクト P"", パスネーム型の定義
- assert, symbol-macrolet (cl-macs.el)
- typecase (encap+.l)
- ecase (loop/loop.l)
- disassemble (disassemble.l)
- fdefinition
|#
(provide "cl")

(in-package :lisp)

(shadow '(time) :winapi)

(export '(nth-value
          probe-file
          file-write-date
          lisp-implementation-type
          lisp-implementation-version
          make-string
          special-operator-p
          pprint
          with-standard-io-syntax
          progv
          sleep
          time                  ; 'winapi::time と被る可能性あり注意
          constantly
          function-lambda-expression
          name-char
          ensure-directories-exist
          ))

(defmacro nth-value (n form)
  "return only value the nth value yielded by form."
  `(nth ,n (multiple-value-list ,form)))

;;; PROBE-FILE returns false if there is no file named pathspec, and other
;;; wise returns the truename of pathspec.
(defun probe-file (pathname)
  "tests whether a file exists."
  (and (file-exist-p pathname)
       (truename pathname)))

(defun file-write-date (pathname)
  "Return a universal time representing the time at which the file specified
by pathspec was last written (or created), or returns nil if such a time
cannot be determined."
  (if (file-exist-p pathname)
      (file-write-time pathname)
      (error "file ~S does not exist" pathname)))

(setf (symbol-function 'lisp-implementation-type) #'software-type)
(setf (symbol-function 'lisp-implementation-version) #'software-version)

(defun make-string (size &key (initial-element #\null)
                         (element-type 'character))
  (if (subtypep element-type 'character)
      (make-array size
                  :initial-element initial-element
                  :element-type element-type)
      (error ":ELEMENT-TYPE argument must be a subtype of CHARACTER")))

;; Historically, this function was called special-form-p. The name was
;; finally declared a misnomer and changed, since it returned true for
;; special operators, not special forms.
(defun special-operator-p (symbol)
  "Returns true if symbol is a special operator, otherwise, returns false."
  (special-form-p symbol))
;; (setf (symbol-function 'special-operator-p) #'special-form-p)

(defun pprint (object &optional output-stream)
  "pprint is just like `print' except that the trailing space is omitted
and object is printed with the *print-pretty* flag non-nil to produce
pretty output. "
  (write object :stream output-stream :escape t :pretty t)
  (values))			; <no values>

(defmacro with-standard-io-syntax (&body body)
  "Within the dynamic extent of the body of forms, all control variables,
including any implementation-defned ones not specified by this standard,
are bound to values that produce standard read/print behavior. The values
for the variables specified by this standard are listed in the next figure."
  `(let ((*package* ,(find-package :user))
#-xyzzy  (*print-array* t)
         (*print-base* 10)
#-xyzzy  (*print-case* :upcase)
         (*print-circle* nil)
         (*print-escape* t)
#-xyzzy  (*print-gensym* t)
         (*print-length* nil)
         (*print-level* nil)
#-xyzzy  (*print-lines* nil)
#-xyzzy  (*print-miser-width* nil)
#-xyzzy  (*print-pprint-dispatch* *print-pprint-dispatch*) ; [The standard pprint dispatch table]
         (*print-pretty* nil)
         (*print-radix* nil)
         (*print-readably* t)
#-xyzzy  (*print-right-margin* nil)
#-xyzzy  (*read-base* 10)
         (*read-default-float-format* 'single-float)
#-xyzzy  (*read-eval* t)
         (*read-suppress* nil)
         (*readtable* (copy-readtable nil)) ; [The standard readtable]
         )
     ,@body))

;;; http://home.pipeline.com/~hbaker1/MetaCircular.html
(defconstant *unbound-value* (list nil))

(defun msymbol-value (var)
  (if (boundp var) (symbol-value var) *unbound-value*))

(defun mset (var val)
  (if (eq val *unbound-value*) (makunbound var) (set var val)))

(defmacro progv (syms vals &body forms)
  `(let* ((#1=#:vsyms ,syms)
          (#2=#:vvals ,vals)
          (#3=#:vovals (mapcar #'msymbol-value #1#)))
     (unwind-protect
         (progn
           (mapc #'mset #1# #2#)
           (mapc #'makunbound
                 (subseq #1# (min (length #1#) (length #2#))))
           ,@forms)
       (mapc #'mset #1# #3#))))

(setf (symbol-function 'sleep) #'editor:sleep-for)

(defmacro time (form)
  `(let ((#1=#:begin (get-internal-real-time)))
     (unwind-protect
         ,form
       (format t "Real time: ~A sec."
               (/ (- (get-internal-real-time) #1#) 1000.0)))))

(defun constantly (object)
  #'(lambda (&rest arguments) object))

(defun function-lambda-expression (def)
  "Returns information about function."
  (setq def (coerce def 'function))
  (values (if (si:*builtin-function-p def)
              nil
              (si:closure-body def))))

;; (char-name)
(defun name-char (name)
  "Returns the character object whose name is NAME.
If such a character does not exist, nil is returned."
  (if (typep name '(or string symbol character))
      (let ((lst (assoc (string name) si:*character-name-alist*
                        :test #'string-equal)))
        (if lst (ed:unicode-char (cdr lst))))
      (error "argument ~S should be a string, a symbol or a character" name)))

;; なんか違う気がする
(setf (symbol-function 'ensure-directories-exist) #'create-directory)

(export '(locally the))

;; $EMACS/lisp/emacs-lisp/cl-macs.el
(defmacro locally (&rest body) `(let nil ,@body))
(defmacro the (type form) form)

;; http://www.nhplace.com/kent/CL/Revision-18.lisp

;; http://www.grumblesmurf.org/corman-patches/sys/misc-features.lisp
#-xyzzy
(defmacro assert (test-form &rest rest)
  (let ((places (first rest))
        (msg    (second rest))
        (args   (cddr rest)))
    (declare (ignore places))
    (if (null msg)
        `(unless ,test-form (error "Assertion failed: ~A" ',test-form))
        `(unless ,test-form (error ,msg ,@args)))))

(defun read-sequence (sequence stream &key start end)
  (declare (ignore start end))
  (or end (setq end (length sequence)))
  (do ((i (or start 0) (1+ i))
       (c #1=(read-char stream nil :eof) #1#))
      ((or (eq c :eof) (<= end i))
       (return i))
    (setf (aref sequence i) c)))

;; (defparameter *data* (make-array 15 :initial-element nil))
;; (values (read-sequence *data* (make-string-input-stream "test string")) *data*)
;; => 11, #(#\t #\e #\s #\t #\SPC #\s #\t #\r #\i #\n #\g nil nil nil nil)



(setf (get 'progv 'ed:lisp-indent-hook) 2)
(setf (get 'locally 'ed:lisp-indent-hook) 1)

;;; cl.l ends here
