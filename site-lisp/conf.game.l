;; conf.Game.l

(autoload 'aitan "aitan" t)
(autoload 'mandelbrot "mandelbrot" t)

(defun kitaa ()
  (interactive)
  (let ((kita-list '("(߁��)" "( ߁�)" "(   �)" "(    )" "(�   )" "(��� )" "(߁��)")))
    (while (not (listen *keyboard*))
      (dolist (kao kita-list)
        (minibuffer-message "��������~A������!!!!" kao)
        (sit-for .1)))))