;; conf.javascript.l

;; http://xyzzy.s53.xrea.com/wiki/index.php?%B3%C8%C4%A5lisp%2Fjavascript-mode
(require "javascript-mode")
(setq *javascript-indent-tabs-mode* nil)

(define-key *javascript-mode-map* #\Tab 'javascript-indent-line)
(define-key *javascript-mode-map* #\M-Tab 'ed::javascript-completion)
(define-key *javascript-mode-map* #\C-\/ 'undo)
;; (define-key *javascript-mode-map* '(#\C-c #\C-i) 'ed::javascript-completion)

;(set-syntax-string ed::*javascript-mode-syntax-table* #\/)
;(push '("\\.js$" . java-mode) *auto-mode-alist*)
(push '("\\.js$" . javascript-mode) *auto-mode-alist*)
(push '("\\.as$" . javascript-mode) *auto-mode-alist*) ; ActionScript
(push '("\\.ds$" . javascript-mode) *auto-mode-alist*) ; DMDScript
(push '("\\.ts$" . javascript-mode) *auto-mode-alist*) ; TypeScript
(push '("\\.dart$" . javascript-mode) *auto-mode-alist*) ; Dart

(defun javascript-user-hook ()
  (setq comment-column (default-value 'comment-column))
  (setq comment-start "// " comment-end ""))

(add-hook '*javascript-mode-hook* 'javascript-user-hook)

;; jshint
;; https://gist.github.com/sharapeco/7783075
(require "jshint")
