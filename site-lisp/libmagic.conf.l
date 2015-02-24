;;; conf.libmagic.l

(require "libmagic/autoload")
;(require "libmagic/libmagic")

(defun get-file-type (pathname)
  "ファイルタイプを判別する."
  (interactive "fFile type: " :default0 (get-buffer-file-name))
  (message "~A" (magic-file pathname)))

(defun filer-get-file-type ()
  (get-file-type (ed::filer-fetch-file nil nil)))

(define-key filer-keymap #\? 'filer-get-file-type)
