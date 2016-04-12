;;; junk-lib.l --- 使用頻度の高いライブラリ

(defun execute-buffer-file (&optional buffer)
  "編集中のバッファを関連付けられたプログラムで開く."
  (interactive)
  (shell-execute (or (get-buffer-file-name buffer)
                     (error "バッファを保存してください"))
                 t))

(defmacro with-set-directory (dir &body body)
  "一時的に(DEFAULT-DIRECTORY)をDIRに設定してBODYを実行する."
  `(let ((#1=#:odir (default-directory))
         (#2=#:obuf (selected-buffer)))
     (unwind-protect
         (progn (set-default-directory ,dir #2#) ,@body)
       (set-default-directory #1# #2#))))
(setf (get 'with-set-directory 'lisp-indent-hook) 1)

;; tips/ファイルの暗号化(Rijndael) より
;; http://xyzzy.s53.xrea.com/wiki/index.php?cmd=read&page=tips%2F%A5%D5%A5%A1%A5%A4%A5%EB%A4%CE%B0%C5%B9%E6%B2%BD(Rijndael)
(defmacro with-temp-file ((temp-file &rest args) &body body)
  `(let ((,temp-file ,(apply #'make-temp-file-name args)))
     (unwind-protect
         (progn ,@body)
       (delete-file ,temp-file :if-does-not-exist :error :if-access-denied :error))))
(setf (get 'with-temp-file 'ed:lisp-indent-hook) 1)
;; (with-temp-file (dest) (truename dest)) => "C:/tmp/~xyzirtx.tmp"

(defun echo (input &optional output)
  "INPUTストリームの中身をOUTPUTに流す.
デフォルトの出力先は*standard-output*."
  #+NIL
  ;; 1文字単位はさすがに遅い
  (do ((c #1=(read-char input nil :eof) #1#))
      ((eq c :eof))
    (write-char c output))
  #+xyzzy
  (loop
    ;; 末尾の改行も考慮するならread-lineは多値でとるべき
    (multiple-value-bind (line missing-newline-p)
        (read-line input nil #1='#:EOF)
      (message "Read: ~S" (list line missing-newline-p))
      (when (eq line #1#) (return))
      (princ line output)
      (unless missing-newline-p (terpri output)))))

(defun cat (file &optional stream (encoding :text))
  "print FILE contents to STREAM (default *standard-output*)."
  (with-open-file (fp file :direction :input)
    (set-stream-encoding fp encoding)
    (echo fp stream)))

(defun shell-command-to-string (command)
  "Execute shell command COMMAND and return its output as a string."
  (with-temp-file (outfile)
    (with-output-to-string (stream)
      (call-process command :output outfile :show :minimize :wait t)
      (cat outfile stream))))

(defun command-substitution (command)
  "外部コマンドの結果を文字列にして返します."
  (string-right-trim '(#\SPC #\TAB #\LFD)
    (shell-command-to-string command)))

(defmacro with-syntax-table (table &body body)
  "BODY を実行する際に一時的にシンタックステーブルを変更します."
  ;; バッファも保存するべき？
  `(let ((#1=#:syntab (syntax-table)))
     (unwind-protect
         (progn (use-syntax-table ,table) ,@body)
       (use-syntax-table #1#))))
(setf (get 'with-syntax-table 'ed:lisp-indent-hook) 1)

(defmacro with-lisp-syntax-table (&body body)
  `(with-syntax-table ed::*lisp-mode-syntax-table*
     ,@body))
(setf (get 'with-lisp-syntax-table 'lisp-indent-hook) 0)

(defun current-word (&optional highlight?)
  "カーソル位置にある単語を返します."
  (save-excursion
    (let* ((syntax (if (standard-char-p (following-char))
                       "w_" "w_jk"))
           (from (progn
                   (skip-syntax-spec-backward syntax)
                   (point)))
           (to (progn
                 (skip-syntax-spec-forward syntax)
                 (point))))
      (unless (eql from to)
        (prog1
            (buffer-substring from to)
          (and highlight? (reverse-region from to t)))))))

;; arglist
(defun show-arglist (symbol)
  (interactive "SArglist: ")
  (when (fboundp symbol)
    (message "(~A ~{~A~^ ~})" symbol (arglist symbol))))

(defun arglist (x)
  "Return function argment list."
  (labels ((arglist-helper (x)
             (cond ((consp x)
                    (mapcar #'arglist-helper x))
                   ((and (symbolp x) (not (keywordp x)))
                    (first (multiple-value-list (intern (string x)))))
                   (t
                    x))))
    (arglist-helper (arglist-1 x))))

(defun arglist-1 (x)
  (let* ((fn (or (and (consp x) (eq (car x) 'macro) x)
                 (coerce x 'function)))
         (cl (and (si:*closurep fn) (si:closure-body fn))))
    (cond ((si:*builtin-function-p fn)
           (labels ((symbol-builtin-function-name-p (sym)
                      (and (fboundp sym)
                           (si:*builtin-function-p (symbol-function sym))
                           sym))
                    ;; #'subr-name (Emacs)
                    (builtin-function-name (f)
                      (when (string-match "#<function: \\(.+\\)>"
                                          (princ-to-string f))
                        (match-string 1))))
             (get (some #'symbol-builtin-function-name-p
                        (find-all-symbols (builtin-function-name fn)))
                  'si::builtin-function-argument)))
          ((eq (car cl) 'lambda)
           (cadr cl))
          ((eq (safe-car fn) 'macro)
           (cadr fn)))))

(defun buffer-list-if (fn)
  "FNを満たすバッファのリストを返します."
  (remove-if-not fn (buffer-list)))

(defun process-list ()
  "バッファプロセスのリスト."
  (mapcar #'buffer-process
          (buffer-list-if #'buffer-process)))

(defun running-process-exist-p ()
  "動作中のプロセスがあるか."
  (some #'(lambda (pid)
            (eq (process-status pid) :run))
        (process-list)))

;; (remove-if-not #'need-buffer-save-p (buffer-list))
(defun modified-buffer-exist-p ()
  "保存する必要のあるバッファがあるか."
  (/= (count-modified-buffers) 0))

(defun delete-dump-and-compile-siteinit ()
  (delete-file (si:dump-image-path) :if-does-not-exist :skip)
  (let ((siteinit (find-load-path "siteinit")))
    (when (and siteinit (string-match "\\.lc$" siteinit))
      ;; *.lc が存在して *.l が存在しないなんて可能性があるんだが
      (trap-errors (compile-file (substring siteinit 0 -1))))))

;; 環境変数の変更が反映されないのはしょうがないのか
;; [注意]
;; (kill-xyzzy)する時にyes-no-or-cancel-p/yes-or-no-pに引っかかるとイヤになる
;; [関連するもの] バッファプロセス、保存、排他制御
;; (need-buffer-save-p buf) (verify-buffers-file-modtime) (buffer-modified-p &optional buf)
;; *kill-xyzzy-hook*に時間をかけるとまずいかも -> 先に実行させておこう
(defun reboot-xyzzy (&optional cleanup)
  "xyzzyを再起動する."
  (interactive "P")
  ;; (save-some-buffers)
  (cond ((and *query-kill-xyzzy-hook*
              (null (run-hook-with-args-while-success '*query-kill-xyzzy-hook*)))
         (return-from reboot-xyzzy))
        ((modified-buffer-exist-p) (error "保存をしよう、な！"))
        ((running-process-exist-p)
         (or (yes-no-or-cancel-p "サブプロセスを全部殺して再起動しますか?")
             (return-from reboot-xyzzy))
         (mapcar #'kill-process (process-list))
         (sleep-for 1.0))
        (:else nil))
  (when cleanup
    (delete-dump-and-compile-siteinit))
  (run-hooks '*kill-xyzzy-hook*)
  (let ((*kill-xyzzy-hook* nil)
        (*query-kill-xyzzy-hook* nil))
    (and (call-process (merge-pathnames "xyzzy.exe" (si:system-root))
                       ;; 環境変数の設定
                       :environ `(("XYZZYHOME" . ,(or (si:getenv "XYZZYHOME")
                                                      (map-slash-to-backslash
                                                       (remove-trail-slash
                                                        (si:system-root)))))
                                  ;; 設定ファイル (xyzzy.ini等) のディレクトリ
                                  ("XYZZYCONFIGPATH" . ,(or (si:getenv "XYZZYCONFIGPATH")
                                                            (user-config-path))))
                       :no-std-handles t
                       :exec-directory (si:system-root)
                       :show t
                       :wait nil)
         (kill-xyzzy))))

(setf (symbol-function 'restart-xyzzy) #'reboot-xyzzy)

(defun point-of (fn &rest args)
  "関数FNを呼び出した後のポイント位置を返す."
  (save-excursion (apply fn args) (point)))
;; (point-of #'goto-bol)

(defun map-internal-to-binary (input-string-or-stream &optional output-stream)
  (convert-encoding-to-internal *encoding-binary*
                                input-string-or-stream
                                output-stream))
(setf (symbol-function 'binary-string) #'map-internal-to-binary)

;;(setf (symbol-function 'hash->list) #'make-list-from-keyword-table)
(setf (symbol-function 'hash-keys) #'make-list-from-keyword-table)

(defun hash->alist (hash)
  (let (alist)
    (maphash #'(lambda (key value)
                 (push (cons key value) alist))
             hash)
    alist))

(defun hash->plist (hash)
  (let (plist)
    (maphash #'(lambda (key value)
                 (setf (getf plist (intern key :keyword)) value))
             hash)
    plist))

(defun sha1-file (pathspec)
  (with-open-file (s pathspec :encoding :binary)
    (si:sha-1 s)))

(defun md5-file (pathspec)
  (with-open-file (s pathspec :encoding :binary)
    (si:md5 s)))

(defun radix (num &optional (base 10))
  "数値NUMを基数BASEで表示します."
  #+nil
  (let ((*print-base* base)
        (*print-radix* t))
    (princ-to-string num))
  (format nil "#~Dr~:@(~VR~)" base base num))

;; 日付を36進数で表示
;; (radix (get-universal-time) 36)
;; => "#36r1OEMNOZ"
;; (iso8601-date (read-from-string *))
;; => "2015-10-06T13:53:35+09:00"

;; http://lisptips.com/post/43404489000/the-tree-walkers-of-cl
(defun walk-tree (fn tree)
  "The tree-walkers by Fn."
  (subst-if t (lambda (&rest args) nil) tree :key fn))

(defun fetch-url (url)
  "URLの中身を文字列として取得します."
  (labels ((vec2str (vector)
             (map 'string #'code-char vector)))
    (vec2str
     (let ((xhr (ole-create-object "MSXML2.XMLHTTP")))
       (ole-method xhr 'open "GET" url nil) ;; blocking!
       (ole-method xhr 'send nil)
       (ole-method xhr 'responseBody)))))
