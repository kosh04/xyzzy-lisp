;;; batch-make.l

;; see Makefile

(provide "batch-make")

(defun batch-make (rule name)
  (multiple-value-bind (value err)
      (ignore-errors
        (unless (si:getenv "XYZZYHOME")
          (error "Must set: XYZZYHOME"))
        (let* ((file (concat name ".l"))
               (src (compile-file-pathname file))
               (dst (merge-pathnames (concat "site-lisp/" (file-namestring src))
                                     (si:getenv "XYZZYHOME"))))
          (cond ((equal rule "compile")
                 (compile-file file))
                ((equal rule "install")
                 (copy-file src dst :if-exists :overwrite))
                ((equal rule "uninstall")
                 (delete-file dst :if-access-denied :force))
                ((equal rule "test")
                 (let ((testfile (merge-pathnames (concat name "-test.l") name)))
                   ;; XXX/XXX-test.l
                   (load testfile :verbose t :print t)
                   ;; TODO: How to detect on test failure?
                   (run-tests)))
                ((equal rule "clean")
                 (delete-file src :if-access-denied :force))
                (t
                 (error "Unknown rule: ~a" rule)))))
    (declare (ignore value))
    (when err
      (format *debug-output* "make fail in [~a ~a]: ~a" rule name err)
      (format *debug-output* "=== *Trace Output* ===%~a"
              (save-excursion
                (set-buffer "*Trace Output*")
                (buffer-substring (point-min) (point-max)))))
    (when (and (equal rule "test")
               (null err))
      (format *debug-output* "=== *Test Results* ===~%~a"
              (save-excursion
                (set-buffer "*Test Results*")
                (buffer-substring (point-min) (point-max)))))
    (kill-xyzzy (if err nil t))))
