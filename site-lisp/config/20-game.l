;;; config/Game

(require "aitan")
(require "animate")
(require "mandelbrot")
(require "zone")

(defun kitaa ()
  (interactive)
  (let ((kita-list '("(߁��)" "( ߁�)" "(   �)" "(    )" "(�   )" "(��� )" "(߁��)")))
    (while (not (listen *keyboard*))
      (dolist (kao kita-list)
        (minibuffer-message "��������~A������!!!!" kao)
        (sit-for .1)))))
