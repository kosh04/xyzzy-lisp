;;; conf.progmode.l --- コード編集系の設定

(defun indent-and-next-line ()
  "インデントして次の行へ"
  (interactive)
  (save-excursion
    (progn (goto-eol) (delete-trailing-spaces))
    (when (and mode-specific-indent-command
               ;; 空行でない場合
               (not (and (bolp) (eolp))))
      (funcall mode-specific-indent-command)))
  (next-line))

(global-set-key #\M-n 'indent-and-next-line)

;; C (c-mode.l)
(setq c-indent-level 2
      ;; c-argdecl-indent 5
      ;; c-brace-imaginary-offset 0
      c-brace-offset 0 ; -2
      ;; c-comment-indent 2
      ;; c-continued-statement-offset 2
      ;; c-label-offset -2
      )
(setq *c-comment-c++-style* t)  ; "// " でコメントアウト(indent-for-comment)

(pushnew '("\\.rc$" . c-mode) *auto-mode-alist* :test #'equal)

;; C++ (cc-mode.l)
(setf (symbol-function 'cc-mode) #'c++-mode)

;; Java (java.l)
(require "java")
(setq *java-indent-tabs-mode* t)
(setq java-indent-level 4)
(pushnew ".class" ignored-extensions :test #'equal)

;; Comment
(require "comment")
(global-set-key '(#\C-c #\C-c) 'comment-out-region)
;; コメントをはずす時は C-u M-x comment-out-region

;; tags.l
(defun tag-jump ()
  (interactive)
  (or (jump-tag)
      (direct-tag-jump)))

(global-set-key #\F4 'tag-jump)

;; Basic
(pushnew '("\\.vbs$" . basic-mode) *auto-mode-alist* :test 'equal) ; VBScript
(pushnew '("\\.asp$" . basic-mode) *auto-mode-alist* :test 'equal) ; Active Server Pages

;; PHP-mode
(require "php-mode")
;(load-library "php-misc")
(pushnew '("\\.php$" . php-mode) *auto-mode-alist*)
(defun php-user-hook ()
  (make-local-variable 'c-indent-level)
  (setq c-indent-level 4))
(add-hook '*php-mode-hook* 'php-user-hook)

;; Batch file (bat-mode)
(require "bat-mode")
(pushnew '("\\.bat$" . bat-mode) *auto-mode-alist* :test 'equal)
(pushnew '("\\.cmd$" . bat-mode) *auto-mode-alist* :test 'equal)
(push (car (compile-regexp-keyword-list '(("\\<\\(?:SETLOCAL\\|ENDLOCAL\\)\\>" t (:keyword 0)))))
      *bat-regexp-keyword-list*)

;; Lua
(require "lua")
(pushnew '("\\.lua\\(?:doc\\)?$" . lua-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.nse$" . lua-mode) *auto-mode-alist* :test #'equal)

;; Python-mode
(require "shell")
(require "py-mode")
(push '("\\.py$" . py-mode) *auto-mode-alist*)
(setf (symbol-function 'python-mode) #'py-mode)

;; Ruby-mode
(require "ruby")
(pushnew '("\\.rb$" . ruby-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.rake$" . ruby-mode) *auto-mode-alist* :test #'equal)
(set-syntax-string *ruby-mode-syntax-table* #\/)

;; Golang-mode
(require "golang")
(setq *golang-indent-column* 4)
(push '("\\.go$" . golang-mode) *auto-mode-alist*)
(defun golang-user-hook ()
  ;(setq indent-tabs-mode t)
  (change-fileio-encoding *encoding-utf8n*)
  )
(add-hook '*golang-mode-hook* 'golang-user-hook)

;; 自作 Makefile-mode
(require "makefile-mode")

;; HTML+
(require "htmlmode")
(unintern 'html+-mode)		; XXX
(setq ed::*html+-use-html-kwd* t) ; use HTML 5.0
(require "html+-mode")
(setq *html+-tag-attribute* '(:bold t :foreground 2))
(pushnew '("\\.[xs]?html?$" . html+-mode) *auto-mode-alist* :test 'equal)

;(define-key *html+-mode-map* #\C-h 'html+-backward-)
(define-key *html+-mode-map* '(#\C-c #\C-v) 'execute-buffer-file)
(define-key *html+-mode-map* #\Tab 'html+-indent-line)

;; Cygwin
(require "cygwin")
;;(setq ed::*cygwin-environment-alist* '(("LANG" . "ja_JP.SJIS")))
(setq ed::*cygwin-environment-alist* '(("LANG" . "C")))
(push (cons "PATH" (concat "C:\\cygwin\\bin;"  (si:getenv "PATH"))) ed::*cygwin-environment-alist*)
;(global-set-key '(#\C-x #\r #\c) 'run-cygwin-console)
(pushnew "/usr/local/share/man" *manpath* :test #'equal)
(pushnew "/usr/local/man/" *manpath* :test #'equal)

(setf (symbol-function 'bash) #'run-cygwin-console)

;; アセンブラ (for GAS-SH)
(require "asm-mode")
(pushnew '("\\.\\(asm\\|s\\)$" . asm-mode) *auto-mode-alist* :test #'equal)

(require "cmacexp")
(define-key ed::*c-mode-map* '(#\C-c #\C-e) 'c-macro-expand-region)
