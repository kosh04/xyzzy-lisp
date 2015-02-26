;;; www-mode.conf.l

;; www-mode
(require "www/config")

(define-key www::*www-view-mode-map* '(#\C-x #\k) 'kill-selected-buffer)
(define-key www::*www-view-mode-map* #\= 'www::www-view-to-src)
(define-key www::*www-view-mode-map* #\F22 'previous-page) ; S-space
(define-key www::*www-view-mode-map* #\S
            #'(lambda ()
                (interactive)
                (google nil :callback #'(lambda (url) (www-open-url url)))))
; ?
(pushnew 'www::script www::*www-tag-trim-list*)

