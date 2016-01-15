;;; pp.l --- printf debug

;; usage: #?(form ...)

(provide "pp")

(defmacro pp (form)
  `(let ((#1=#:result (multiple-value-list ,form)))
     (msgbox "Form: ~S~%Value: ~{~S~^; ~}" ',form #1#)
     ;;(format t "Form: ~S~%Value: ~{~S~^; ~}~%" ',form #1#)
     (values-list #1#)))

(defun |pp-reader| (stream subchar arg)
  (declare (ignore subchar arg))
  `(pp ,(read stream t nil t)))

(set-dispatch-macro-character #\# #\? #'pp-reader)
