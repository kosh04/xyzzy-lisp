;;; -*- Mode: Lisp; Package: USER; Encoding: UTF-8 -*-
;;;
;;; util.l
;;;

(provide "util")

(in-package "user")

;;; estartup.l
(defun load-xyzzyrc ()
  "$XYZZY/.xyzzy のロード"
  (trap-errors
    (let ((*loading-user-initial-file* t)) ; 何の効果が?
      (load (merge-pathnames ".xyzzy" (si:system-root))
            :if-does-not-exist nil :verbose nil :print nil))))
;; (add-hook '*post-startup-hook* 'load-xyzzyrc)

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

;;; XyzzyWikiから拾ってきたんだと思う
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

;;; 閉じたタブを元に戻す、を自分用に改変
;;; ダイアログ使いたい
;;; http://white.s151.xrea.com/wiki/index.php?memo%2Fxyzzy%2Ffile#k96261fd
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

;;; 'si:*trace-on-error* とかクオートされたシンボルの値を評価したい
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
  "テンション上がってきた."
  (interactive)
  (let ((kita-list
         '("(ﾟ∀ﾟ)" "( ﾟ∀)" "(   ﾟ)" "(    )" "(ﾟ   )" "(∀ﾟ )" "(ﾟ∀ﾟ)")
         ))
    (while (not (listen *keyboard*))
      (dolist (kao kita-list)
        (minibuffer-message "ｷﾀ━━━~A━━━!!!!" kao)
        (sit-for .1)))))

;;; $EMACS/lisp/comint.el
;;; (point) が EOF ならプロセス終了
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

