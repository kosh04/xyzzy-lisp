;;; -*- Mode: Lisp; Package: User; Encoding: Shift_JIS -*-
;;;
;;; This file is NOT part of xyzzy.
;;;

(provide "emacs-help")

(in-package "user")

(defvar help-map nil)
(unless help-map
  (setq help-map (make-sparse-keymap))
  (define-key help-map #\A 'apropos)
  (define-key help-map #\a 'command-apropos)
  (define-key help-map #\b 'describe-bindings)
  (define-key help-map #\c 'describe-key-briefly)
  (define-key help-map #\f 'describe-function)
  (define-key help-map #\k 'describe-key)
  (define-key help-map #\l 'view-lossage)
  (define-key help-map #\v 'describe-variable)
  (define-key help-map #\w 'where-is)
  (define-key help-map #\C-a 'about-dialog)

  (define-key help-map #\F1 'show-html-help)
  (define-key help-map #\C-l 'find-library)
  (define-key help-map #\? 'call-help-list))

(setf (symbol-function 'help-command-prefix) help-map)
(global-set-key #\F1 'help-command-prefix)

#|
;; お好みで
(eval-when (compile load eval)
  (require "info-modoki-mode")
  (require "info"))

(define-key help-map #\A 'imm-apropos)
(define-key help-map #\a 'imm-command-apropos)
(define-key help-map #\b 'imm-describe-bindings)
(define-key help-map #\i 'info)
(define-key help-map #\k 'imm-describe-key)
|#

(defun command-execute-in-keymap (prompt keymap)
  (unless (keymapp keymap)
    (error 'type-error :datum keymap :expected-type 'keymap))
  (labels ((expand-keymap (map)
             (case (type-of map)
               (simple-vector
                (mapcan #'expand-keymap-1 (coerce map 'list)))
               (cons
                (mapcan #'expand-keymap-1 (mapcar #'cdr (rest map))))))
           (expand-keymap-1 (x)
             (cond ((null x) nil)
                   ((keymapp x) (expand-keymap x))
                   (t (list x)))))
    (let ((sym (find-symbol
                (completing-read prompt (expand-keymap keymap)
                                 :must-match t))))
      (unless (commandp sym)
        (error "関数が定義されていません: ~A" sym))
      (call-interactively sym))))

(defun call-help-list ()
  (interactive)
  (command-execute-in-keymap "Help: " help-map))

(defun read-exist-library (prompt &optional modules-only)
  (completing-read prompt
                   (if modules-only
                       *modules*
                     (mapcan #'(lambda (path)
                                 ;; "*.l" -> "*"
                                 ;; pathname-nameではディレクトリ名が除かれてしまう
                                 (mapcar #'(lambda (f) (substring f 0 -2))
                                         (directory path :recursive t :wild "*.l")))
                             *load-path*))
                   :case-fold t
                   :must-match t))

(defun find-library (lib)
  "*load-path*から適当に選んで開く."
  (interactive (list (read-exist-library "Find library: " nil)))
  (let ((file (find-load-path lib)))
    (when file
      (if (string-match "\\.lc$" file)
          (setq file (substring file 0 -1)))
      (find-file file)
      (add-history file '*minibuffer-file-name-history*))))

;; [2018-12-04] TODO: keymap 変数の再帰的な探索
(defun where-is-1 (def &aux hello)
  "Return ((key Key) . (keymap Symbol))"
  (or
   ;; esc
   (let ((p (position def esc-map)))
     (and p (cons (code-char (+ p #x8000)) 'esc-map)))
   ;; ctrl-x
   (let ((p (position def ctl-x-map)))
     (and p (cons (vector #\C-x (code-char p)) 'ctl-x-map)))
   ;; ctrl-c
   (let ((kv (find def spec-map :key 'safe-cdr)))
     (and kv (cons (vector #\C-c (car kv)) 'spec-map)))
   ;; help
   (let ((kv (find def help-map :key 'safe-cdr)))
     (and kv (cons (vector 'help-map (car kv)) 'help-map)))
   ;; *local
   (let ((kv (find def (local-keymap) :key 'safe-cdr)))
     (and kv (cons (car kv) 'local-keymap)))
   ;; *global
   (let ((p (position def *global-keymap*)))
     (and p (cons (code-char p) '*global-keymap*)))))

(defun where-is (definition)
  "Print message listing key sequences that invoke the command DEFINITION."
  (interactive "aWhere is command: ")
  (unless definition (error "No command"))
  (message "~s" (where-is-1 definition))
  (let ((x (where-is-1 definition)))
    (if x
        (message "~a is on ~s (~a)" definition (car x) (cdr x))
        (message "~a is not on any key" definition))))
