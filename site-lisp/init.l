;;; init.el

(defvar *xyzzy-user-init-directory*
  (directory-namestring (or *load-pathname* ".")))

;; このディレクトリを *load-path* に追加
(pushnew *xyzzy-user-init-directory* *load-path* :test #'path-equal)

;; load conf/*-*.l
(dolist (config (directory (merge-pathnames "conf/" *xyzzy-user-init-directory*)
                           :absolute t
                           :wild "*-*.l"))
  (load config :verbose t :print t))

(gc)
