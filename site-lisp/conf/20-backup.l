;;; conf.backup.l

(require "backup")

;; %USERPROFILE%/AppData/Local/Temp/xl-backup
(setq *backup-directory* (merge-pathnames "xl-backup" (si:getenv "TEMP"))
      *hierarchic-backup-directory* t)

(push (cons "Backup" *backup-directory*) *filer-directories*)

(setq backup-by-copying :remote)
