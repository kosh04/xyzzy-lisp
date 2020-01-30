;;; config/Ispell

;; USB Ç©ÇÁégÇ§Ç∆Ç´ÇÕ ispell.ini Ç…íçà”
(require "ispell")

(defun ispell-create-ini (&key (if-exists nil))
  (let* ((dir (directory-namestring ed::*ispell-command*))
         (file (merge-pathnames "ispell.ini" dir)))
    (with-open-file (out file
                         :direction :output
                         :if-exists if-exists)
      (when out
        (format out "[Config]~%LibDir=~A~%" dir)))))

#+NIL
(ispell-create-ini :if-exists :overwrite)

(defun ispell-word ()
  (interactive "*")
  (ed::edict-lookup-word #'ispell-region))

;;(global-set-key '(#\C-x #\w) 'ispell-word)
(global-set-key #\M-$ 'ispell-word)
