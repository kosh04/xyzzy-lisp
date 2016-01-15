;;; -*- Mode: Lisp -*-
;;;
;;; xyzzylisp(or CL)にないelispを移植してみる
;;;

;; NOTE:
;;
;; あくまで xyzzylisp <-> elisp の変数、関数の対応表
;; #\a <-> 97 など文字型の考慮はしない
;; See katex/emacs.l

;; 追加情報 : CL->elisp
;; http://clocc.cvs.sourceforge.net/clocc/clocc/src/cllib/elisp.lisp?view=markup

(defpackage "emacs"
  (:use "lisp" "editor"))

;(in-package :emacs)


;;; Variable

(defvar exec-path (split-string (si:getenv "PATH") ";"))

;; This variable is obsolete since 21.1; do not use it.
(defconstant directory-sep-char #\/
  "Directory separator character for built-in functions that return file names.
The value is always ?/.  Don't use this variable, just use `/'.")

(defconstant path-separator
  (if (featurep #+clisp :win32
		#+xyzzy :windows-nt)
      ";" ":")
  "String containing the character that separates directories in
search paths, such as PATH and other similar environment variables.")

(defvar e (exp 1) "自然対数の底 e") ; or  defconstant



;;; Function

(si:*fset 'expand-file-name #'merge-pathnames)
(si:*fset 'file-name-directory #'directory-namestring)
(si:*fset 'file-exists-p #'file-exist-p)

(defun file-name-as-directory (pathname)
  (append-trail-slash (map-backslash-to-slash pathname)))

(setf (symbol-function 'aset) #'si:*aset)

(defun line-beginning-position (&optional n)
  "行頭のポイント."
  (save-excursion
    (if (not (or (null n) (eql n 1)))
	(forward-line n))
    (goto-bol) (point)))
(defun line-end-position (&optional n)
  "行末のポイント."
  (save-excursion
    (if (not (or (null nil) (eql n 1)))
	(forward-line (1- n)))
    (goto-eol) (point)))
(si:*fset 'point-at-bol #'line-beginning-position)
(si:*fset 'point-at-eol #'line-end-position)

#+nil
(defun substring (string start &optional end)
  "emacs互換substring(ENDに負数を指定できる)"
  (subseq string start (if (and end (minusp end))
                           (+ (length string) end)
                           end)))

(defun upcase-initials (obj)
  "Convert the initial of each word in the argument to upper case.
Do not change the other letters of each word.
The argument may be a character or string.  The result has the same type.
The argument object is not altered--the value is a copy."
  (cond ((characterp obj)
	 (char-upcase obj))
	((stringp obj)
	 (map 'string #'(lambda (x y)
			  (if (and (upper-case-p x)
				   (lower-case-p y))
			      x y))
	      obj
	      (string-capitalize obj)))
	(t
	 (error "require string or character: ~S" obj))))

(defun buffer-live-p (object)
  "Return non-nil if object is a buffer which has not been killed.
Value is nil if object is not a buffer or if it has been killed."
  (and (bufferp object)
       (deleted-buffer-p object)))

(si:*fset 'remove-hook #'delete-hook)

(defmacro put (symbol propname value)
  "Store symbol's propname property with value value."
  `(setf (get ,symbol ,propname) ,value))

;; 試してないです
(defun defalias (symbol definition &optional docstring)
  (setf (symbol-function symbol) definition)
  (if docstring
      (setf (get symbol 'function-documentation) docstring))
  symbol)

(defalias 'setcar #'rplaca)
(defalias 'setcdr #'rplacd)
(defalias 'beep #'ding)

(defun buffer-string ()
  (buffer-substring (point-min) (point-max)))

(defun memq (object list)       ; katex/emacs.l
  (lisp::member object list :test #'eq))

(defun booleanp (object)
  "Return non-nil if OBJECT is one of the two canonical boolean values: t or nil."
  (memq object '(nil t)))

;; エンコードとか適当
(defun set-process-coding-system (process &optional
                                          (decoding *encoding-binary*)
                                          (encoding *encoding-binary*))
  "Set coding systems of process to decoding and encoding.
decoding will be used to decode subprocess output and encoding to
encode subprocess input."
  (set-process-outcode process decoding)
  (set-process-incode process encoding))

(defun process-encoding (process)
  (cons (process-incode process)
        (process-outcode process)))

;; 逆かもしれない from-internal/to-internal
(defun decode-coding-string (string encoding &optional nocopy)
  (declare (ignore nocopy))
  (convert-encoding-from-internal encoding string))

(defun encode-coding-string (string encoding &optional nocopy)
  (declare (ignore nocopy))
  (convert-encoding-to-internal encoding string))

(defun string-to-multibyte (string)
  (decode-coding-string string *encoding-binary*))

;; or lisp/filer.l:147:
(defun file-truename (filename)
  (or (ignore-errors (resolve-shortcut filename))
      filename))

;; reb-with-current-buffer (re-builder.l)
(defmacro with-current-buffer (buffer &rest body)
  `(save-excursion
     (set-buffer ,buffer)
     ,@body))
(setf (get 'with-current-buffer 'lisp-indent-hook) 0)

(defmacro with-temp-buffer (&rest body)
  "Create a temporary buffer, and evaluate BODY there like `progn'.
See also `with-temp-file' and `with-output-to-string'."
  `(let ((#1=#:temp-buffer (create-new-buffer " *temp*")))
     (unwind-protect
         (with-current-buffer #1#
           ,@body)
       (and (buffer-name #1#)
            (kill-buffer #1#)))))
(setf (get 'with-temp-buffer 'lisp-indent-hook) 0)

(setf (symbol-function 'beep) #'ding)
(setf (symbol-function 'how-many) #'count-matches)

#|
(defun mapconcat (function sequence separator)
  (if separator
      (with-output-to-string (out)
        (dolist (c (coerce sequence 'list))
          (princ (funcall function c) out)
          (princ separator out)))
      (with-output-to-string (out)
        (dolist (c (coerce sequence 'list))
          (princ (funcall function c) out)))))
;(mapconcat #'(lambda (x) (code-char (1+ (char-code x)))) "HAL-8000" nil)
;=> "IBM.9111"
|#

#|
(mapconcat #'(lambda (x) (string (code-char (1+ (char-code x)))))
           "HAL-8000" nil)      ;=> "IBM.9111"
(mapconcat 'symbol-name '(The cat in the hat) " ") ;=> "The cat in the hat"
|#
(defun mapconcat (function sequence separator)
  (apply #'concatenate 'string
         (cdr (mapcan (lambda (el) (list separator el))
                      (map 'list function sequence)))))

(setf (symbol-function 'set-match-data) #'store-match-data)
(defmacro save-match-data (&body body)
  `(ed::protect-match-data ,@body))

;;; paths.el
(defun prune-directory-list (dirs &optional keep reject)
  (apply #'nconc
         (mapcar (lambda (dir)
                   (and (not (member dir reject))
                        (or (member dir keep) (file-directory-p dir))
                        (list dir)))
                 dirs)))

(defun assoc-string (key list &optional case-fold)
  (assoc key list
         :key #'string
         :test (if case-fold #'string-equal #'string=)))

(setf (symbol-function 'send-string) #'process-send-string)
(setf (symbol-function 'subrp) #'si:*builtin-function-p)

(defun put (symbol indicator value)
  (setf (get symbol indicator) value))

(defun ignore (&rest args)
  "Do nothing and return nil."
  (interactive)
  nil)

(defun char-width (ch)
  "Return width of ch when displayed in the current buffer."
  (char-columns ch))

(defun current-indentation ()
  "Return the indentation of the current line."
  (save-excursion
    (back-to-indentation)
    (current-column)))

(defun window-point (&optional window)
  "Return current value of point in WINDOW."
  (save-window-excursion
    (set-window window)
    (point)))

(defun format-time-string (fmt &optional utime universal)
  (declare (ignore universal))
  (format-date-string fmt utime))

(defun window-list (&optional frame minibuf window)
  "Return a list of windows on frame, starting with window."
  (mapcar #'second (third (current-window-configuration))))

;;; simple.el
(defun count-lines (start end)
  "Return number of lines between START and END.
This is usually the number of newlines between them,
but can be one more if START is not equal to END
and the greater of them is not at the start of a line."
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (goto-char (point-min))
      ;; (- (buffer-size) (forward-line (buffer-size)))
      (count-matches "\n" t t)
      )))

(defun count-lines-region (start end)
  "Print number of lines and characters in the region."
  (interactive "r")
  (message "Region has ~D lines, ~D characters"
           (count-lines start end) (abs (- end start))))


;;; Keymap
(dolist (key '(#\C-0 #\C-1 #\C-2 #\C-3 #\C-4 #\C-5 #\C-6 #\C-7 #\C-8 #\C-9))
  (global-set-key key 'digit-argument))

;;; emacs.l ends here
