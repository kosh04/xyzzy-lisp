;;; config/site-lisp

(require "redef")
(require "junk-lib")

;(require "emacs")
(require "emacs-fn")
(require "emacs-keymaps")
(require "regexp-opt")
(require "winapp")
(require "google-search")
(require "patch-mode")
;(require "sessionstore")
(require "json")
(require "json-encode")
(require "sgml-util")
(require "view-minor-mode")
(require "memo/junk")

;;(require "my-dired")
(require "ls-l")
(global-set-key '(#\C-x #\d) 'ls-l)
(global-set-key '(#\C-x #\C-j) 'ls-l*)
(global-set-key '(#\C-x #\4 #\d) 'ls-l-other-window)
