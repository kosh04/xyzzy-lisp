;;; config/Takt

(let* ((ldir (directory-namestring *load-pathname*))
       (takt-dir (merge-pathnames "../takt" ldir)))
  (when (file-directory-p takt-dir)
    (pushnew takt-dir *load-path* :test #'path-equal)
    (require "takt-mode")))
