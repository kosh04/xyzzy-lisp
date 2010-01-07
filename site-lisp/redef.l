;;; -*- Mode: Lisp; Encoding: Shift_JIS -*-
;;;
;;; redef.l --- xyzzy 組み込み関数を再定義したもの
;;;
;;; This file is NOT part of xyzzy.

(provide "redef")


(in-package "editor")

;; すでに定義されているものは必要ないかも
;; (export '())

(defparameter *tab-bar-never-focus* t
  "non-nil ならタブフォーカスの際にキャレットが消えにくくなる.")

;;; defs.l
(defparameter inverse-cursor-line t
  "non-nil ならカーソル行と下線の重なりが見やすくなるかもしれない.")

(defparameter show-dots nil
  "non-nil なら find-file でドットで始まるファイルも見えるようになる.")

;;; [xyzzy:07649]
(defparameter *eat-mouse-activate* t
  "non-nil なら xyzzy がアクティブになる際, クリックした場所にカーソル移動させない.")

;;; winhelp.l
(setq *html-help-path* (merge-pathnames "reference.chm" (etc-path)))

;;; builtin.l
#+NIL
(defun listen (&optional input-stream)
  #+case1
  (let ((ch (read-char-no-hang input-stream nil nil)))
    (prog1
        (and ch t)
      (and ch (unread-char ch input-stream))))
  #+case2
  (eq (peek-char nil input-stream nil :eof) :eof))

(si::defun-builtin track-popup-menu (menu &optional any))

;;; buf-menu.l
(defun buffer-menu ()
  (interactive)
  (list-buffers)
  (scan-buffer "^\\." :regexp t)) ; 選択していたバッファにカーソル

;; 大文字小文字を区別しないバッファ選択
(defun visible-buffer-list ()
  (remove-if #'(lambda (buf)
                 (find #\SPC buf :end 1))
             (mapcar #'buffer-name (buffer-list))))
(defun emacs-interactive-buffer-name (prompt default &rest rest)
  (ed::emacs-read-buffer-name prompt (or default (selected-buffer))
                              #'(lambda (prompt &key default history)
                                  (completing-read prompt
                                                   (visible-buffer-list)
                                                   :case-fold t
                                                   :default default
                                                   :history history))))
#+NIL
(defun emacs-interactive-exist-buffer-name (prompt default &rest rest)
  (ed::emacs-read-buffer-name prompt (or default (selected-buffer))
                              #'(lambda (prompt &key default history)
                                  (completing-read prompt
                                                   (visible-buffer-list)
                                                   :case-fold t
                                                   ;; :must-match t ; exist
                                                   :default default
                                                   :history history))))

;;; cmds.l
(defun toggle-mode (var arg sv)
  (set var (if sv
	       (if (integerp arg)
		   (not (minusp arg))
		 arg)
	     (null (symbol-value var))))
  (let ((msg (get var 'message-documentation)))
    (when msg
      ;; 表示があると分かりやすい
      (message "~A: ~:[OFF~;ON~]" msg (symbol-value var)))))

(setf (get 'ed::*auto-save-session-file* 'message-documentation) "Session auto save")
(setf (get 'si:*trace-on-error* 'message-documentation) "Trace on error")

;;; misc.l
(defun toggle-trace-on-error (&optional (arg nil svar))
  (interactive "p")
  (toggle-mode 'si:*trace-on-error* arg svar)
  (cond (si:*trace-on-error*
         (ed::setup-trace-output-buffer)
         (save-excursion
           (set-buffer (buffer-stream-buffer *error-output*))
           (lisp-mode)))
        (t
         (ignore-errors
          (kill-buffer (buffer-stream-buffer *error-output*)))))
  t)

;; 単に好みの問題
(defun msgbox (fmt &rest args)
  (message-box (apply #'format nil fmt args)))

;;; tags.l
(defun jump-tag (&optional other-window)
  (interactive)
  (long-operation
    (when (and tags-find-target tags-find-point)
      (let ((opoint (point)))
        (multiple-value-bind (class name functionp)
            (funcall tags-find-target)
          ;; 組み込み関数も見つけたい
          (if (string-match "lisp" (string buffer-mode))
              (setq name (car (last (split-string name ":"))))) ; remove package-name
          (multiple-value-bind (file point functionp)
              (tags-find-entry class name functionp)
            (cond (file
                   (goto-char opoint)
                   (jump-tag-1 file class name point functionp other-window))
                  ((some #'(lambda (sym)
                             (and (fboundp sym)
                                  (si:*builtin-function-p (symbol-function sym))
                                  (ding)
                                  (message "#'~S is Builtin function" sym)
                                  t))
                         (find-all-symbols name)))
                  (t            ; 見つからなかったら
                   ;; (direct-tag-jump)
                   ))
            nil))))))

;;; edict.l
(setq *edict-dictionary-path* (merge-pathnames "edict" (si:system-root)))

(defun edict-lookup-word (fn)
  (let ((x (if (alpha-char-p (following-char)) 1 -1)))
    (save-excursion
      (apply fn (list (progn
                        (forward-word x)
                        (point))
                      (progn
                        (forward-word (- x))
                        (point)))))))

;;; filer.l
#+NIL
(defun filer-shell-execute ()
  (let ((file (filer-get-current-file)))
    (when (or (null *filer-query-before-process*)
              (yes-or-no-p "~A~%を実行しますか?" file))
      (filer-forward-line 1)
      (shell-execute file (filer-get-directory))
      (filer-cancel))))         ; ついでに quit

;; ファイルのマークをバッファのリージョンのように扱ってみる
#+NIL
(defun filer-close-modal ()
  (cond ((filer-get-mark-files)
         ;; (ding)
         (filer-clear-all-marks))
        ((filer-modal-p) (filer-cancel))
        (t (quit))))

(defun filer-list-archive ()
  (let ((file (ed::filer-fetch-file t)))
    (when file
      (multiple-value-bind (result data)
          (dialog-box
           `(dialog 0 0 273 237
                    (:caption ,(concat (file-namestring file) "の中身"))
                    (:font 9 "MS UI Gothic")
                    (:control
                     (:listbox list nil #x50b10911 7 7 259 202)
                     (:button IDOK "開く" #x50010001 158 216 50 14)
                     (:button IDCANCEL "キャンセル" #x50010000 216 216 50 14)))
           (list (cons 'list
                       (long-operation
                         (mapcar #'(lambda (x)
                                     (list (cadr x)
                                           (format nil "~d" (caddr x))
                                           (apply #'format
                                                  nil "~d/~2,'0d/~2,'0d ~2,'0d:~2,'0d"
                                                  (cadddr x))
                                           (car x)))
                                 (prog2 ; 表示があった方が気が楽
                                     (message "展開中 ~A..." file)
                                     (list-archive file)
                                   (message "done"))))))
           '((list :column (6 -10 18 100) :must-match t :enable (IDOK))))
        (when result
          (with-set-buffer
            (when (filer-modal-p)
              (filer-cancel))
            (mapc #'(lambda (f)
                      (ed::filer-open-in-archive file (nth 3 f)))
                  (cdr (assoc 'list data)))))))))

(or (fboundp '%filer-get-mark-files)
    (setf (symbol-function '%filer-get-mark-files) #'filer-get-mark-files))

(defun filer-get-mark-files (&optional file-only-p secondary-window-p)
  (or #1=(%filer-get-mark-files file-only-p secondary-window-p)
      (prog2
          ;; マークがなければカーソル位置のファイルを対象にしてみる
          ;; [共通設定]->[ファイラ]->[なんかする前に必ず確認する]
          ;; のチェックを入れておかないと色々危険かも...
          (filer-mark file-only-p secondary-window-p)
          #1#
        (filer-clear-all-marks secondary-window-p))))

(defun filer-rename ()
  (let ((old (filer-get-mark-files))
	(goto-new nil)
	files)
    (cond (old
	   (when (endp (cdr old))
	     (setq old (car old))))
	  (t
	   (when (filer-current-file-dot-dot-p)
	     (return-from filer-rename nil))
	   (setq old (filer-get-current-file))
	   (setq goto-new t)))
    (cond ((listp old)
	   (setq files (ed::filer-get-rename-pattern old))
	   (unless files
	     (return-from filer-rename nil)))
	  (t
	   (let ((new (ed::filer-get-rename-file (file-namestring (namestring old)))))
	     (unless new
	       (return-from filer-rename nil))
	     (setq files (acons old (merge-pathnames new (filer-get-directory)) nil)))))
    (filer-subscribe-to-reload (filer-get-directory))
    (mapc #'(lambda (x)
              (let ((old (car x))
                    (new (cdr x)))
                (message "~A から ~A へリネーム..." old new)
                (do-events)
                (rename-file old new)
                ;; ファイルに関連付けられているバッファもリネーム
                (let ((oldbuf (get-file-buffer old)))
                  (when (and oldbuf (not (file-directory-p new)))
		    (set-buffer-file-name new oldbuf)
		     (rename-buffer (file-namestring new) oldbuf)))
                (filer-subscribe-to-reload (directory-namestring new))))
	  files)
    (when goto-new
      (filer-demand-reload)
      (filer-goto-file (file-namestring (cdar files))))
    (message "done.")
    t))

;;; mouse.l
(defun default-drag-and-drop-hook (window files)
  (set-window window)
  (cond ((minibuffer-window-p window)
         (selection-start-end (start end)
           (delete-region start end))
         (insert (format nil "~{~A~^ ~}" files)))
        ;; ディレクトリをD&Dしたらファイラを開く
        ;; ファイルの扱い方が適当すぎる
        ((file-directory-p (car files))
         (let ((*filer-primary-directory* (car files)))
           (open-filer)))
        (t
         (find-file files)
         (mapc #'(lambda (f)
                   (setq f (namestring f))
                   (if (file-exist-p f)
                       (setq f (truename f)))
                   (add-history f '*minibuffer-file-name-history*))
               files))))
(setq *drag-and-drop-hook* #'default-drag-and-drop-hook)

;;; window.l
(defun toggle-tab (&optional (arg nil sv))
  (interactive "p")
  (toggle-window-flag *window-flag-tab* arg sv)
  (message "Toggle tab: ~:[OFF~;ON~]" ;+
           (not (zerop (logand (get-window-flags) *window-flag-tab*)))))

;;; help.l
;; apropos ですべてのパッケージを検索する (s/do-symbols/do-all-symbols)
;; コンパイルしないと遅いよ
(defun apropos-find-matches (pattern pred)
  (let ((regexp (compile-regexp pattern))
        (result nil))
    (cond ((and regexp pred)
           (do-all-symbols (sym)
             (and (funcall pred sym)
                  (string-match regexp (symbol-name sym))
                  (push sym result))))
          (pred
           (do-all-symbols (sym)
             (and (funcall pred sym)
                  (push sym result))))
          (regexp
           (do-all-symbols (sym)
             (and (string-match regexp (symbol-name sym))
                  (push sym result))))
          (t
           (do-all-symbols (sym)
             (push sym result))))
    result))

(defun apropos (string &optional print-key pred)
  "指定した正規表現に一致するシンボルを表示します"
  (interactive "sApropos(Regexp): \np")
  (if *apropos-no-regexp*
      (setq string (regexp-quote string)))
  (long-operation
    (let ((matches (apropos-find-matches string pred)))
      ;; 見つからなければバッファいらない
      (unless matches
        (error "no apropos matches for ~S" string))
      (with-output-to-temp-buffer ("*Help*")
        (message "Building apropos list...")
        (let ((local-keymap (local-keymap))
              (doc-path (lisp::documentation-path)))
          (dolist (sym (sort matches #'string<))
            (prin1 sym)
            (when (and print-key (commandp sym))
              (let ((keys (command-keys sym *global-keymap* local-keymap)))
                (when keys
                  (format t "~40T")
                  (print-key-sequence keys))))
            (terpri)
            (let ((doc (si:get-documentation-string
                        sym 'lisp::function-documentation t doc-path)))
              (when doc
                (format t "  Function: ~A~%" doc)))
            (let ((doc (si:get-documentation-string
                        sym 'lisp::variable-documentation t doc-path)))
              (when doc
                (format t "  Variable: ~A~%" doc)))))
        ;; もうちょっと見易く
        (toggle-read-only t)
        (lisp-mode)
        (message "Building apropos list...done")))))

;;; kbdmacro.l
(defvar *kbd-macro-repeat-char* #\e)
(defvar *kbd-macro-undo-boundary* t
  "non-nilならばキーボードマクロの実行毎にアンドゥが効くようになります.")

(defun call-last-kbd-macro (&optional (arg 1))
  (interactive "p")
  (when *executing-macro*
    (error "キーボードマクロはすでに実行中です"))
  (when (kbd-macro-saving-p)
    (error "キーボードマクロの定義中です"))
  (unless *last-kbd-macro*
    (error "キーボードマクロは未定義です"))
  (let ((*executing-macro* t)
        (*prefix-value* arg))
    ;; Emacs のようにタイプひとつで連続実行
    (tagbody
      #1=#:continue
      (when (command-execute *last-kbd-macro*)
        (if *kbd-macro-undo-boundary* (undo-boundary))
        ;; (refresh-screen)
        (minibuffer-message "Press ~C repeat keyboard macro."
                            *kbd-macro-repeat-char*)
        (let ((ch (read-char)))
          ;; ループ内で判定しなくていい気はする
          ;; S式を変数に閉じ込めてfuncall?
          (if (char= ch *kbd-macro-repeat-char*)
              (go #1#)
              (unread-char ch)))))))

;;; fill.l
;; Emacsのように引数を明示的に指定させる
(defun set-fill-column (&optional col)
  (interactive "p")
  (unless (integerp col)
    (error "set-fill-column requires an explicit argument (current ~D)"
           fill-column))
  (unless (<= 4 col 30000)
    (error "フィルカラムは4以上30000以下です"))
  (message "フィルカラムは~dです(以前:~d)" col fill-column)
  (setq fill-column col))

;;; lispmode.l
(defun kill-scratch-hook ()
  (cond (*kill-buffer-kills-scratch*
         t)
        ((and (eq buffer-mode 'lisp-interaction-mode)
              (equal (buffer-name (selected-buffer)) "*scratch*"))
         ;; 消す前に保存する
         (unless (zerop (buffer-size))
           (write-file (merge-pathnames ".scratch.l" (si:system-root))))
         (erase-buffer (selected-buffer))
         nil)
        (t t)))

(defun eval-region (from to &optional stream)
  (interactive "r")
  (let ((result nil))
    (when (> from to)
      (rotatef from to))
    (let ((s (make-buffer-stream (selected-buffer) from to)))
      (handler-case
          (let ((*package* *package*))
            (while (< (buffer-stream-point s) to)
              (let ((form (read s nil '#1=#:eof)))
                (when (eq form '#1#)
                  (return))
                (setq result (multiple-value-list (eval form))))))
        ((or error reader-error quit) (c)
         (when (<= (buffer-stream-point s) to)
           (goto-char (buffer-stream-point s))
           (when stream
             (eval-region-print stream
                                (format t "~A~%" c)))
           (let ((si:*trace-on-error* nil))
             (error c))))))
    (eval-region-print stream
                       (if (null stream)
                           (message "~{~S~^ ; ~}" result) ; 多値なら一行表示
                           (format t "~{~S~%~}" result)))
    (values-list result)))

;;; files.l
(defun emacs-write-file (filename)
  (interactive "FWrite file: "
    :title0 "Write File" :default0 *default-write-file-directory*)
  (and (rename filename)
       (save-buffer)
       ;; モード切替
       (funcall (or (some #'(lambda (x)
                              (and (string-match (car x) filename)
                                   (cdr x)))
                          *auto-mode-alist*)
                    *default-buffer-mode*))))

;;; tail-f.l

;; tail-f.lはautoloadで読み込まれるので上書きする必要あり
(require "tail-f")

;; 文字コード指定の追加
(defun tail-f (filename &optional encoding)
  (interactive "ftail-f: \n0zEncoding: " :title0 "tail-f")
  (setq encoding (or encoding *default-process-encoding*))
  (let* ((buffer (tail-f-internal filename))
         (process (buffer-process buffer)))
    (set-process-incode process encoding)
    (set-process-outcode process encoding)
    (set-buffer-fileio-encoding encoding buffer)
    (set-buffer buffer)))

(defun tail-f-internal (filename)
  (setq filename (namestring filename))
  (let ((buffer (tail-f-find-buffer filename)))
    (unless buffer
      (save-excursion
        (setq buffer (create-new-buffer "*tail-f*"))
        (set-buffer buffer)
        (tail-f-mode filename))
      (make-process (format nil "\"~a\" \"~a\""
                            (merge-pathnames "tail-f.exe" (etc-path))
                            filename)
                    :output buffer
                    :exec-directory (default-directory buffer))
      ;; 更新されたらウィンドウも移動してほしい
      ;; プロセスマーカー考慮してないかも
      (set-process-filter (buffer-process buffer)
                          #'(lambda (proc str)
                              (display-buffer #1=(process-buffer proc))
                              (when #2=(get-buffer-window #1#)
                                (with-selected-window
                                  ;; (set-buffer #1#)
                                  (set-window #2#)
                                  (goto-char (point-max))
                                  (insert str)
                                  (recenter -1)))
                              (refresh-screen))))
    buffer))


(in-package "lisp")

(defun load-library (filename &rest rest)
  (ed:interactive (list (ed:completing-read
                         "Load library: "
                         (mapcan #'(lambda (path)
                                     (directory path
                                                :wild "*.l"
                                                :recursive t))
                                 *load-path*))))
  ;; バイトコンパイルされたものを優先してロード
  (if (file-exist-p #1=(compile-file-pathname filename))
      (load #1#)
    (apply #'si:*load-library filename rest)))

;;; package.l
;; 引数NAMEはstring designator
(defmacro in-package (name)
  `(eval-when (:compile-toplevel :load-toplevel :execute)
     (in-package-1 ',(string name))))

;;; list.l
;; ほかにもいくつか返値が逆だったのがあったはず
(defun intersection (list1 list2 &rest rest &key test test-not key)
  (let ((x '()))
    (dolist (l list1 (nreverse x))
      (when (apply #'member (if key (funcall key l) l) list2 rest)
        (push l x)))))

(defun set-difference (list1 list2 &rest rest &key test test-not key)
  (let ((x '()))
    (dolist (l list1 (nreverse x))
      (unless (apply #'member (if key (funcall key l) l) list2 rest)
        (push l x)))))

;; 組み込みのpathname-directoryがだめだめだった気がする
;; (pathname-directory "C:/home/") => nil
#+NIL
(defun pathname-directory (pathname)
  (let ((dir (ed::split-string (if (file-directory-p pathname)
                                   pathname
                                   (directory-namestring pathname))
                               "/")))
    (if (find #\: (car dir))    ; remove drive-letter
        (cdr dir)
        dir)))

;;; redef.l ends here
