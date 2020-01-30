;;; config/backup

(require "backup")

;; XYZZYHOME/var/backup/*
(setq *backup-directory* (merge-pathnames "../../var/backup" (directory-namestring (or *load-pathname* ".")))
      *hierarchic-backup-directory* t)

(push (cons "Backup" *backup-directory*) *filer-directories*)

(setq backup-by-copying :remote)
