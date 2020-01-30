;;; config/buffer

;;(global-set-key '(#\C-x #\C-b) 'select-buffer)
;;(global-set-key '(#\C-x #\C-b) 'buffer-menu)

;; emacs 風のバッファ名指定
(pushnew '(#\B . emacs-interactive-buffer-name) *interactive-specifier-alist* :test #'equal)
(pushnew '(#\b . emacs-interactive-exist-buffer-name) *interactive-specifier-alist* :test #'equal)

;; ウィンドウ構成の save/restore をもうちょっとなんとかしたい
(defun buffer-menu*  (&optional gui)
  "バッファ一覧を表示します."
  (interactive "p")
  (save-window-configuration-to-register 'buffer-menu-before)
  (call-interactively (if gui #'select-buffer #'buffer-menu)))

(global-set-key '(#\C-x #\C-b) 'buffer-menu*)

(let ((map ed::*buffer-menu-mode-map*))
  (define-key map #\n 'next-line)
  (define-key map #\p 'previous-line)
  (define-key map #\RET 'buffer-menu-this-window)
  (define-key map #\q
              (lambda ()
                (interactive)
                (bury-buffer (selected-buffer))
                (restore-window-configuration-register 'buffer-menu-before)))
  )
