;;; conf.libmagic.l

(require "libmagic")

(defun get-file-type (pathname)
  "�t�@�C���^�C�v�𔻕ʂ���."
  (interactive "fFile type: " :default0 (get-buffer-file-name))
  (message "~A" (magic-file pathname)))

(defun filer-get-file-type ()
  (get-file-type (ed::filer-fetch-file nil nil)))

(define-key filer-keymap #\? 'filer-get-file-type)