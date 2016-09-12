;;; conf/tags.l

;; タグジャンプ
(defvar *xyzzy-source-directories*
  (list (cons "lisp"  "~/lisp")
        (cons "site-lisp" "~/site-lisp")
        (cons "src" "~/src/src")))

(defun jump-xyzzy-tag ()
  (interactive)
  (dolist (dir (cons (default-directory) *load-path*))
    (with-set-directory dir
      (jump-tag t))))

(defun direct-xyzzy-tag-jump ()
  (interactive)
  (with-set-directory (merge-pathnames "lisp" (si:system-root))
    (direct-tag-jump)))

(define-key esc-map #\. 'jump-xyzzy-tag)
(define-key esc-map #\, 'back-tag-jump)

(if (boundp 'help-map)
    ;; F1 j
    (define-key help-map #\j 'direct-xyzzy-tag-jump)
  (global-set-key '(#\C-x #\j) 'direct-xyzzy-tag-jump))

(defun tags-jump (dir)
  (interactive "DTags directory: ")
  (with-set-directory dir
    (direct-tag-jump)))

;; ctag
(require "ctags")
(setq *ctags-command-path* (merge-pathnames "bin/ctags.exe" (si:system-root)))
;; (global-set-key #\M-. 'ctags-jump-tag)
;; (global-set-key #\M-\, 'ctags-back-tag-jump)
;; (global-set-key #\M-/ 'ctags-make-tags-file-recursive)
;; (global-set-key #\M-? 'ctags-select-stack)
