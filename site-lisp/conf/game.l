;; conf.Game.l

(autoload 'aitan "aitan" t)
(autoload 'mandelbrot "mandelbrot" t)

(defun kitaa ()
  (interactive)
  (let ((kita-list '("(ßÍß)" "( ßÍ)" "(   ß)" "(    )" "(ß   )" "(Íß )" "(ßÍß)")))
    (while (not (listen *keyboard*))
      (dolist (kao kita-list)
        (minibuffer-message "·À„ª„ª„ª~A„ª„ª„ª!!!!" kao)
        (sit-for .1)))))
