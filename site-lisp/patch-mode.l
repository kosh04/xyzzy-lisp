;;; -*- Mode: Lisp; Package: EDITOR; Encoding: Shift_JIS -*-
;;;
;;; This file is NOT part of xyzzy.
;;;

;; 申し訳程度の色付き diff-mode

;; Author: KOBAYSHI Shigeru (kosh)

(provide "patch-mode")

(in-package "editor")

(export '(patch-mode))

(defparameter *patch-mode-keyword-list*
  (compile-regexp-keyword-list
   `(("^--- .*" nil 6)
     ("^\\+\\+\\+ .*$" nil 7)
     ("^@@ -\\([0-9]+\\)\\(?:,\\([0-9]+\\)\\)? \\+\\([0-9]+\\)\\(?:,\\([0-9]+\\)\\)? @@" nil 5)
     ("^\\(-\\).*$" nil (:color 1)) ; "git diff" 風味
     ("^\\(\\+\\).*$" nil (:color 10))
     )))

(defun patch-mode ()
  (interactive)
  (toggle-read-only t)
  (make-local-variable 'regexp-keyword-list)
  (setq regexp-keyword-list *patch-mode-keyword-list*))

(pushnew '("\\.diff$" . patch-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.patch$" . patch-mode) *auto-mode-alist* :test #'equal)
