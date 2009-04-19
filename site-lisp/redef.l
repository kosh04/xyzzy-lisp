;;; -*- Mode: Lisp; Encoding: UTF-8 -*-
;;;
;;; redef.l - xyzzy 組み込み関数群の再定義
;;;

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
#-xyzzy
(defun listen (&optional input-stream)
  ;; 未完成だから使わない方がいいと思う。こんなやり方もあるよ、ということで
  #+nil
  (let ((ch (read-char-no-hang input-stream nil nil)))
    (prog1
        (and ch t)
      (and ch (unread-char ch input-stream))))
  #+nil
  (eq (peek-char nil input-stream nil :eof) :eof))

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
#|
(defun emacs-interactive-exist-buffer-name (prompt default &rest rest)
  (ed::emacs-read-buffer-name prompt (or default (selected-buffer))
                              #'(lambda (prompt &key default history)
                                  (completing-read prompt
                                                   (visible-buffer-list)
                                                   :case-fold t
                                                   ;; :must-match t ; exist
                                                   :default default
                                                   :history history))))
|#

;;; session.l
(defun toggle-session-auto-save (&optional (arg nil sv))
  (interactive "p")
  (toggle-mode '*auto-save-session-file* arg sv)
  ;; 表示があると分かりやすい
  (message "Session auto save: ~:[OFF~;ON~]" ed::*auto-save-session-file*))

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
  (message "Trace on error: ~:[OFF~;ON~]" si:*trace-on-error*)
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
(defun filer-shell-execute ()
  (let ((file (filer-get-current-file)))
    (when (or (null *filer-query-before-process*)
              (yes-or-no-p "~A~%を実行しますか?" file))
      (filer-forward-line 1)
      (shell-execute file (filer-get-directory))
      (filer-cancel))))         ; ついでに quit

;; ファイルのマークをバッファのリージョンのように扱ってみる
(defun filer-close-modal ()
  (cond ((filer-get-mark-files) (filer-clear-all-marks))
        ((filer-modal-p) (filer-cancel))
        (t (quit))))

#|
(defun open-filer ()
  (interactive)
  (multiple-value-bind (files result)
      (let ((omode (get-ime-mode))
            ;; ここで変数決めると外側の束縛が無意味になってしまうのでやめる
            (*filer-primary-directory*
             (if (file-visited-p)
                 (directory-namestring (get-buffer-file-name))
                 (default-directory))))
        (unwind-protect
            (filer nil t nil t (not *filer-modal*))
          (and *filer-modal* (toggle-ime omode))))
    (when result
      (filer-readin-1 files))))
|#

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

(defun filer-delete ()
  (long-operation
    (let ((marks (or (filer-get-mark-files)
                     ;; マークがなければ、カーソル位置のファイルを削除対象にする
                     (list (filer-get-current-file)))))
      (when (and marks
                 (if *filer-query-delete-precisely*
                     (filer-query-delete marks)
                     (yes-or-no-p "~A" (concat "選択されたファイルを削除しまっせ"
                                               (and *filer-delete-mask*
                                                    (filer-delete-mask-string *filer-delete-mask*
                                                                              "\n削除マスク: "))))))
        (filer-subscribe-to-reload (filer-get-directory) t)
        (let ((if-access-denied (if *filer-delete-read-only-files*
                                    :force :error))
              (delete-non-empty-directory
               *filer-delete-non-empty-directory*))
          (declare (special if-access-denied
                            delete-non-empty-directory))
          (filer-do-delete marks))
        (message "done.")))))

;;; mouse.l
(defun default-drag-and-drop-hook (window files)
  (set-window window)
  (cond ((minibuffer-window-p window)
         (selection-start-end (start end)
           (delete-region start end))
         (insert (format nil "~{~A~^ ~}" files)))
        ;; ディレクトリをD&Dしたらファイラを開く
        ;; ファイルの扱い方が適当すぎるな...
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
         (unless (zerop (buffer-size))
           (write-file (merge-pathnames "scratch.l" (si:system-root))))
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
                           (message "~{~S~^ ; ~}" result) ; 多値は一行表示で
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


(in-package "lisp")

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

;; 組み込みのpathname-directoryがだめだめだった気がするので
(defun pathname-directory (pathname)
  (let ((dir (ed::split-string (directory-namestring pathname) "/")))
    (if (find #\: (car dir))    ; remove drive-letter
        (cdr dir)
        dir)))


;;; redef.l ends here
