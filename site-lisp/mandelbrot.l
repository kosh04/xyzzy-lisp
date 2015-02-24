;;; -*- Mode: Lisp; Package: USER -*-
;;;
;;; This file is NOT part of xyzzy.
;;;

;;; Usage:
;;; (autoload 'mandelbrot "mandelbrot" t)
;;; M-x: mandelblot

(provide "mandelbrot")

(in-package "user")

(eval-when (compile load eval)
  (require "cmu_loop"))

(defun %mandelbrot (&optional stream)
  (loop for y from -1 to 1.1 by 0.1 do
    (loop for x from -2 to 1 by 0.04 do
      (let* ((c 126)
             (z (complex x y))
             (a z))
        (loop while (< (abs
                        (setq z (+ (* z z) a)))
                       2)
          while (> (decf c) 32))
        (princ (code-char c) stream)))
    (terpri stream)))

;;;###autoload
(defun mandelbrot ()
  (interactive)
  (long-operation
    (with-output-to-temp-buffer (#1="*Mandelbrot set*" nil)
      (%mandelbrot))
    (switch-to-buffer #1#)))

(defun add-menu-mandelbrot ()
  (let ((menu (get-menu (get-menu *app-menu* 'ed::tools) :|(>_<)-popup|)))
    (add-menu-item menu nil "�}���f���u���b�g�W��(&M)" 'mandelbrot)))

(add-hook '*post-startup-hook* 'add-menu-mandelbrot)