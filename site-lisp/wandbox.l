;;; -*- Mode: Lisp; Package: Wandbox -*-

(provide "wandbox")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "json")
  (require "json-encode")
  (require "cmu_loop")
  (require "xml-http-request"))

#+common-lisp
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :quicklisp)          ; http://www.quicklisp.org/
  (require :alexandria)         ; http://common-lisp.net/project/alexandria/draft/alexandria.html
  (require :yason)              ; http://common-lisp.net/project/yason/
  (require :drakma)             ; http://weitz.de/drakma/
  nil)

(defpackage #:wandbox
  #+xyzzy (:use "lisp" "xml-http-request" "editor")
  #-xyzzy (:use #:common-lisp #:drakma #:cl-json)
  (:shadow
   #:compile
   #:compile-file
   #:eval-last-sexp)
  (:export
   #:compile
   #:eval-with
   #:eval-last-sexp
   #:compile-file
   #:compile-region
   #:compile-buffer
   #:+base-url+
   #:*compilers*
   #:*profiles*
   #:*precompiled-hook*
   ))


(in-package :wandbox)

;; Utility
(defun lookup (item alist &key (test #'equal))
  (cdr (assoc item alist :test test)))

;; JSON のアクセサもどき
;; - (path json "foo" 1 "bar" 2) => json.foo[1].bar[2]
;; - (path json '("key" . "value")) => json[key=value]
(defun path (json &rest items)
  (dolist (item items)
    (setf json (cond ((consp item)
                      (let ((key (car item))
                            (value (cdr item)))
                        (cond ((eq value '*)
                               ;; (key . *) => $[key=*]
                               (loop for c in json
                                     collect (cdr (find key c :key #'car :test #'equal))))
                              (t
                               ;; (key . value) => $[key=value]
                               (find value json
                                     :key #'(lambda (x)
                                              (cdr (assoc key x :test #'equal)))
                                     :test #'string=)))))
                     ((stringp item)
                      ;; key => $[key]
                      (cdr (assoc item json :test #'equal)))
                     ((integerp item)
                      ;; num => $[num]
                      (nth item json))
                     )))
  json)

(defun http-request (method url data &key key headers)
  #-xyzzy (flexi-streams:octets-to-string (drakma:http-request url)))

(defun fetch-file (filename)
  (labels ((echo (input &optional output)
             (loop
               (multiple-value-bind (line missing-newline-p)
                   (read-line input nil :eof)
                 (when (eq line :eof) (return))
                 (princ line output)
                 (unless missing-newline-p (terpri output))))))
    (with-output-to-string (s)
      (with-open-file (f filename)
        (echo f s)))))

(defun fetch-url (url)
  (xhr:xhr-get url :since :epoch :key 'xhr:xhr-response-text))

(defun fetch (src)
  (if (string-match "^https?://" src)
      (fetch-url src)
      (fetch-file src)))

(defun merge-plist (&rest args)
  (let ((result (copy-list (car args))))
    (dolist (plist (cdr args))
      (loop for (key value) on plist by #'cddr
            do (setf (getf result key) value)))
    result))

(defun pick (plist &rest keys)
  "Return a copy plist, filterd to only have values KEYS."
  (let (obj)
    (dolist (key keys)
      (let ((val (getf plist key)))
        (when val
          (setf (getf obj key) val))))
    obj))

;; API
(defconstant +base-url+ "http://melpon.org/wandbox")

;; TODO: BaseUrlをAPI定義時に固定させるかどうか
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro define-api-method (name &key method path headers sync)
    (let ((#1=#:url (concat (remove-trail-slash +base-url+) path))
          (#2=#:fname (intern (format nil "api-~a" name))))
      `(defun ,#2# (&key data (sync ,sync) onsuccess onfailure
                         (key 'msxml:xhr-response-text))
         (if sync
             (msxml:xhr-request       ,method ,#1# data
                                      :headers ,headers
                                      :key key)
           (msxml:xhr-request-async ,method ,#1# data
                                    :headers ,headers
                                    :key key
                                    :onsuccess onsuccess
                                    :onfailure onfailure)))))

  (define-api-method list-compilers
    :method "GET"
    :path "/api/list.json"
    :sync t)
  
  (define-api-method compile
    :method "POST"
    :path "/api/compile.json"
    :headers '(:Content-Type "application/json"))
  )

;; (define-api-method permalink ()
;;   :method "GET"
;;   :path "/permlink/:link")


(defparameter *response-keywords*
  '(
    ;;"compiler_output"
    ;;"compiler_error"
    "compiler_message"
    ;;"program_output"
    ;;"program_error"
    "program_message"
    "status"
    "signal"
    "permlink"
    "url"
    ))

;; (defvar *compilers-raw* (wandbox::api-list-compilers))


(defvar *compilers*
  (json:json-decode #.(api-list-compilers)))

;; Profiles
(defvar *profiles* '()
  "Wandbox copmiler profiles (set of property list)")

;; not used yet
(defstruct compile-params
  (compiler "" :type string)
  (options "")
  (code "")
  (stdin "")
  (compiler-option-raw "")
  (runtime-option-raw "")
  (save nil :type boole))

(defun make-profiles ()
  (loop for #1=#:compiler in *compilers*
        collect `(:lang ,(path #1# "language")
                  :name ,(path #1# "display-name")
                  :compiler ,#2=(path #1# "name")
                  :options ,(compiler-options #2#)
                  :nickname nil
                  :ext ,(command-extension #1#))))

(defun command-extension (x)
  (let ((cmd (path x "display-compile-command")))
    (if (string-match " \\<prog\\.\\([A-Za-z0-9]+\\)\\>" cmd)
        (match-string 1)
      "")))

(defun profile-nickname (key item)
  (getf (find-profile key item) :nickname))

(defsetf profile-nickname (key item) (nickname)
  `(let ((#1=#:p (find-profile ,key ,item)))
     (setf (getf #1# :nickname) ,nickname)))

(defun scan-profile (input)
  "ストリームINPUTからコンパイル用パラメータを探索します."
  (let ((params nil))
    (loop
      for line = (read-line input nil)
      while line
      do (when (string-match "#wandbox \\([a-z-]+\\): \\(.+\\)$" (or line ""))
           (let ((key (intern (match-string 1) "keyword"))
                 (val (match-string 2)))
             (setf (getf params key) val))))
    params))

(defun compiler-options (compiler)
  (labels ((join (list separator)
             (format nil (concat "~{~a~^" separator "~}") list)))
    (join (loop for s in (path *compilers* (cons "name" compiler) "switches")
                if #3=(lookup "default" s)
                collect (if (stringp #3#) #3# (lookup "name" s)))
          ",")))

(defun compiler-exist-p (name)
  (let ((compiler-names
         (path *compilers* '("name" . *))))
    (find name compiler-names :test #'string=)))

(defun find-profile (key item)
  (find item *profiles*
        :key #'(lambda (x) (getf x key '#:undef))
        :test #'string-equal))

(defun pretty-print (alist)
  (dolist (key *response-keywords*)
    (let ((msg (lookup key alist)))
      (when msg
        (format t "[~a]~%" key)
        (format t "~a~%~%" msg)))))

(defun to-buffer (alist)
  (with-set-buffer
    (with-output-to-temp-buffer (#1="*Wandbox Output*" nil)
      (pretty-print alist))
    (display-buffer #1#)))

(defun build-request-data-raw (&rest profile
                               &key compiler options code stdin save
                                    compiler-option runtime-option
                               &allow-other-keys)
  (labels ((raw (x)
             (if (consp x) (format nil "~{~a~^~%~}" x) x))
           (boolean (x)
             (if x 'true 'false)))
    (unless (compiler-exist-p compiler)
      (error "Unknown compiler: ~a" compiler))
    ;; NOTE: json-encode accepts only alist (plist unavailable).
    `(("compiler" . ,(or compiler ""))
      ("options"  . ,(or options ""))
      ("code"     . ,(or code ""))
      ("stdin"    . ,(or stdin ""))
      ("compiler-option-raw" . ,(or (raw compiler-option) ""))
      ("runtime-option-raw"  . ,(or (raw runtime-option) ""))
      ("save"     . ,(boolean save)))))

;; TODO: マージする順番
;; 1. ファイル名、gist指定をcodeに展開
;; 2. codeからbuffer profileを展開
;; 3. 言語指定(lang,name,ext)を展開
;; 4. 直接指定(compiler,options等)を展開
(defun build-request-data (&rest profile)
  (labels ((merge-profile (plist &rest functions)
             (reduce #'(lambda (memo f)
                         (merge-plist memo (apply f memo)))
                     functions
                     :initial-value plist)))
    (let ((other-options (pick profile
                               :compiler :options :stdin :save
                               :compiler-option :runtime-option)))
      (apply #'build-request-data-raw
             (merge-profile profile
                            #'(lambda (&key file &allow-other-keys)
                                (when file `(:code ,(fetch file))))
                            #'option-gist
                            #'(lambda (&rest p &key code)
                                (when code (with-input-from-string (s code)
                                             (scan-profile s))))
                            #'option-around-code
                            #'(lambda (&key name lang &allow-other-keys)
                                (cond (name (or (find-profile :name name)
                                                (find-profile :nickname name)))
                                      (lang (find-profile :lang lang))))
                            #'(lambda (&rest p)
                                other-options))))))

(defun post (data &key (sync nil))
  (api-compile :data (json:json-encode data)
               :sync sync
               :key #'(lambda (req)
                        (json:json-decode (xhr:xhr-response-text req)))
               :onsuccess #'(lambda (alist)
                              (let* ((err (lookup "error" alist)))
                                (cond (err (message "error: ~a" err))
                                      (:else
                                       (to-buffer alist)
                                       (refresh-screen)
                                       (message "Compile...done")))))
               ;; FIXME: 要確認-引数の型
               :oncomplete #'(lambda (res)
                               (unless (= (xhr:xhr-status res) 200)
                                 (warn "~D ~A"
                                       (xhr:xhr-status res)
                                       (xhr:xhr-status-text res))))))

(defun option-around-code (&rest profile &key code-before code code-after)
  ;; `concat' returns empty string if args nil
  (setf (getf profile :code) (concat code-before code code-after))
  profile)

(defun fetch-gist (id)
  (let* ((url (format nil "https://api.github.com/gists/~a" id)))
    (json:json-decode (fetch url))))

(defun option-gist (&key gist gist-file &allow-other-keys)
  (when gist
    (let* ((data (fetch-gist gist))
           (profile (find-profile :lang (path data "files" (or gist-file 0) "language"))))
      (setf (getf profile :code) (path data "files" 0 "content"))
      profile)))

(defvar *precompiled-hook* nil)

(add-hook '*precompiled-hook* 'option-around-code)
(add-hook '*precompiled-hook* 'option-gist)

(defun compile (&rest profile
                &key compiler options code stdin
                     compiler-option runtime-option
                     lang name file
                     (save nil)
                     (sync nil))
  (post (apply #'build-request-data profile) :sync sync))

(defmacro eval-with ((&rest options) &body form)
  (declare (indent 1))
  (let ((*print-circle* t))
    `(wandbox:compile :name "CLISP"
                      :code ,(prin1-to-string
                              `(let ((*print-circle* t))
                                 (format t "~{~s~^ ;~%~}"
                                         (multiple-value-list (progn ,@form)))))
                      ,@options)))

(setf (get 'eval-with 'ed:lisp-indent-hook) 1)

;; この辺からxyzzy用コマンド定義
;; 後で分割させるかも (wandbox-command.l)

(defun buffer-profile ()
  "現在のバッファからコンパイル用パラメータを探索します."
  (save-excursion
    (goto-char (point-min))
    (with-input-from-selected-buffer
      (scan-profile *standard-input*))))

;; FIXME: eval-with はマクロなので使えないのが不便
(defun eval-last-sexp ()
  (interactive)
  (let* ((*package* (find-package :user))
         (opoint (point))
         (form (read-from-string
                (buffer-substring (progn (backward-sexp 1 t) (point))
                                  (progn (forward-sexp) (point))))))
    (wandbox::compile :name "CLISP"
                      :code (prin1-to-string
                             `(let ((*print-circle* t))
                                (format t "~{~s~^ ;~%~}"
                                        (multiple-value-list ,form)))))))

(defun read-profile (&optional (key :name))
  (let* ((items (mapcar #'(lambda (x) (getf x key))
                        *profiles*))
         (name (completing-read "Profile: " items)))
    (find-profile key name)))

(defun compile-file (filename)
  "指定したファイルをコンパイルします."
  (interactive "fFile to wandbox: ")
  (let ((profile (or (find-profile :ext (pathname-type filename))
                     (read-profile))))
    (apply #'wandbox:compile :file filename profile)))

(defun compile-region (from to)
  "指定したリージョンをコンパイルします."
  (interactive "r")
  (let* ((path (get-buffer-file-name))
         (profile (or (buffer-profile)
                      (and path (find-profile :ext (pathname-type path)))
                      (read-profile)))
         (code (buffer-substring from to)))
    (apply #'wandbox:compile :code code profile)))

(defun compile-buffer ()
  "バッファ全体をコンパイルします."
  (interactive)
  (wandbox:compile-region (point-min) (point-max)))

(unless *profiles*
  (setf *profiles* (make-profiles))
  (setf (profile-nickname :name "mruby HEAD") "mruby")
  (setf (profile-nickname :name "erlang HEAD") "erlang")
  )

(in-package "user")

(defun wandbox (&rest args)
  (interactive)
  (if (interactive-p)
      (call-interactively #'wandbox:compile-buffer)
    (apply #'wandbox:compile args)))

;;; wandbox.l ends here
