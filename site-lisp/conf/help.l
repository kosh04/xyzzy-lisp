;;; conf.help.l

(require "paren")
(require "ldoc")

;;
(require "info-modoki-mode")
(setq *imm-reference-file* "~/reference/reference.txt")

;; �w���v�����������֗���
(require "emacs-help")
;(require "info")
(define-key help-map #\A 'imm-apropos)
(define-key help-map #\a 'imm-command-apropos)
(define-key help-map #\b 'imm-describe-bindings)
(define-key help-map #\i 'info)
(define-key help-map #\k 'imm-describe-key)

;; ���t�@�����X�𒲂ׂ�
(require "info-modoki-mode")
(defun imm-refer-symbol (sym)
  (interactive "SReference: ")
  (imm-refer (symbol-name sym)))
(defun imm-describe-function (f)
  (interactive "aDescrive function: ")
  (imm-refer (symbol-name f)))
(defun imm-describe-variable (v)
  (interactive "vDescrive variable: ")
  (imm-refer (symbol-name v)))
(define-key ed::*lisp-mode-map* #\F3 'imm-refer-selection)
(define-key ed::*lisp-interaction-mode-map* #\F3 'imm-refer-selection)
(define-key *info-modoki-mode-map* #\q 'kill-selected-buffer)
(pushnew 'info-modoki-mode *ldoc-activated-mode-list*) ; ldoc ���g����悤��
(add-hook '*info-modoki-mode-hook* 'turn-on-paren)