;;; -*- Mode: Lisp; Package: newlisp; Encoding: Shift_JIS -*-
;;;
;;; newlispfn.l --- newLISP function CommonLisp(xyzzy) Port
;;;
;;; This file is NOT part of xyzzy.
;;;

(provide "newlispfn")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "xml-http-request"))

(defpackage "newlisp"
  #+xyzzy (:use "lisp" "editor" "xml-http-request")
  #-xyzzy (:use :common-lisp)
  (:nicknames :nl))

(in-package "newlisp")

#|
;; function
(export '(join eval-string sequence exists
          println amb date dup select slice symbols
          filter get-url file? directory?
          get-string pop-assoc
          nl-read-file nl-count nl-write-file))

;; macro
(export '(begin define fn sgn dostring))
|#


;; ##newlisp.c
(defun curry (proc form)
  #'(lambda (arg)
      (funcall proc form arg)))
#|
(funcall (nl::curry #'+ 10) 7)          => 17
(mapcar (nl::curry #'cons 'x) '(1 2 3)) => ((x . 1) (x . 2) (x . 3))
|#

(defmacro define (name-and-args &body body)
  (if (symbolp name-and-args)
      `(defparameter ,name-and-args ,@body)
      `(defun ,(car name-and-args) ,(cdr name-and-args)
         ,@body)))

(defmacro dostring ((sym string &optional (test ''nil)) &body body)
  `(do* ((#1=#:charlist ',(coerce string 'list) (cdr #1#))
         (,sym (car #1#) (car #1#))
         ($idx 0 (1+ $idx))
         (#2=#:break ,test ,test))
       ((or (null #1#) #2#) #2#)
     ,@body))
#|
(nl::dostring (c "newLISP" (= nl::$idx 3)) 
  (format t "~A~%" (cons nl::$idx c))
  (sleep 1))
|#

(defmacro begin (&body body)
  `(progn ,@body))

(defun read-expr (source &optional pkg err offset)
  (declare (ignore pkg err offset))
  (read-from-string source))

(defun eval-string (str &optional expr sym-context)
  (declare (ignore expr sym-context))
  (eval (read-expr str)))

;; (defmacro silent (&body body)
;;   "SUppress output of the return value."
;;   `(progn ,@body (values)))

(defun legalp (string)
  (= (nth 1 (multiple-value-list
             (read-from-string string)))
     (length string)))
;(setf (symbol-function 'legal?) #'legalp)
#|
(nl::legalp "one")              ;=> t
(nl::legalp "one two")          ;=> nil
|#

(defun println (&rest args)
  (dolist (arg args)
    (princ arg))
  (terpri))

#+xyzzy (setf (symbol-function '$) #'ed:match-string)


;; ##nl-list.c
(shadow '(count))
(defun count (list1 list2)
  (mapcar #'(lambda (x)
              (lisp:count x list2))
          list1))
;; (nl::count '(z a) '(z d z b a z y a)) => (3 2)

(setf (symbol-function 'exists) #'find-if)
(setf (symbol-function 'filter) #'remove-if-not)
(setf (symbol-function 'clean) #'remove-if)

(defun lookup (key list &optional index (default nil))
  (let ((result (assoc key list)))
    (or (and result (nth (or index (1- (length result))) result))
        default)))
#|
(nl::lookup 'x '((x 1) (y 2) (z 3)))       => 1
(nl::lookup 'x '((x "X") (y "Y") (z "Z"))) => "X"
|#

(defmacro pop-assoc (item alist &rest args)
  `(let ((#1=#:x (assoc ,item ,alist ,@args)))
     (when #1#
       (setq ,alist (delete #1# ,alist :test #'eq))
       #1#)))
#|
(let ((alist '((a "A") (b "B") (c "C") nil (d "D") (a "A"))))
  (nl::pop-assoc 'a alist)              ;=> (a "A")
  alist)
=> ((b "B") (c "C") nil (d "D") (a "A"))

(let ((alist '(("lisp" +) ("perl" -) ("ruby" *) ("prolog" /))))
  (nl::pop-assoc "perl" alist :test #'equal)
  alist)
=> (("lisp" +) ("ruby" *) ("prolog" /))
|#

#+xyzzy
(defun sequence (start end &optional (step 1))
  "Generates a sequence of numbers."
  (check-type step (integer 1 *))
  ;; (setq step (abs step))
  (let* ((reverse? (> start end))
         (compare-fn (if reverse? #'< #'>))
         (step-fn (if reverse? #'- #'+)))
    (do ((i start (funcall step-fn i step))
         (acc '()))
        ((funcall compare-fn i end) (nreverse acc))
      (push i acc))))


;; ##nl-liststr.c
#+common-lisp
(defun chop (sequence &optional (n 1))
  (subseq sequence 0 (- (length sequence) n)))

#+xyzzy
(defun chop (sequence &optional (n 1))
  (if (stringp sequence)
      (substring sequence 0 (- n))
    (butlast sequence n)))
#|
(nl::chop "newLISP")            => "newLIS"
(nl::chop "newLISP" 2)          => "newLI"

(nl::chop '(a b (c d) e))       => (a b (c d))
(nl::chop '(a b (c d) e) 2)     => (a b)
|#

(defun join (list-of-string &optional (str-joint "") bool-trial-joint)
  "Concatenates lthe given list of strings in LIST-OF-STRING."
  (if bool-trial-joint 
      (format nil (concatenate 'string "~{~A" str-joint "~}") list-of-string)
    (format nil (concatenate 'string "~{~A~^" str-joint "~}") list-of-string)))
#|
(nl::join '("this" "is" "a" "sentence"))     => "thisisasentence"
(nl::join '("this" "is" "a" "sentence") " ") => "this is a sentence"
(nl::join '("2009" "03" "22") "-")           => "2009-03-22"
(nl::join '("A" "B" "C") "-")                => "A-B-C"
(nl::join '("A" "B" "C") "-" t)              => "A-B-C-"
|#

;; (make-sequence 'string 5 :initial-element #\A)
(defun dup (obj &optional (n 2) listp)
  (if (and (stringp obj) (null listp))
      (apply #'concatenate 'string
             #1=(make-sequence 'list n :initial-element obj))
    #1#))
#|
(nl::dup "A" 6)                 => "AAAAAA"
(nl::dup "A" 6 t)               => (#1="A" #1# #1# #1# #1# #1#)
(nl::dup "A" 0)                 => ""
(nl::dup "AB" 5)                => "ABABABABAB"
(nl::dup 9 7)                   => (9 9 9 9 9 9 9)
(nl::dup 9 0)                   => nil
(nl::dup 'x 8)                  => (x x x x x x x x)
(nl::dup '(1 2) 3)              => (#1=(1 2) #1# #1#)
(nl::dup (string #\null) 4)     => "^@^@^@^@"
(nl::dup "*")                   => "**"
|#

(defun select (seq &rest selection)
  (map (if (stringp seq) 'string 'list)
       #'(lambda (x) (elt seq x))
       (let ((length (length seq)))
         (mapcar #'(lambda (n)
                     (if (plusp n) n (mod n length)))
                 (if (listp (car selection))
                     (car selection)
                   selection)))))
#|
(nl::select '(a b c d e f g) '(-2 -1 0))   => (f g a)
(nl::select '(a b c d e f g) '(0 3 2 5 3)) => (a d c f d)
(nl::select '(a b c d e f g) 0 3 2 5 3)    => (a d c f d)
(nl::select "abcdefg" '(0 3 2 5 3))        => "adcfd"
(nl::select "abcdefg" '(-2 -1 0))          => "fga"
(nl::select "abcdefg" -2 -1 0)             => "fga"
|#

(defun slice (seq start &optional length)
  (let ((slength (length seq)))
    (and (minusp start)
         (setq start (+ start slength)))
    (subseq seq start (cond ((null length)   nil)
                            ((minusp length) (+ slength length))
                            (t               (+ start length))))))
#|
(nl::slice '(a b c d e f) 3 2)       => (d e)
(nl::slice '(a b c d e f) 2 -2)      => (c d)
(nl::slice '(a b c d e f) 2)         => (c d e f)
(nl::slice '(a b c d e f) -4 3)      => (c d e)
(nl::slice '((1 2) (3 4) (5 6)) 1 2) => ((3 4) (5 6))

(nl::slice "Hello World" 6 2)   => "Wo"
(nl::slice "Hello World" 0 5)   => "Hello"
(nl::slice "Hello World" 6)     => "World"
(nl::slice "newLISP" -4 2)      => "LI"
|#


;; ##nl-math.c

(defun amb (&rest symbols)
  (nth (random (length symbols)) symbols))
#|
(dotimes (x 10)
  (nl::println (apply #'nl::amb '(a b c d e f))))
|#

;; (or `nif' from "On Lisp")
(defmacro sgn (test &optional minus-form zero-form plus-form)
  (if (null minus-form)
      `(let ((#1=#:g ,test))
         (cond ((minusp #1#) -1)
               ((zerop #1#)   0)
               (t             1)))
    `(let ((#2=#:g ,test))
       (cond ((minusp #2#) ,minus-form)
             ((zerop #2#)  ,zero-form)
             (t            ,plus-form)))))
#|
(nl::sgn -3.5)                  => -1
(nl::sgn 0)                     => 0
(nl::sgn 123)                   => 1

(nl::sgn 3 "-1" "0" "1")        => "1"
|#

(defun seed (state)
  (check-type state number)
  (make-random-state state))


;; ##nl-filesys.c

(defun ! (command)
  (user::with-temp-file (file)
    (call-process command :output file :show :hide :wait t)
    (user::cat file)))
#|
(nl::! "ls -l")
|#

(setf (symbol-function 'file?) #'file-exist-p)
(setf (symbol-function 'directory?)  #'file-directory-p)

(shadow '(read-file))
(defun read-file (path)
  (if (string-match "^http://" path)
      (get-url path)
    (with-output-to-string (out)
      (user::cat path out))))

(defun writeFile (filename buffer &key if-exists)
  (with-open-file (out filename
                       :direction :output
                       :encoding :binary
                       :if-exists if-exists
                       :if-does-not-exist :create)
    (princ buffer out))
  (length buffer))

(shadow '(write-file))
(defun write-file (filename buffer)
  (writeFile filename buffer :if-exists :overwrite))

(shadow '(append-file))
(defun append-file (fileame buffer)
  (writeFile filename buffer :if-exists :append))

#|
(defun appendWriteFile (param type)
  #+emacs
  (let ((buf (create-new-buffer " *nl-write-file*")))
    (unwind-protect
        (save-excursion
          (set-buffer buf)
          (insert str-buffer)
          ;; (rename filename "nowarn") (save-buffer)
          (write-region (point-min) (point-max) filename))
      (or (deleted-buffer-p buf)
          (delete-buffer buf))))
  #+(or common-lisp xyzzy)
  (with-open-file (out filename
                       :direction :output
                       :encoding :binary
                       :if-exists :overwrite
                       :if-does-not-exist :create)
    (princ str-buffer out))
  (file-length filename))
|#

(setf (symbol-function 'make-dir) #'create-directory)
(setf (symbol-function 'remove-dir) #'delete-directory)
(setf (symbol-function 'change-dir) #'set-default-directory)

(defun now (&optional offset)
  (multiple-value-bind (sec min hour day month year tz)
      (decode-universal-time (or offset (get-universal-time)))
    (list year month day hour min sec
          ;; FIXME:
          0                     ; microsecond
          0                     ; day of current-year
          0                     ; day of current-week
          0                     ; time zone offset in minutes
          0                     ; daylight savings time type
          )))
;(nl::now)                      => (2010 1 16 12 21 38 0 0 0 0 0)

#+xyzzy
(defun date (&optional (universal-time (get-universal-time))
                       (offset 0)
                       (str-format "%a %b %d %H:%M:%S %Y"))
  (ed:format-date-string str-format
                         (+ universal-time (* offset 60))))
#|
(nl::date)                      => "Sat Jan 16 06:55:55 2010"
(nl::date 0)                    => "Mon Jan 01 09:00:00 1900"
(nl::date (nl::date-value) 300) => "Sat Jan 16 11:58:25 2010"
|#

(defun date-value (&optional year month day hour min sec &rest args)
  (declare (ignore args))
  (unless year
    (return-from date-value (get-universal-time)))
  (unless hour
    (setq hour 0 min 0 sec 0))
  (encode-universal-time sec min hour day month year))
#|
(nl::date-value)                     => 3472633115
(nl::date (nl::date-value 2010 1 1)) => "Fri Jan 01 00:00:00 2010"
(apply #'nl::date-value (nl::now))   => 3472633972
|#


;; ##nl-matlix.c
(defun transpose (seq)
  (apply #'mapcar #'list seq))
#|
(nl::transpose '((1 2 3) (4 5 6)))    ;=> ((1 4) (2 5) (3 6))
(nl::transpose (list (sequence 1 5))) ;=> ((1) (2) (3) (4) (5))
(nl::transpose '((a b) (c d) (e f)))  ;=> ((a c e) (b d f))

(nl::transpose '((1 2 3) X (7 8 9)))  ;=> ERR 
|#


;; ##nl-string.c
#+xyzzy
(defun get-string (addr)
  (check-type addr (integer #x0300000 *))
  (si:unpack-string (si:make-chunk nil 1024 nil addr) 0 nil t))

(defun explode (sequence &optional (chunk 1) (ignore-short nil))
  (let ((acc '())
        (len (length sequence)))
    (do ((from 0 idx)
         (idx chunk (+ idx chunk)))
        ((< len idx)
         (when (and (< len idx) (/= from len) (not ignore-short))
           (push (subseq sequence from len) acc)))
      (push (subseq sequence from idx) acc))
    (nreverse acc)))
#|
(nl::explode "newLISP")         ;=> ("n" "e" "w" "L" "I" "S" "P")
(nl::explode "newLISP" 2)       ;=> ("ne" "wL" "IS" "P")
(nl::explode "newLISP" 3)       ;=> ("new" "LIS" "P")
;; omit last chunk if too short
(nl::explode "newLISP" 3 t)     ;=> ("new" "LIS")

;; also works on binary content
(nl::explode "\000\001\002\003") ;=> (" " "" "" "")

(nl::explode '(a b c d e f g) 2) ;=> ((a b) (c d) (e f) (g))

(nl::transpose (explode '(a b c d e f g h) 2))
|#

(shadow '(float))
(defun float (x &optional (default nil))
  (if (stringp x) (setq x (read-from-string x)))
  (or (and (numberp x)
           (lisp:float x))
      default))

(defun int (x &optional (default nil) (base 10))
  ;; parse-integer cannot apply float-number
  (if (stringp x) (setq x (read-from-string x)))
  (if (numberp x)
      (identity (truncate x))   ; ignore multiple-value
    default))

#|
(nl::int "1.567")               ;=> 1
(nl::int 1.567)                 ;=> 1
(nl::int "1111" 0 2)            ;=> 15 (#b1111)
(nl::int "0FF" 0 16)            ;=> 255 (#x0FF)
(nl::int 'xyz 0)                ;=> 0 
|#

(defun regex (pattern text &optional (option 0) (offset 0))
  (when (string-match pattern text offset)
    (let ((data (match-data))
          (acc nil)
          start end)
      (dotimes (i 9)
        (setq start (elt data (* i 2))
              end   (elt data (1+ (* i 2))))
        (when start
          (push (subseq text start end) acc)
          (push start acc)
          (push end acc)))
      (nreverse acc))
    ))


;; ##nl-symbol.c
(defun symbols (&optional package)
  (let (acc)
    (do-symbols (sym (or package *package*))
      (push sym acc))
    (nreverse acc)))
#|
(nl::symbols "system")
(nl::symbols :lisp)
|#


;; ##nl-web.c

(defun get-url (url &optional option timeout header)
  (xhr-response-text (xhr-get url)))

(defun post-url (url content &optional option timeout header)
  (xhr-response-text (xhr-post url content
                               ;:headers (list header)
                               )))

#|
#+xyzzy
(defun get-url (url &optional (request "GET"))
  (setq request (string-upcase request))
  (multiple-value-bind (host port path)
      (and
       (or (string-match "https?://\\([a-z0-9.]+\\):?\\([0-9].+\\)?\\(.*\\)" url)
           (error "Bad URL Scheme: ~A" url))
       (values (match-string 1)
               (or (match-string 2) "<none>")
               (or (match-string 3) "")))
    (setq port (or (parse-integer port :junk-allowed t) 80))
    (unless (string= "/" path :end2 1)
      (setq path (concat "/" path)))
    (with-open-stream (s (connect host port))
      (format s "~A"
              (with-output-to-string (req)
                (format req "~A ~A HTTP/1.0~%" request path)
                (format req "User-Agent: xyzzy ~A (Win32)~%" (software-version))
                (format req "Host: ~A~%" host)
                (format req "~%")))
      (while (string/= (read-line s) "") ) ; ignore Headers
      (with-output-to-string (to)
        (user::echo s to)))))
|#

;;; newlispfn.l ends here
