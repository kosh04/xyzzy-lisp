;;; conf.buffer.l

(global-set-key '(#\C-x #\C-b) 'select-buffer)
;;(global-set-key '(#\C-x #\C-b) 'buffer-menu)

;; emacs ���̃o�b�t�@���w��
(pushnew '(#\B . emacs-interactive-buffer-name) *interactive-specifier-alist* :test #'equal)
(pushnew '(#\b . emacs-interactive-exist-buffer-name) *interactive-specifier-alist* :test #'equal)