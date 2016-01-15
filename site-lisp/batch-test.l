;;; batch-test.l

(defun batch-test (target)
  (let ((*standard-output* *debug-output*))
    (multiple-value-bind (value err)
        (ignore-errors
          (load target)
          (run-tests))
      (format t "=== Test Results ===~%~a"
              (save-excursion
                (set-buffer "*Test Results*")
                (buffer-substring (point-min) (point-max))))
      (when err
        (format *debug-output* "TEST fail: ~a" (si:*condition-string err)))
      (kill-xyzzy (if err nil t)))))

(add-hook '*process-command-line-hook* 'batch-test)
