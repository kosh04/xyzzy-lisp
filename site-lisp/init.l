;;; init.el

(defvar *user-init-directory*
  (directory-namestring (or *load-pathname* ".")))

;; このディレクトリを *load-path* に追加
(pushnew *user-init-directory* *load-path* :test #'path-equal)

(defvar *user-config-files*
  (directory (merge-pathnames "config/" *user-init-directory*)
             :absolute t
             :wild "*-*.l")
  "Files config/*-*.l")

(dolist (config *user-config-files*)
  (load config :verbose t :print t))

(gc)
