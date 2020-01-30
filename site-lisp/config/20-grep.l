;;; config/grep

(require "grep")
(require "grepd")

(setf (symbol-function 'grep-find) #'grep-dialog)
(setq *grep-highlight-match* '(:foreground 1 :underline t)) ; default '(:bold t)

;; Grep Šg’£
(require "xgrep")

(defun grep-load-path (kwd)
  (interactive "sGrep (xyzzy/lisp): " :default0 (current-word t))
  (let ((dirs (append '("~/.xyzzy")
                      (reverse *load-path*)
                      *load-pathname*)))
    (ed::xgrep1 kwd dirs "*.l" :regexp t :subdir t)))

(global-set-key '(#\C-x #\g) 'grep-load-path)
