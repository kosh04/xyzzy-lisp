;;; config/www-mode

(require "www/config")

(let ((map www::*www-view-mode-map*))
  (define-key map '(#\C-x #\k) 'kill-selected-buffer)
  (define-key map #\= 'www::www-view-to-src)
  (define-key map #\F22 'previous-page) ; S-space
  (define-key map #\S
              #'(lambda ()
                  (interactive)
                  (google nil :callback #'(lambda (url) (www-open-url url))))))
;; ?
(pushnew 'www::script www::*www-tag-trim-list*)
