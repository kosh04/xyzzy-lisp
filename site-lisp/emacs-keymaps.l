;;; -*- Mode: Lisp; Package: USER -*-

;; 参考: Emacsキーバインド - XyzzyWiki
;; http://xyzzy.s53.xrea.com/wiki/index.php?Emacs%A5%AD%A1%BC%A5%D0%A5%A4%A5%F3%A5%C9

;;; Code:

(provide "emacskey")

(global-set-key #\C-/ 'undo)
(global-set-key #\M-v 'previous-page)
(global-set-key #\M-% 'query-replace)
;(global-set-key #\C-M-% 'replace-regexp)
(global-set-key #\C-M-% 'query-replace-regexp)
(global-set-key #\C-M-\\ 'indent-region)
;(global-set-key '(#\C-x #\h) 'mark-whole-buffer)
(global-set-key '(#\C-x #\u) 'undo)
(global-set-key '(#\C-x #\C-r) 'find-file-read-only)
(global-set-key '(#\C-x #\C-w) 'emacs-write-file)
(global-set-key #\Home 'beginning-of-line)
(global-set-key #\End 'end-of-line)
;(global-set-key #\C-_ 'undo)
(global-set-key #\C-- 'negative-argument)
(global-set-key #\C-\\ 'toggle-ime)
;(global-set-key #\C-o 'toggle-ime) ; Canna 風
;; (dolist (c '(#\C-0 #\C-1 #\C-2 #\C-3 #\C-4 #\C-5 #\C-6 #\C-7 #\C-8 #\C-9))
;;   (global-set-key c 'digit-argument))
(when (eq (lookup-key-command '(#\C-x #\n)) 'narrow-to-region)
  (global-unset-key '(#\C-x #\n))
  (global-set-key '(#\C-x #\n #\n) 'narrow-to-region))
(when (eq (lookup-key-command '(#\C-x #\w)) 'widen)
  (global-unset-key '(#\C-x #\w))
  (global-set-key '(#\C-x #\n #\w) 'widen))
(global-set-key #\M-: 'eval-expression)
(global-set-key #\M-! 'execute-subprocess)
(global-set-key #\M-SPC 'just-one-space)
(global-set-key #\C-M-k 'kill-sexp)
;(global-set-key #\C-M-h 'backward-kill-sexp)
;(substitute-key-definition 'next-virtual-line 'next-line)
;(substitute-key-definition 'previous-virtual-line 'previous-line)
(global-set-key #\C-] 'quit-recursive-edit)
#+emacs
(global-set-key #\C-M-c 'exit-recursive-edit)

;; 動的入力補完
(require "dabbrev")
(global-set-key #\M-/ 'dabbrev-expand)

;; 矩形 (*-selection)
;; *-register とキーが少し被っている
(global-set-key '(#\C-x #\r #\c) 'clear-rectangle)
(global-set-key '(#\C-x #\r #\d) 'delete-rectangle)
(global-set-key '(#\C-x #\r #\k) 'kill-rectangle)
(global-set-key '(#\C-x #\r #\o) 'open-rectangle)
(global-set-key '(#\C-x #\r #\r) 'copy-rectangle-to-register)
;(global-set-key '(#\C-x #\r #\w) 'copy-rectangle) ;?
(global-set-key '(#\C-x #\r #\t) 'string-rectangle)
(global-set-key '(#\C-x #\r #\y) 'yank-rectangle)

;; フレーム (#\C-x #\5 *)
(defvar ctl-x-5-map (make-sparse-keymap))
(setf (symbol-function 'ctl-x-5-prefix) ctl-x-5-map)
(define-key ctl-x-map #\5 'ctl-x-5-prefix)
(define-key ctl-x-5-map #\o 'other-pseudo-frame)
(define-key ctl-x-5-map #\0 'delete-pseudo-frame)
(define-key ctl-x-5-map #\2 'new-pseudo-frame)

(global-set-key '(#\C-x #\3) 'split-window-vertically)
(define-key ctl-x-4-map #\C-o 'display-buffer)

;; エンコーディング
(defun revert-buffer-with-coding-system (encoding)
  (interactive "zEncoding: ")
  (revert-buffer encoding))
(global-set-key '(#\C-x #\RET #\f) 'change-fileio-encoding)
(global-set-key '(#\C-x #\RET #\r) 'revert-buffer-with-coding-system)

;;; EOF
