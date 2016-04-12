;;; -*- Mode: Lisp; Package: EDITOR; Encoding: Shift_JIS -*-
;;;
;;; This file is NOT part of xyzzy.
;;;

;; Author: KOBAYASHI Shigeru (kosh)
;; Comment: おそらく車輪の再開発

(provide "makefile-mode")

(in-package "editor")

(export '(makefile-mode))

(defvar *makefile-keyword-hash-table* nil)
(defvar *makefile-keyword-file* "Makefile.kwd")

(defvar *makefile-mode-syntax-table* nil)
(unless *makefile-mode-syntax-table*
  (setq *makefile-mode-syntax-table* (make-syntax-table))
  (do ((x #x21 (1+ x)))((>= x #x7f))
    (let ((c (code-char x)))
      (unless (alphanumericp c)
        (set-syntax-punctuation *makefile-mode-syntax-table* c))))

  (set-syntax-string *makefile-mode-syntax-table* #\")
  (set-syntax-escape *makefile-mode-syntax-table* #\\)
  (set-syntax-symbol *makefile-mode-syntax-table* #\_)
  (set-syntax-symbol-prefix *makefile-mode-syntax-table* #\$)
  (set-syntax-match *makefile-mode-syntax-table* #\( #\))
  (set-syntax-match *makefile-mode-syntax-table* #\{ #\})
  (set-syntax-match *makefile-mode-syntax-table* #\[ #\])
  (set-syntax-start-comment *makefile-mode-syntax-table* #\#)
  (set-syntax-end-comment *makefile-mode-syntax-table* #\LFD)
  )

(defun makefile-mode ()
  (interactive)
  (kill-all-local-variables)
  (setq buffer-mode 'makefile-mode
        mode-name "Makefile")
  ;(use-keymap *makefile-mode-map*)
  (use-syntax-table *makefile-mode-syntax-table*)
  (and *makefile-keyword-file*
       (null *makefile-keyword-hash-table*)
       (setq *makefile-keyword-hash-table*
             ;; NOTE: Case-insensitive
             (load-keyword-file *makefile-keyword-file* nil)))
  (when *makefile-keyword-hash-table*
    (make-local-variable 'keyword-hash-table)
    (setq keyword-hash-table *makefile-keyword-hash-table*))
  (setq comment-start "# "
        comment-end ""
        comment-start-skip "#+[ \t]*")
  (setq comment-indent-function
        #'(lambda () (generic-comment-indent "#" #'calc-c-indent)))
  ;; http://raido.sakura.ne.jp/southly/xyzzy/makefile-mode.l
  (setq regexp-keyword-list 
        (compile-regexp-keyword-list
         '(("^\t+\\([+---@]+\\)"
            nil (:keyword 1 :bold) nil 1 1)
           ("^ *\\(\\.DEFAULT\\|\\.DELETE_ON_ERROR\\|\\.EXPORT_ALL_VARIABLES\\|\\.IGNORE\\|\\.INTERMEDIATE\\|\\.PHONY\\|\\.POSIX\\|\\.PRECIOUS\\|\\.SECONDARY\\|\\.SILENT\\|\\.SUFFIXES\\)[ \t]*:"
            nil (:keyword 0 :underline) nil 1 1)
           ("^ *\\(define\\|endef\\|ifdef\\|ifndef\\|ifeq\\|ifneq\\|else\\|endif\\|include\\|override\\|export\\|unexport\\|vpath\\)\\b"
            nil (:keyword 2) nil 1 1)
           ("\\$%\\|\\$(%D)\\|\\$(%F)\\|\\$(\\*D)\\|\\$(\\*F)\\|\\$(<D)\\|\\$(<F)\\|\\$(\\?D)\\|\\$(\\?F)\\|\\$(@D)\\|\\$(@F)\\|\\$(\\^D)\\|\\$(\\^F)\\|\\$\\*\\|\\$\\+\\|\\$<\\|\\$\\?\\|\\$@\\|\\$\\^"
            nil (:color 1 0) nil 0 0)
           ))
        )
  (run-hooks '*makefile-mode-hook*))

(pushnew '("\\<Makefile\\>" . makefile-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.mk$" . makefile-mode) *auto-mode-alist* :test #'equal)

