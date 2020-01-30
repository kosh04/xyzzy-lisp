;;; config/info

;; 山本真二さんの info
;; http://www1.neweb.ne.jp/wa/sinj/xyzzy/

(shadow '(info) "user")
(require "info")

;; FIXME: どこかで起きているらしい名前(info)の衝突を回避する
(setf (symbol-function 'info) #'ed:info)

(dolist (dir (list
              (merge-pathnames "Programs/emacs-26.2/share/info/" (si:getenv "LOCALAPPDATA"))
              (merge-pathnames ".config/emacs/share/info/" (si:getenv "USERPROFILE"))
              ))
  (pushnew dir *info-directory-list* :test #'path-equal))