;;; transient-mark-mode もどき
(defun keyboard-quit ()
  (interactive)
  (set-mark t)                  ; マークをクリア (ChangeLog Version 0.1.0.107)
  (error 'quit))
(global-set-key #\C-g 'keyboard-quit)

;; 末尾の改行も考慮するならread-lineは多値でとるべき
(defun cat (file &optional stream)
  "print FILE contents to STREAM (default *standard-input*)."
  (with-open-file (fp file :direction :input)
    (loop
      (multiple-value-bind (line missing-newline-p)
          (read-line fp nil nil)
        (when (null line) (return))
        (princ line stream)
        (unless missing-newline-p (terpri stream))))))

(defun shell-command-to-string (command)
  "Execute shell command COMMAND and return its output as a string."
  (let ((outfile (make-temp-file-name "xyzzycmd-")))
    (unwind-protect
        (with-output-to-string (stream)
          (call-process command :output outfile :show :minimize :wait t)
          (cat outfile stream))
      (and outfile (delete-file outfile)))))

(defun command-substitution (command)
  "外部コマンドの結果を文字列にして返します."
  (string-right-trim '(#\SPC #\TAB #\LFD)
    (shell-command-to-string command)))

(defun get-file-infomation (file)
  "ファイルのプロパティを表示します。"
  (interactive "fFile info: " :default0 (get-buffer-file-name))
  (multiple-value-bind (attr write-time size short-path)
      (values-list (get-file-info file))
    (message "~{~A~^ ~}"	; ls -l の書式どんなだっけ?
             (list
              (file-attribute-to-string attr)            ; 属性
              size                                       ; サイズ
              (format-date-string "%Y-%m-%d" write-time) ; 更新日時
              (file-namestring file)                     ; ファイル名
              ))))

(defun file-attribute-to-string (attr)
  "attrib /? 参照"
  (concat
   (if (zerop (logand attr ed::*file-attribute-directory*))  "-" "D") ; ディレクトリ
   (if (zerop (logand attr ed::*file-attribute-readonly*))   "-" "R") ; 読み取り専用
   (if (zerop (logand attr ed::*file-attribute-archive*))    "-" "A") ; アーカイブ
   (if (zerop (logand attr ed::*file-attribute-hidden*))     "-" "H") ; 隠しファイル
   (if (zerop (logand attr ed::*file-attribute-system*))     "-" "S") ; システム
   (if (zerop (logand attr ed::*file-attribute-compressed*)) "-" "C") ; 圧縮?
   ))

;; 毎度毎度 do-all-symbols は時間がかかるのでキャッシュで誤魔化す
(defvar *keymaplist* nil)

(defun keymaplist (&optional force-update)
  (or (and (not force-update)
           *keymaplist*)
      (do-all-symbols (sym *keymaplist*)
        (if (and (boundp sym)
                 (keymapp (eval sym)))
            (push sym *keymaplist*)))))

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
  "see `imenu.el'"
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

;;; (require "paren") とかにもそれなりに対応
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

;;; xyzzy スレ >>383
;;; http://yasai.2ch.net/win/kako/979/979930156.html#383
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

;; よく分からない
(defconstant text-color-list
  '(none red green yellow blue purple cyan white black brown olive
    ocher azure violet 浅葱色？ gray)
  "set-text-attribute などで使える色の順番.")

(defun find-library (lib)
  "*load-path* の中から適当に選んで開く."
  (interactive (list (read-exist-library "Find library: ")))
  (let ((file (find-load-path lib)))
    (when file
      (if (string-match "\\.lc$" file)
          (setq file (substring file 0 -1)))
      (find-file file)
      (add-history file '*minibuffer-file-name-history*))))

(defun read-exist-library (prompt &optional modules-only)
  (completing-read prompt
                   (if modules-only
                       *modules*
                       (mapcan #'(lambda (path)
                                   ;; "*.l" -> "*"
                                   (mapcar #'(lambda (f) (substring f 0 -2))
                                           (directory path :recursive t :wild "*.l")))
                               *load-path*))
                   :case-fold t :must-match t))

(global-set-key '(#\C-c #\f) 'find-library)

;;; ミニバッファ内で単語削除
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

;;; ファイル名のないバッファでの 'save-buffer のエラーをマイルドに
(add-hook '*save-buffer-no-filenames-hook*
          (defun no-filenames-error ()
            (plain-error "ファイル名がありません")))

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

;;; tips/ファイルの暗号化(Rijndael) より
;;; http://xyzzy.s53.xrea.com/wiki/index.php?cmd=read&page=tips%2F%A5%D5%A5%A1%A5%A4%A5%EB%A4%CE%B0%C5%B9%E6%B2%BD(Rijndael)
(defmacro with-temp-file ((temp-file) &body body)
  `(let ((,temp-file ,(make-temp-file-name)))
     (unwind-protect
         (progn ,@body)
       (delete-file ,temp-file :if-does-not-exist :error :if-access-denied :error))))
(setf (get 'with-temp-file 'ed:lisp-indent-hook) 1)
;; (with-temp-file (dest) (truename dest)) => "C:/tmp/~xyzirtx.tmp"

(defun process-list ()
  "バッファプロセスのリスト."
  (remove-if (complement #'processp)
             (mapcar #'buffer-process (buffer-list))))

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

;;; 環境変数の変更が反映されないのはしょうがないのか
;;; [注意]
;;; (kill-xyzzy)する時にyes-no-or-cancel-p/yes-or-no-pに引っかかるとイヤになる
;;; [関連するもの] バッファプロセス、保存、排他制御
;;; (need-buffer-save-p buf) (verify-buffers-file-modtime) (buffer-modified-p &optional buf)
;;; *kill-xyzzy-hook*に時間をかけるとまずいかもね -> 先に実行させておこう
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
                       :environ `(("XYZZYHOME" . ,(si:system-root))
                                  ;; 設定ファイル (xyzzy.ini等) のディレクトリ
                                  ("XYZZYCONFIGPATH" . ,(user-config-path)))
                       :no-std-handles t
                       :exec-directory (si:system-root)
                       :show t
                       :wait nil)
         (kill-xyzzy))))

;;; @@describeシリーズ

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

(defun get-window-end-line ()
  "ウィンドウの後尾行"
  (if (pos-visible-in-window-p (point-max))
      (buffer-lines)
      (+ (window-lines) (get-window-start-line))))

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
;; (point-of #'(lambda () (goto-char (point-min)))) ;=> 0

;; 対括弧入力派にはあまり必要がないけど
(defun close-all-parens-in-sexp ()
  (interactive "*")
  (while (save-excursion (backward-up-list 1 'noerror))
    (insert ")")))
;; (global-set-key '(#\C-c #\C-]) 'close-all-parens-in-sexp)

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
    (narrow-to-region from to)
    (query-replace "\\" "/" 'noerror)))

;;; $EMACS/lisp/simple.el
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
    (while (up-list -1 'noerror))
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
      (format t "~S" expand)
      (lisp-interaction-mode)
      (indent-line-sexp))))
(global-set-key '(#\C-c #\C-m) 'xyzzy-macroexpand-1) ; C-c RET

;; (name-encoding "Shift_JIS") => #.(make-sjis-encoding "sjis" "日本語(Shift_JIS)") ; t
(defun name-encoding (name)
  "NAMEに対応する文字コードオブジェクトを返します."
  (gethash name *mime-charset-name-hash-table*))

;; help
(defvar help-map (make-sparse-keymap))
(setf (symbol-function 'help-command-prefix) help-map)
(global-set-key #\F1 'help-command-prefix)
(define-key help-map '#\A 'user::imm-apropos) ; or 'apropos
(define-key help-map '#\a 'user::imm-command-apropos) ; 'command-apropos
(define-key help-map '#\b 'user::imm-describe-bindings) ; 'describe-bindings
(define-key help-map '#\c 'describe-key-briefly)
(define-key help-map '#\f 'describe-function)
(define-key help-map '#\i 'ed:info)
(define-key help-map '#\k 'user::imm-describe-key) ; 'describe-key
(define-key help-map '#\l 'view-lossage)
(define-key help-map '#\v 'describe-variable)
(define-key help-map '#\F1 'show-html-help)
(define-key help-map '#\? 'call-help-list)

(defun call-help-list ()
  (interactive)
  (command-execute-in-keymap "Help: " help-map))

(defun command-execute-in-keymap (prompt keymap)
  (if (keymapp keymap)
      (labels ((expand-keymap (map)
                 (case (type-of map)
                   (simple-vector
                    (mapcan #'expand-keymap-1 (coerce map 'list)))
                   (cons
                    (mapcan #'expand-keymap-1 (mapcar #'cdr (rest map))))))
               (expand-keymap-1 (x)
                 (cond ((null x) nil)
                       ((keymapp x) (expand-keymap x))
                       (t (list x)))))
        (let* ((fns (expand-keymap keymap))
               (sym (find-symbol
                     (completing-read prompt fns :must-match t))))
          (if (and (fboundp sym)
                   (commandp sym))
              (call-interactively sym)
              (error "関数が定義されていません: ~A" sym))))
      (error 'type-error :datum keymap :expected-type 'keymap)))

;;; util.l ends here
