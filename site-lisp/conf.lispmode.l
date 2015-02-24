;;; conf.lispmode.l

(setq-default *lisp-indent-tabs-mode* nil)

;; 関数のシグネチャを表示
(require "funsig")
;; (setq *funsig-popup-signature* nil) ; ステータスラインに表示
(define-key ed::*lisp-mode-map* #\C-\; 'funsig-show-signature)
(define-key ed::*lisp-interaction-mode-map* #\C-\; 'funsig-show-signature)
;; (and (fboundp 'funsig-get-function-argument)
;;      (setf (symbol-function 'funsig-get-function-argument) #'arglist-1))

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

