;;; conf.completion.l

(defun do-completion-dwim ()
  "キーワードファイルを元に補完する."
  (interactive)
  (unless keyword-hash-table
    (error "キーワードがありません"))
  (if (member buffer-mode '(lisp-mode lisp-interaction-mode))
      (lisp-complete-symbol)
      (do-completion (save-excursion (skip-syntax-spec-backward "w_") (point))
                     (point)
                     :list-ignore-case
                     (make-list-from-keyword-table keyword-hash-table))))

(global-set-key '(#\C-c #\C-i) 'do-completion-dwim)
;; (global-set-key #\M-TAB 'do-completion-dwim)
