;;; conf/wandbox.l

(require "wandbox")
(global-set-key '(#\C-c #\w #\w) 'wandbox)
(global-set-key '(#\C-c #\w #\r) 'wandbox:compile-region)
(global-set-key '(#\C-c #\w #\e) 'wandbox:eval-last-sexp)
