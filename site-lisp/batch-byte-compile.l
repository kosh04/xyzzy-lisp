;; usage[1]: cmd> xyzzy.exe -q -trace -l batch-byte-compile.l FILENAME.l
;; usage[2]: cmd> xyzzy.exe -q -trace -l batch-byte-compile.l *.l

(defun batch-byte-compile (target)
  (let ((files (if (file-exist-p target)
                   (list target)
                 (directory target :absolute t))))
    (dolist (f files)
      (byte-compile-file f))))

;; see %XYZZYHOME%/lisp/estartup.l L98-99
(add-hook '*process-command-line-hook* 'batch-byte-compile)
