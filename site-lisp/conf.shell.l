;;; conf.shell.l

(require "shell")

;; shell‚Å“ü—Í•âŠ®
;; http://www7a.biglobe.ne.jp/~hat/download.cgi?xyzzy/shell3.l
(require "shell3")

(define-key *shell-mode-map* #\C-p 'previous-virtual-line)
(define-key *shell-mode-map* #\M-p 'ed::shell-history-previous)
(define-key *shell-mode-map* #\C-n 'next-virtual-line)
(define-key *shell-mode-map* #\M-n 'ed::shell-history-next)
(define-key *shell-mode-map* #\C-w 'backward-kill-word)
(define-key *shell-mode-map* #\Up 'previous-virtual-line)
(define-key *shell-mode-map* #\Down 'next-virtual-line)
(define-key *shell-mode-map* #\C-r
            (cond ((modulep 'igsearch) (intern "igsearch-backward" "editor"))
                  ((modulep 'isearch) (intern "isearch-backward" "editor"))
                  (:else 'search-backward)))

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

(define-key *shell-mode-map* '(#\C-c #\C-p) 'shell-previous-prompt)
(define-key *shell-mode-map* '(#\C-c #\C-n) 'shell-next-prompt)

(defun shell-other-window ()
  (interactive)
  (let ((shell-buffer
         (save-window-excursion (shell) (selected-buffer))))
    (or (eq shell-buffer (selected-buffer))
        (switch-to-buffer-other-window shell-buffer))))

(global-set-key '(#\C-c #\s) 'shell-other-window)
