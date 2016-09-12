;;; takt-model.l -*- Package: EDITOR -*-

;; Version: 0.1
;; Created: 2016-07-07

(provide "takt-mode")

(in-package "editor")

(eval-when (compile load eval)
  (require "c-mode")
  (require "takt-play")
  (require "takt-track-mode"))

(export '(takt-mode
          takt-repl
          *takt-mode-map*
          *takt-mode-hook*))

(defvar *keyword-file* "Takt.kwd")

(pushnew (directory-namestring (or *load-pathname* "."))
         *keyword-load-path*
         :test #'path-equal)

(defparameter *takt-mode-map*
  (let ((map (make-sparse-keymap)))
    (define-key map '(#\C-c #\f) 'takt:play-this)
    (define-key map '(#\C-c #\q) 'takt:stop)
    (define-key map '(#\C-c #\i) 'takt:show-interp-console)
    (define-key map '(#\C-c #\t) 'takt-show-track-summary)
    map))

(defvar *takt-mode-hook* nil)

(defun takt-mode ()
  "Takt editing mode."
  (interactive)
  (kill-all-local-variables)
  (setq buffer-mode 'takt-mode
        mode-name "Takt")
  (use-syntax-table ed::*c-mode-syntax-table*)
  (use-keymap *takt-mode-map*)
  (setq keyword-hash-table (load-keyword-file *keyword-file*))
  (run-hooks '*takt-mode-hook*))

(pushnew '("\\.takt\\'" . takt-mode) *auto-mode-alist* :test #'equal)

(defun takt-repl ()
  (interactive)
  (let ((*eshell* (takt::program-path)))
    (shell)))

;; EOF
