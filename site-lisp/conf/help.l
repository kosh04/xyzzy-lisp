;;; conf.help.l

;;
(require "info-modoki-mode")
(setq *imm-reference-file* "~/reference/reference.txt")

;; ƒwƒ‹ƒv‚ğ‚à‚¤­‚µ•Ö—˜‚É
(require "emacs-help")
;(require "info")
(define-key help-map #\A 'imm-apropos)
(define-key help-map #\a 'imm-command-apropos)
(define-key help-map #\b 'imm-describe-bindings)
(define-key help-map #\i 'info)
(define-key help-map #\k 'imm-describe-key)

