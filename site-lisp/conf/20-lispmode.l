;;; conf.lispmode.l

(setq-default *lisp-indent-tabs-mode* nil)

;; 関数のシグネチャを表示
(require "funsig")
;; (setq *funsig-popup-signature* nil) ; ステータスラインに表示
(define-key ed::*lisp-mode-map* #\C-\; 'funsig-show-signature)
(define-key ed::*lisp-interaction-mode-map* #\C-\; 'funsig-show-signature)
;; (and (fboundp 'funsig-get-function-argument)
;;      (setf (symbol-function 'funsig-get-function-argument) #'arglist-1))

(require "ldoc-popup")

;; eldoc (Emacs) の手抜き (M-x: turn-on-ldoc)
;; http://kitaj.no-ip.com/xyzzy/index.html
(require "ldoc")
;(push 'fundamental-mode *ldoc-activated-mode-list*) ; *Help*用
(defun toggle-ldoc-with-message ()
  (interactive)
  (toggle-ldoc)
  (message "Toggle ldoc: ~:[OFF~;ON~]" ed::*ldoc-status*))
(global-set-key '(#\C-x #\t #\l) 'toggle-ldoc-with-message)

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
        (putnl "(progn " "(progn\n")
        ;; (putnl "(let nil ")
        (putnl "(block nil " "(block nil \n")
        (clear-undo-boundary)))
    (indent-sexp)))

(defun xyzzy-macroexpand-1 (&optional repeatedly)
  (interactive "P")
  (let* ((*package* (find-package *buffer-package*))
         (form (or (read-from-string
                    (save-excursion
                      (buffer-substring (progn
                                          (unless (syntax-open-p (following-char))
                                            (up-list -1 'noerror))
                                          (point))
                                        (progn
                                          (forward-sexp)
                                          (point))))
                    nil nil)
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

(define-key ed::*lisp-mode-map* '(#\C-c #\C-m) 'xyzzy-macroexpand-1) ; C-c RET
(define-key ed::*lisp-interaction-mode-map* '(#\C-c #\C-m) 'xyzzy-macroexpand-1)


;; *scratch* バッファを保存する
(defun save-scratch-buffer ()
  (save-excursion
    (set-buffer (get-buffer-create "*scratch*"))
    (write-file (merge-pathnames "scratch.l" (si:getenv "TEMP")))))

(defun save-scratch-buffer-maybe ()
  (when (and (null *kill-buffer-kills-scratch*)
             (equal (buffer-name (selected-buffer)) "*scratch*")
             (eq buffer-mode 'lisp-interaction-mode)
             (not (zerop (buffer-size))))
    (save-scratch-buffer))
  ;; always returns `t'
  t)

(add-hook '*kill-xyzzy-hook* 'save-scratch-buffer)
(add-hook '*query-kill-buffer-hook* 'save-scratch-buffer-maybe)

(defun toggle-scratch-buffer (&optional other-window)
  (interactive "P")
  (labels ((window-list ()
             (mapcar #'second (third (current-window-configuration)))))
    (let ((scratch (get-buffer-create "*scratch*")))
      (if (or other-window (find scratch (window-list)))
          (pop-to-buffer scratch t)
        (switch-to-buffer scratch))
      (or (eq buffer-mode *initial-buffer-mode*)
          (funcall *initial-buffer-mode*))))
  t)

(global-set-key '(#\C-x #\t #\s) 'toggle-scratch-buffer)

;; 書込み禁止バッファでも移動できるように(Emacs互換)
(defun elisp-indent-line ()
  (interactive)
  (or (and buffer-read-only
           (save-excursion (skip-chars-backward " \t") (bolp))
           (skip-chars-forward " \t"))
      (lisp-indent-line)))

(define-key ed::*lisp-mode-map* #\Tab 'elisp-indent-line)
(define-key ed::*lisp-interaction-mode-map* #\Tab 'elisp-indent-line)

;; 再ロードするには以下の要素が必要.
;; - ファイルが一度ロードされている
;; - (provide "***")
(defun recompile-and-load-file ()
  "*.lc があれば再コンパイルとロード."
  (let* ((file (get-buffer-file-name))
         (lc (compile-file-pathname file))
         (encoding (buffer-fileio-encoding)))
    (when (and file
               (member buffer-mode '(lisp-mode lisp-interaction-mode))
               (file-exist-p lc)
               ;; 括弧が足りないとコンパイル時に怒られるので
               (check-parens))
      (if (eq encoding *encoding-sjis*)
          (byte-compile-file file)
          (mc-compile-file file encoding))
      (let ((provide
             ;; pathname-name では"*/*"などの階層provideに対応できない
             (find-buffer-provide)))
        (and provide
             (modulep provide)
             ;; バイトコンパイルされたファイルはsjisなのでmc-*でなくてOK
             (load-file lc))))
    ))

;(defvar *after-save-buffer-hook* nil)
(add-hook '*after-save-buffer-hook* 'recompile-and-load-file)
(defun toggle-recompile ()
  (interactive)
  (let ((hook (member 'recompile-and-load-file *after-save-buffer-hook*)))
    (cond (hook
           (delete-hook '*after-save-buffer-hook* 'recompile-and-load-file))
          (t
           (add-hook '*after-save-buffer-hook* 'recompile-and-load-file)))
    (message "Recompile: ~:[OFF~;ON~]" hook)))
;; (delete-hook 'ed::*after-save-buffer-hook* 'recompile-file)

(setf (get 'string-trim 'ed:lisp-indent-hook) 1)
(setf (get 'string-right-trim 'ed:lisp-indent-hook) 1)
(setf (get 'string-left-trim 'ed:lisp-indent-hook) 1)

;; CL の基本関数を調べる
(require "hyperspec")
;(import '(hyperspec:hyperspec hyperspec:hyperspec-format))
(define-key ed::*lisp-mode-map* '(#\C-c #\h) 'hyperspec:hyperspec)
(define-key ed::*lisp-interaction-mode-map* '(#\C-c #\h) 'hyperspec:hyperspec)
(setq hyperspec::*hyperspec-root* "http://www.lispworks.com/documentation/HyperSpec/")
;(setq hyperspec::*hyperspec-root* "C:/home/lxuser/code/lisp/HyperSpec-7-0/HyperSpec/")

;; http://ohkubo.s53.xrea.com/xyzzy/scratch.html 'auto-find-file-read-only も参考
(defun read-only-if-load-path ()
  "*load-path* 内のファイルは read-only にトグルする."
  (when (in-load-path-p (directory-namestring (get-buffer-file-name)))
    (toggle-read-only t)))

(add-hook '*find-file-hooks* 'read-only-if-load-path)

(defun in-load-path-p (dir)
  "DIR が *load-path* のサブディレクトリかどうか."
  (some #'(lambda (parent)
            (sub-directory-p dir parent))
        *load-path*))
