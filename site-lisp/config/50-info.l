;; 山本真二さんの info
;; http://www1.neweb.ne.jp/wa/sinj/xyzzy/

(shadow '(info) "user")
(require "info")

;; FIXME: どこかで起きているらしい名前(info)の衝突を回避する
(setf (symbol-function 'info) #'ed:info)

(pushnew (merge-pathnames "opt/emacs-24.5-IME-patched-generic-cpu/share/info/" (si:getenv "HOME"))
         *info-directory-list*
         :test #'path-equal)
