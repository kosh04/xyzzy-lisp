;;; util.l -*- Mode: Lisp; Package: USER; Encoding: Shift_JIS -*-

;;; This file is NOT part of xyzzy.

(provide ".xyzzy")

(in-package "user")

(require "cl")

#+NIL
(progn
  (require "destructuring-bind")
  (import 'destructuring:destructuring-bind))

(require "dbind")

;; WIN32API
(require "wip/winapi")
(require "api")
;; コレのおかげでパッケージ名を省略できることを忘れずに...
(use-package "winapi")

;; 略記
(defun hwnd () (get-window-handle))
;; (setf (symbol-function 'hWndMain) #'get-window-handle)
(si:*fset 'TEXT #'si:make-string-chunk)
(c:*define NULL 0)

(require "wip/winapi")
;; wip/winapi.l で定義済み
;; (c:define-dll-entry winapi:BOOL ShowWindow (winapi:HWND c:int) "user32")
(defun iconify-xyzzy (&optional (hwnd (get-window-handle)))
  "起動中の xyzzy を最小化します."
  (interactive)
  (ShowWindow hwnd SW_MINIMIZE)) ; 6
(global-set-key '(#\C-x #\C-c) 'iconify-xyzzy)

;; http://hie.s64.xrea.com/xyzzy/note/buffer.html#maximize-xyzzy
(c:*define-dll-entry winapi:BOOL IsZoomed (winapi:HWND) "user32")
(defun maximize-xyzzy ()
  (interactive)
  (ShowWindow (get-window-handle) SW_MAXIMIZE)) ; 3
(defun restore-xyzzy ()
  "元のサイズに戻す."
  (interactive)
  (ShowWindow (get-window-handle) SW_RESTORE)) ; 9
(defun toggle-xyzzy-window ()
  (interactive)
  (if (zerop (IsZoomed (get-window-handle)))
      (maximize-xyzzy)
      (restore-xyzzy)))
(global-set-key #\M-F10 'toggle-xyzzy-window)

;; from estartup.l
(defun load-xyzzyrc ()
  "$XYZZY/.xyzzy のロード"
  (trap-errors
    (let ((*loading-user-initial-file* t)) ; 何の効果が?
      (load (merge-pathnames ".xyzzy" (si:system-root))
            :if-does-not-exist nil :verbose nil :print nil))))
;; USBからの起動に使えそう
;; (add-hook '*post-startup-hook* 'load-xyzzyrc)

;; nilなら、JIS X0208に存在する文字をUnicodeから内部コードに変換する際、
;; 日本語の文字として扱う (ChangeLog Version 0.2.2.205)
;; デフォルトは t
(setq *unicode-to-half-width* nil)

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

;; XyzzyWikiから拾ってきたんだと思う
(defun recentf-open-files ()
  "履歴からファイルを開く"
  (interactive)
  (let (hlist filename)
    (setq hlist (mapcar #'(lambda (x)
                            (list (abbreviate-display-string x 60 t) x))
                        *minibuffer-file-name-history*))
    (multiple-value-bind (result data)
        (dialog-box
         '(dialog 0 0 286 162
           ;;(:caption "最近使ったﾌｧｲﾙ")
           (:caption "最近使ったファイル")
           (:font 9 "ＭＳ Ｐゴシック")
           (:control
            (:listbox flist nil #x50b10111 7 7 216 148)
            (:button IDOK "OK" #x50010001 229 7 50 14)
            (:button IDCANCEL "ｷｬﾝｾﾙ" #x50010000 229 24 50 14)))
         (list (cons 'flist hlist))
         `((flist :must-match t :enable (IDOK))))
      (when result
        (setq filename (car (cddr (assoc 'flist data))))
        (find-file filename)
        (add-history filename '*minibuffer-file-name-history*)))))

#|
(defun foobar ()
  "最近開いたファイル"
  (interactive)
  (popup-list (subseq *minibuffer-file-name-history* 0 9)
              #'(lambda (file)
                  (find-file file)
                  (add-history file '*minibuffer-buffer-name-history*)
                  (refresh-screen))))
|#

;; 閉じたタブを元に戻す、を自分用に改変
;; TODO: ダイアログ使いたい
;; http://white.s151.xrea.com/wiki/index.php?memo%2Fxyzzy%2Ffile#k96261fd
(defvar *recent-killed-buffers* nil)

(defun push-visited-file-recent-killed (buffer)
  (when (file-visited-p buffer)
    (pushnew (get-buffer-file-name buffer)
             *recent-killed-buffers* :test #'path-equal))
  t)
(add-hook '*delete-buffer-hook* 'push-visited-file-recent-killed)

(defun recentf ()
  "最近閉じたファイル"
  (interactive)
  (unless *recent-killed-buffers*
    (error "最近閉じられたバッファはありますん"))
  (popup-list (subseq *recent-killed-buffers*
                      0 (min (length *recent-killed-buffers*) 9))
              #'(lambda (file)
                  (find-file file)
                  (add-history file '*minibuffer-buffer-name-history*)
                  (setf *recent-killed-buffers*
                        (delete file *recent-killed-buffers* :test #'equal))
                  (refresh-screen))))

;; 'si:*trace-on-error* とかクオートされたシンボルの値を評価したい
(defun get-variable-value ()
  "現在のポイント上にあるシンボルを評価します."
  (interactive)
  (let ((name (buffer-substring (progn
                                  (skip-syntax-spec-backward "w_")
                                  (point))
                                (progn
                                  (skip-syntax-spec-forward "w_")
                                  (point)))))
    (if (string= name "")
        ;;(return-from get-variable-value)
        (warn "symbol not found at point")
        (let ((symbol (multiple-value-bind (sym pac)
                          (values-list (reverse (split-string name ":")))
                        (when sym
                          ;; (find-symbol sym (or (find-package pac) (find-package *buffer-package*) *package*))
                          ;; 全てのシンボル名は被ることが無いという前提ありで使う
                          (some (lambda (x) (and (boundp x) x))
                                (find-all-symbols sym))
                          ))))
          (if (and symbol
                   (boundp symbol))
              (message "~S -> ~S" symbol (symbol-value symbol))
              (plain-error "変数が定義されていません: ~A" name))))))
(define-key spec-map #\C-e 'get-variable-value)

(defun kitaa ()
  (interactive)
  (let ((kita-list
         '("(ﾟ∀ﾟ)" "( ﾟ∀)" "(   ﾟ)" "(    )" "(ﾟ   )" "(∀ﾟ )" "(ﾟ∀ﾟ)")
         ))
    (while (not (listen *keyboard*))
      (dolist (kao kita-list)
        (minibuffer-message "ｷﾀ━━━~A━━━!!!!" kao)
        (sit-for .1)))))

;; バッファも保存するべき？
(defmacro with-syntax-table (table &body body)
  `(let ((#1=#:syntab (syntax-table)))
     (unwind-protect
         (progn (use-syntax-table ,table) ,@body)
       (use-syntax-table #1#))))
(setf (get 'with-syntax-table 'ed:lisp-indent-hook) 1)

;; $EMACS/lisp/comint.el
;; (point) が EOF ならプロセス終了
(defun comit-delchar-or-maybe-eof (&optional arg)
  "Delete ARG characters forward or send an EOF to subprocess.
Sends an EOF only if point is at the end of the buffer and there is no input."
  (interactive "p")
  (let ((proc (buffer-process (selected-buffer))))
    (if (and (eobp)
             proc
             (eq (process-status proc) :run)
             (eql (point) (marker-point (process-marker proc))))
        (kill-process proc)
        ;; (process-send-string proc (concat "exit" *shell-ret*))
      (delete-char arg))))
(define-key *shell-mode-map* #\C-d 'comit-delchar-or-maybe-eof)

;; slime-repl-bolより
(defun ed::shell-goto-bol ()
  (interactive)
  (let ((point-at-bol (save-excursion (goto-bol) (point)))
        (marker (ignore-errors
                 (marker-point
                  (process-marker (buffer-process (selected-buffer)))))))
    (if (and marker (<= point-at-bol marker (point)))
        (goto-char marker)
        (goto-bol))))
(define-key ed::*shell-mode-map* #\C-a 'ed::shell-goto-bol)

(defun shell-next-prompt (&optional (n 1))
  (interactive "p")
  (cond ((plusp n)
         (scan-buffer *shell-prompt-regexp* :regexp t :reverse nil :tail t :no-dup nil))
        ((minusp n)
         (previous-line)
         (scan-buffer *shell-prompt-regexp* :regexp t :reverse t :tail t :no-dup nil))
        (:else nil)))

(defun shell-previous-prompt (&optional (n 1))
  (interactive "p")
  (shell-next-prompt (- n)))

(define-key ed::*shell-mode-map* '(#\C-c #\C-p) 'shell-previous-prompt)
(define-key ed::*shell-mode-map* '(#\C-c #\C-n) 'shell-next-prompt)

(global-set-key '(#\C-c #\s)
                (defun shell-popup ()
                  (interactive)
                  (let ((shell-buffer
                         (save-window-excursion (shell) (selected-buffer))))
                    (unless (eq shell-buffer (selected-buffer))
                      (pop-to-buffer shell-buffer t)))))

(defun narrow-to-defun ()
  "Make text outside current defun invisible."
  (interactive)
  (save-excursion
    (widen)
    (narrow-to-region (progn (beginning-of-defun) (point))
                      (progn (end-of-defun)       (point)))))

(global-set-key '(#\C-x #\n #\d) 'narrow-to-defun)
;; (global-set-key '(#\C-x #\n #\n) 'narrow-to-region)
;; (global-set-key '(#\C-x #\n #\w) 'widen)

;; transient-mark-mode もどき
(defun keyboard-quit ()
  (interactive)
  (set-mark t)                  ; マークをクリア (ChangeLog Version 0.1.0.107)
  (error 'quit))
(global-set-key #\C-g 'keyboard-quit)

;; tips/ファイルの暗号化(Rijndael) より
;; http://xyzzy.s53.xrea.com/wiki/index.php?cmd=read&page=tips%2F%A5%D5%A5%A1%A5%A4%A5%EB%A4%CE%B0%C5%B9%E6%B2%BD(Rijndael)
(defmacro with-temp-file ((temp-file) &body body)
  `(let ((,temp-file ,(make-temp-file-name)))
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
        (read-line input nil :EOF)
      (when (eq line :EOF) (return))
      (princ line output)
      (unless missing-newline-p (terpri output)))))

(defun cat (file &optional stream)
  "print FILE contents to STREAM (default *standard-output*)."
  (with-open-file (fp file :direction :input)
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

;; 毎度毎度 do-all-symbols は時間がかかるのでキャッシュで誤魔化す
(defvar *keymaplist* nil)

(defun keymaplist (&optional force-update)
  (or (and (not force-update)
           *keymaplist*)
      (long-operation
        (do-all-symbols (sym *keymaplist*)
          (if (and (boundp sym)
                   (keymapp (eval sym)))
              (push sym *keymaplist*))
          ))))

(defun describe-binding-anymap (keymap)
  "任意のキーマップの割り当て一覧を表示."
  (interactive (find-all-symbols
                (completing-read "Describe binding: "
                                 (keymaplist)
                                 :must-match t)))
  (with-output-to-temp-buffer ((string keymap))
    (format t "~S:~%key~20Tbinding~%---~20T-------" keymap)
    (ed::describe-bindings-1 "" (eval keymap) nil)
    (goto-char (point-min))
    (toggle-read-only t)))

;; ed::build-summary-function を2回も呼び出すのは何かやだな
(defun goto-function (fn)
  (interactive
      (list (if (boundp 'ed::build-summary-function)
                (completing-read "Function: "
                                 (or (mapcar #'cadr (funcall ed::build-summary-function))
                                     (error "Function Not Found"))
                                 :must-match t)
                (error "関数ないよ"))))
  (let* ((summary (funcall ed::build-summary-function))
         (fnlst (mapcar #'cadr summary))
         (nlst  (mapcar #'car summary)))
    (goto-line (nth (position fn fnlst :test #'equal) nlst))))
(define-key spec-map #\C-l 'goto-function)

;; (require "paren") とかにもそれなりに対応
(defun ffap-find-file (filename)
  "find file at point."
  (interactive "fFind-file: " :default0 (pathname-at-point *prefix-args*))
  (find-file filename)
  (add-history filename '*minibuffer-file-name-history*))

(defun pathname-at-point (&optional arg)
  (let* ((skip-chars "-a-zA-Z0-9_/~.#@%?&=+(),'$!*:")
         (from (save-excursion
                 (skip-chars-backward skip-chars)
                 (point)))
         (to (save-excursion
               (skip-chars-forward skip-chars)
               (point)))
         (odir (default-directory)))
    (unless (eql from to)
      ;; (or (default-directory) (directory-namestring (get-buffer-file-name)))
      (set-default-directory (pwd))
      (let* ((word (buffer-substring from to))
             (path (cond ((file-exist-p word)
                          (if (file-directory-p word)
                              (append-trail-slash (namestring word))
                              (namestring word)))
                         (arg
                          ;; 環境変数から検索
                          (some #'(lambda (dir)
                                    (let ((x (merge-pathnames word dir)))
                                      (when (file-exist-p x)
                                        x)))
                                (mapcar #'map-backslash-to-slash
                                        `(,@(split-string (si:getenv "PATH") #\;)
                                          ,(si:getenv "HOME")
                                          ,(si:getenv "XYZZYHOME")
                                          ))
                                ))
                         (t
                          (or (find-load-path (concat word ".l"))
                              (find-load-path word))))))
        (prog1
            path
          (and path (reverse-region from to t))
          (set-default-directory odir))))))

;; xyzzy スレ >>383
;; http://yasai.2ch.net/win/kako/979/979930156.html#383
(defun colortest ()
  "番号と色の対応確認。(前景色:背景色)"
  (interactive)
  (let ((obuffer (selected-buffer)))
    (with-output-to-temp-buffer (" *ColorTest*" t)
      (dotimes (x 16)
        (dotimes (y 16)
          (let ((beg (point)) end)
            (insert (format nil "~2D:~2D" x y))
            (set-text-attribute beg (point) 'color
                                :foreground x
                                :background y)))
        (insert "\n"))
      (goto-char (point-min)))
    (pop-to-buffer obuffer)))
(setf (symbol-function 'list-colors-display) #'colortest)

;; ミニバッファ内で単語削除
;; http://white.s151.xrea.com/wiki/index.php?memo%2Fxyzzy%2Fminibuffer#w95b8c17
;; http://xyzzy.s53.xrea.com/wiki/index.php?tips%2F%A5%DF%A5%CB%A5%D0%A5%C3%A5%D5%A5%A1%A4%C7%A4%D2%A4%C8%A4%C4%BE%E5%A4%CE%A5%C7%A5%A3%A5%EC%A5%AF%A5%C8%A5%EA%A4%D8
(defun delete-word (&optional (arg 1))
  "*kill-ring*に追加しない単語削除"
  (interactive "*p")
  (delete-region (point) (progn (forward-word arg) (point))))
(defun backward-delete-word (&optional (arg 1))
  (interactive "*p")
  (delete-word (- arg)))
(dolist (keymap (list minibuffer-local-completion-map
                      minibuffer-local-must-match-map
                      minibuffer-local-command-line-map
                      minibuffer-local-map))
  (define-key keymap #\C-w 'backward-delete-word))

;; ファイル名のないバッファでの save-buffer のエラーをマイルドに
(add-hook '*save-buffer-no-filenames-hook*
          (defun no-filenames-error ()
            (plain-error "ファイル名がありません")))

;; arglist
(defun show-arglist (symbol)
  (interactive "SArglist: ")
  (message "(~A ~{~A~^ ~})" symbol (arglist symbol)))

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
                    (builtin-function-name (f)
                      ;; #'subr-name (Emacs)
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

(defun pwd ()
  "作業中のディレクトリ."
  (if (file-visited-p)
      (directory-namestring (get-buffer-file-name))
      (default-directory)))

(in-package "editor")
(defun message! (fmt &rest args)
  "メッセージを表示するついでに音も鳴らします."
  (ding)
  (apply #'message fmt args))
(export 'message!)
(in-package "user")

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
        ((running-process-exist-p) (error "サブプロセスが走ってるで")))
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
                                  ("XYZZYCONFIGPATH" . ,(user-config-path)))
                       :no-std-handles t
                       :exec-directory (si:system-root)
                       :show t
                       :wait nil)
         (kill-xyzzy))))

;; @@describeシリーズ

(defun symbol-describe (symbol)
  `((:name     ,(symbol-name symbol))
    (:package  ,(symbol-package symbol))
    (:value    ,(and (boundp symbol) (symbol-value symbol)))
    (:function ,(and (fboundp symbol) (symbol-function symbol)))
    (:plist    ,(symbol-plist symbol))))
;; (symbol-describe 'lisp::*terminal-io*)

(defun process-describe (process)
  `((:command   ,(process-command process))
    (:buffer    ,(process-buffer process))
    (:eol-code  ,(process-eol-code process))
    (:exit-code ,(process-exit-code process))
    (:filter    ,(process-filter process))
    (:sentinel  ,(process-sentinel process))
    (:incode    ,(process-incode process))
    (:outcode   ,(process-outcode process))
    (:maker     ,(process-marker process))))

(defun hash-describe (hash-table)
  `((:size        ,(hash-table-size hash-table))
    (:rehash-size ,(hash-table-rehash-size hash-table))
    (:test        ,(hash-table-test hash-table))
    (:count       ,(hash-table-count hash-table))
    (:item        ,(make-list-from-keyword-table hash-table))))

(defun package-describe (package)
  `((:name              ,(package-name package))
    (:nicknames         ,(package-nicknames package))
    (:shadowing-symbols ,(package-shadowing-symbols package))
    (:use-list          ,(package-use-list package))
    (:used-by-list      ,(package-used-by-list package))))

(defun radix-list (n)
  "N進数表."
  `((:bin ,(format nil "#b~B" n))
    (:oct ,(format nil "#o~O" n))
    (:dec ,(format nil   "~D" n))
    (:hex ,(format nil "#x~X" n))))

(defun pathname-describe (pathname)
  `((:device    ,(pathname-device pathname))
    (:host      ,(pathname-host pathname))
    (:directory ,(pathname-directory pathname))
    (:name      ,(pathname-name pathname))
    (:type      ,(pathname-type pathname))
    (:version   #-xyzzy ,(pathname-version pathname)
                #+xyzzy nil)))

(defun encoding-names (encoding)
  "文字エンコーディングENCODINGの名前一覧を返す."
  `((:display-name ,(char-encoding-display-name encoding))
    (:name         ,(char-encoding-name encoding))
    (:misc         ,(cdr (assoc encoding ed:*character-set-alist*
                                :key #'symbol-value)))))

(defun refwiki-symbol->url (symbol &optional and-go)
  "SYMBOLを参照するrefwikiのURLを返す."
  (interactive "Srefwiki: " :default0 (current-word t))
  (let ((url (concat "http://xyzzy.s53.xrea.com/reference/wiki.cgi?p="
                     (symbol-name symbol))))
    (cond ((or and-go (interactive-p))
           (shell-execute url t))
          (t
           (format t "~A" url)))))

(defun toggle-read-only-colorful (&optional (arg nil sv))
  "書込み禁止バッファを色付けで区別する."
  (interactive "p")
  (toggle-read-only)
  (if buffer-read-only
      (set-buffer-colors #(0 #xcccccc))
      (set-buffer-colors nil)))
;; (global-set-key '(#\C-x #\C-q) 'toggle-read-only-colorful)

(defun get-window-end-line (&optional window)
  "ウィンドウの後尾行"
  (save-window-excursion
    (set-window window)
    (if (pos-visible-in-window-p (point-max))
        (buffer-lines)
      (+ (window-lines) (get-window-start-line)))))

;; 普段見えないバッファだって参照したいときもある
(defun switch-to-invisible-buffer (buffer)
  (interactive
      (list (completing-read
             "Switch to buffer: "
             (mapcar #'buffer-name
                     (remove-if-not #'(lambda (buf)
                                        (find #\SPC (buffer-name buf) :end 1))
                                    (buffer-list)))
             :must-match t :case-fold t)))
  (switch-to-buffer buffer))

(defun point-of (fn &rest args)
  "関数FNを呼び出した後のポイント位置を返す."
  (save-excursion (apply fn args) (point)))
;; (point-of #'goto-eol)

(defun map-internal-to-binary (input-string-or-stream &optional output-stream)
  (convert-encoding-to-internal *encoding-binary*
                                input-string-or-stream
                                output-stream))
(setf (symbol-function 'binary-string) #'map-internal-to-binary)

(defun refresh-xyzzy ()
  (refresh-screen)
  (refresh-title-bar)
  (refresh-tool-bars)
  (do-events))

(setf (symbol-function 'hash->list) #'make-list-from-keyword-table)

(defun map-backslash-to-slash-region (from to)
  (interactive "*r")
  (save-restriction
    (goto-char (min from to))
    (narrow-to-region from to)
    (query-replace "\\" "/" 'noerror)))

(defun map-slash-to-backslash-region (from to)
  (interactive "*r")
  (save-restriction
    (goto-char (min from to))
    (narrow-to-region from to)
    (query-replace "/" "\\" 'noerror)))

;; $EMACS/lisp/simple.el
(defun emacs-delete-blank-lines ()
  "On blank line, delete all surrounding blank lines, leaving just one.
On isolated blank line, delete that one.
On nonblank line, delete any immediately following blank lines."
  (interactive "*")
  (let* ((thisblank (save-excursion
                      (beginning-of-line)
                      (looking-at "[ \t]*$")))
         ;; Set singleblank if there is just one blank line here.
         (singleblank (and thisblank
                           (not (looking-at "[ \t]*\n[ \t]*$"))
                           (or (bobp)
                               (progn
                                 (forward-line -1)
                                 (not (looking-at "[ \t]*$")))))))
    (when thisblank
      (beginning-of-line)
      (if singleblank (forward-line 1))
      (delete-region (point)
                     (if (re-search-backward "[^ \t\n]" 'noerror)
                         (progn (forward-line 1) (point))
                         (point-min))))
    ;; Delete following blank lines, unless the current line is blank
    ;; and there are no following blank lines.
    (unless (and thisblank singleblank)
      (save-excursion
        (end-of-line)
        (forward-line 1)
        (delete-region (point)
                       (if (re-search-forward "[^ \t\n]" 'noerror)
                           (progn (beginning-of-line) (point))
                           (point-max)))))
    ;; Handle the special case where point is followed by newline and eob.
    ;; Delete the line, leaving point at eob.
    (if (looking-at "^[ \t]*\n\\'")
        (delete-region (point) (point-max)))))
(global-set-key '(#\C-x #\C-o) 'emacs-delete-blank-lines)

(defun indent-line-sexp ()
  "長い一行S式をそれなりにインデントします."
  (interactive)
  (labels ((putnl (from to)
             (save-excursion
               (replace-string from to t))))
    ;; (while (up-list -1 'noerror))
    (save-excursion
      (save-restriction
        (narrow-to-region (point)
                          (save-excursion
                            (forward-sexp)
                            (point)))
        (putnl ") " ")\n")
        ;; (putnl "(progn ")
        ;; (putnl "(let nil ")
        (putnl "(block nil " "(block nil \n")
        (clear-undo-boundary)))
    (indent-sexp)))

(defun xyzzy-macroexpand-1 (&optional repeatedly)
  (interactive "P")
  (let* ((form (or (save-excursion
                     (read-from-string
                      (buffer-substring (progn
                                          (unless (syntax-open-p (following-char))
                                            (up-list -1 'noerror))
                                          (point))
                                        (progn
                                          (forward-sexp)
                                          (point)))
                      nil nil))
                   (error "展開するべきフォームが見つかりません")))
         (*print-circle* t)
         (expand (handler-case
                     (funcall (if repeatedly
                                  #'macroexpand
                                  #'macroexpand-1)
                              form)
                   (error (c)
                     (error "~A" (si:*condition-string c))))))
    (with-output-to-temp-buffer (" *XYZZY macroexpansion*")
      (format t "~S~%" expand)
      (lisp-interaction-mode)
      (indent-line-sexp))))
(global-set-key '(#\C-c #\C-m) 'xyzzy-macroexpand-1) ; C-c RET

;; (name-encoding "Shift_JIS") => #.(make-sjis-encoding "sjis" "日本語(Shift_JIS)") ; t
(defun name-encoding (name)
  "NAMEに対応する文字コードオブジェクトを返します."
  (gethash name *mime-charset-name-hash-table*))

;; ヘルプをもう少し便利に
(require "emacs-help")
(require "info-modoki-mode")
(require "info")
(define-key help-map #\A 'imm-apropos)
(define-key help-map #\a 'imm-command-apropos)
(define-key help-map #\b 'imm-describe-bindings)
(define-key help-map #\i 'info)
(define-key help-map #\k 'imm-describe-key)

;; メニューから文字コード指定して #'revert-buffer
;; ファイルに関連付けられていないバッファだとエラーになるのは仕様
;; xyzzy Part7 >>804
(defun add-menu-revert ()
  (let ((file-menu (get-menu *app-menu* 'ed::file)))
    (insert-popup-menu file-menu 8
                       (make-char-encoding-popup-menu
                        #'revert-buffer
                        #'(lambda (e) (and (eq (buffer-fileio-encoding) e) :check)))
                       "開き直す(&?)")
    (insert-menu-separator file-menu 8)))
(add-hook '*init-app-menus-hook* 'add-menu-revert)

;; *scratch* を xyzzy 終了時に保存
(defun save-scratch-buffer ()
  (save-excursion
    (set-buffer (get-buffer-create "*scratch*"))
    (unless (zerop (buffer-size))
      (write-file (merge-pathnames ".scratch.l" (si:system-root)) 'nomsg))))
(add-hook '*kill-xyzzy-hook* 'save-scratch-buffer)

(defun toggle-scratch-buffer (&optional popup)
  (interactive "P")
  (labels ((window-buffer-list ()
             (mapcar #'second (third (current-window-configuration)))))
    (let ((new-buffer-p (not (find-buffer #1="*scratch*")))
          (scratch (get-buffer-create #1#)))
      (if (or popup (find scratch (window-buffer-list)))
          (pop-to-buffer scratch t)
        (set-buffer scratch))
      (when (or (not (eq buffer-mode #2=*initial-buffer-mode*))
                new-buffer-p)
        (funcall #2#))))
  t)
(global-set-key '(#\C-x #\t #\s) 'toggle-scratch-buffer)

(require "cygwin")
(setq ed::*cygwin-environment-alist* '(("LANG" . "ja_JP.SJIS")))
;; (setq ed::*cygwin-environment-alist* '(("LANG" . "C")))
;(global-set-key '(#\C-x #\r #\c) 'run-cygwin-console)
(pushnew "/usr/local/share/man" *manpath* :test #'equal)

(defun tail-f-console (filename)
  (interactive "ftail-f: " :title0 "tail-f")
  (launch-application (format nil "\"~A\" ~A"
                              (merge-pathnames "tail-f.exe" (etc-path))
                              filename)))

;; http://calypso.tux.org/pipermail/xemacs-beta/2009-January/015729.html
(defun check-parens ()
  "バッファの括弧の釣り合いを調べる."
  (interactive)
  (handler-case
      (let ((home (point)))
        (goto-char (point-min))
        (while (forward-list))
        (goto-char home)
        (message "だいたいあってる")
        t)
    (simple-error (c)
      (message! "このへん間違ってるかも")
      nil)))
;; (compile 'check-parens)

(defun _just-one-space ()
  (interactive "*")
  ;; 改行もまとめて削除する
  (delete-region (progn (skip-chars-backward " \t\n") (point))
		 (progn (skip-chars-forward " \t\n") (point)))
  (insert #\SPC))
(setf (symbol-function 'just-one-space) #'_just-one-space)

;; $EMACS/lisp-mode.el
(defun xyzzy-lisp-byte-compile-and-load (&optional force-compile)
  "Byte-compile the current file (if it has changed), then load compiled code."
  (interactive "P")
  (or (file-visited-p)
      (error "The buffer must be saved in a file first"))
  ;; Recompile if file or buffer has changed since last compilation.
  (if (and (buffer-modified-p)
           (y-or-n-p "Save buffer ~A first? " (get-buffer-file-name)))
      (save-buffer))
  (let* ((buffer-file-name (get-buffer-file-name))
         (compiled-file-name (compile-file-pathname buffer-file-name)))
    (if (and (file-newer-than-file-p compiled-file-name buffer-file-name)
             (not force-compile))
	(load-file compiled-file-name)
      (and (byte-compile-file buffer-file-name)
           (load compiled-file-name)))))

(define-key ed::*lisp-mode-map* '(#\C-c #\C-k) 'xyzzy-lisp-byte-compile-and-load)
(define-key ed::*lisp-interaction-mode-map* '(#\C-c #\C-k) 'xyzzy-lisp-byte-compile-and-load)

;;; util.l ends here
