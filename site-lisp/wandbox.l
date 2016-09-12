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
   #:*profiles*
   #:*precompiled-hook*
   ))


(in-package :wandbox)

(eval-when (:compile-toplevel :load-toplevel :execute)

)

;; (defun http-request (method url data &key key headers)
;;   #-xyzzy (flexi-streams:octets-to-string (drakma:http-request url)))

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

(eval-when (:compile-toplevel :load-toplevel :execute)

  ;; JSON のアクセサもどき
  ;; - (path json "foo" 1 "bar" 2) => json.foo[1].bar[2]
  ;; - (path json '("key" . "value")) => json[key=value]
  (defun path (json &rest items)
    (reduce #'(lambda (obj item)
                (cond ((consp item)
                       (let ((key (car item))
                             (value (cdr item)))
                         (case value
                           (*  ;; (key . *) => $[key=*]
                            (loop for c in obj
                                  collect (cdr (find key c :key #'car :test #'equal))))
                           (t  ;; (key . value) => $[key=value]
                            (find value obj
                                  :key #'(lambda (x) (cdr (assoc key x :test #'equal)))
                                  :test #'equal)))))
                      ((stringp item)    ;; key => $[key]
                       (cdr (assoc item obj :test #'equal)))
                      ((integerp item)   ;; num => $[num]
                       (elt obj item))
                      (t
                       (error "Unknown item: ~a" item))))
            items :initial-value json))

  (defun make-profiles (compilers)
    (labels ((compiler-options (compiler)
               (labels ((join (list separator)
                          (format nil (concat "~{~a~^" separator "~}") list)))
                 (join (loop for s in (path compilers (cons "name" compiler) "switches")
                             if #3=(path s "default")
                             collect (if (stringp #3#) #3# (path s "name")))
                       ",")))
             (command-extension (x)
               (let ((cmd (path x "display-compile-command")))
                 (if (string-match " \\<prog\\.\\([A-Za-z0-9]+\\)\\>" cmd)
                     (match-string 1)
                   ""))))
      (loop for #1=#:compiler in compilers
            collect `(:lang ,(path #1# "language")
                      :name ,(path #1# "display-name")
                      :compiler ,#2=(path #1# "name")
                      :options ,(compiler-options #2#)
                      :nickname nil
                      :ext ,(command-extension #1#)))))

  (defstruct (server
              (:constructor make-server)
              (:constructor create-server
               (name location &aux
                     (api/list    (format nil "~a/api/list.json" location))
                     (api/compile (format nil "~a/api/compile.json" location))
                     (compilers (json:json-decode
                                 (msxml:xhr-get api/list :key 'msxml:xhr-response-text)))
                     (profiles (make-profiles compilers)))))
    "Server information."
    name
    location
    api/list
    api/compile
    compilers
    profiles)

  ) ;; ends eval-when

(defvar *servers*
  (list
   #.(create-server "melpon" "http://melpon.org/wandbox"))
  "利用可能なサーバの一覧")

(defvar *default-server-name* "melpon")

(defun find-server (name)
  (find name *servers* :key #'server-name :test #'string=))

(defun default-server ()
  (find-server *default-server-name*))

(defun add-server (name location)
  (or (find-server name)
      (push (create-server name location) *servers*)))

;; Profiles
(defvar *profiles* nil
  "Wandbox copmiler profiles (set of property list)")

(defun profile-nickname (key item &optional (server (default-server)))
  (getf (find-profile key item server) :nickname))

(defsetf profile-nickname (key item &optional server) (nickname)
  `(let ((#1=#:p (if ,server
                     (find-profile ,key ,item ,server)
                   (find-profile ,key ,item))))
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

(defun find-profile (key item &optional (server (default-server)))
  (find item (server-profiles server)
        :key #'(lambda (x) (getf x key '#:undef))
        :test #'string-equal))

(defun pretty-print (alist)
  (dolist (key *response-keywords*)
    (let ((msg (path alist key)))
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
                                    server
                               &allow-other-keys)
  (labels ((raw (x)
             (if (consp x) (format nil "~{~a~^~%~}" x) x))
           (boolean (x)
             (if x 'true 'false))
           (compiler-exist-p (server name)
             '(let* ((compiler-names
                     ;;(path (server-compilers server) '("name" . *))
                     (loop for c in (server-compilers server)
                           collect (cdr (find "name" c :key #'car :test #'string=)))
                     ))
               (find name compiler-names :test #'string=))
             (find name (server-compilers server)
                   :key #'(lambda (c) (cdr (find "name" c :key #'car :test #'string=)))
                   :test #'string=)
             ))
    #+nil ;; FIXME: スロット名(server-name)などは通るのに(server-p)だけがnilを返す場合がある
    (check-type server server)
    (unless (compiler-exist-p server compiler)
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
(defun build-request-data (&rest profile &key (server (default-server)))
  (labels ((merge-profile (plist &rest functions)
             (reduce #'(lambda (memo f)
                         (merge-plist memo (apply f memo)))
                     functions
                     :initial-value plist)))
    (let ((other-options (pick profile
                               :compiler :options :stdin :save
                               :compiler-option :runtime-option)))
      (apply #'build-request-data-raw :server server
             (merge-profile profile
                            #'(lambda (&key file &allow-other-keys)
                                (when file `(:code ,(fetch file))))
                            #'option-gist
                            #'(lambda (&rest p &key code)
                                (when code (with-input-from-string (s code)
                                             (scan-profile s))))
                            #'option-around-code
                            #'(lambda (&key name lang &allow-other-keys)
                                (cond (name (or (find-profile :name name server)
                                                (find-profile :nickname name server)))
                                      (lang (find-profile :lang lang))))
                            #'(lambda (&rest p)
                                other-options))))))

(defun post (server data)
  (let ((url (server-api/compile server))
        (json (json:json-encode data)))
    (msxml:xhr-post url json
                    :headers '(:Content-Type "application/json")
                    :key #'(lambda (res)
                             (json:json-decode
                              (msxml:xhr-response-text res))))))

(defun post-async (server data)
  (labels ((onsuccess (alist &aux (err (path alist "error")))
             (format *debug-output* "Wandbox RESPONSE: ~s" alist)
             (cond (err (message "error: ~a" err))
                   (t (to-buffer alist)
                      (refresh-screen)
                      (message "Compile...done"))))
           (oncomplele (res)
             (unless (= (xhr:xhr-status res) 200)
               (warn "~D ~A"
                     (xhr:xhr-status res)
                     (xhr:xhr-status-text res)))))
    (let ((url (server-api/compile server))
          (json (json:json-encode data)))
      (msxml:xhr-post-async url json
                            :key #'(lambda (res)
                                     (json:json-decode
                                      (xhr:xhr-response-text res)))
                            :headers '(:Content-Type "application/json")
                            :onsuccess  #'onsuccess
                            ;;:oncomplete  #'oncomplele
                            ))))

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
                     (sync nil)
                     (server-name "melpon")
                &aux (server (find-server server-name)))
  (unless server
    (error "Server not found: ~a" server-name))
  (let ((param (apply #'build-request-data :server server profile))
        (post (if sync #'post #'post-async)))
    (format *debug-output* "Wandbox PROFILE: ~s" profile)
    (format *debug-output* "Wandbox REQUEST_URL: ~a" (server-location server))
    (format *debug-output* "Wandbox REQUEST_DATA: ~s" param)
    (funcall post server param)))

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

;;;###autoload
(defun user::wandbox (&rest args)
  (interactive)
  (if (interactive-p)
      (call-interactively #'wandbox:compile-buffer)
    (apply #'wandbox:compile args)))

(unless *servers*
  ;;(push #.(create-server "melpon" "http://melpon.org/wandbox") *servers*)
  (push #.(create-server "fetus" "https://wandbox.fetus.jp") *servers*)

  (let ((s (find-server "melpon")))
    (setf (profile-nickname :name "mruby HEAD" s) "mruby")
    (setf (profile-nickname :name "erlang HEAD" s) "erlang"))
  )

;;; wandbox.l ends here
