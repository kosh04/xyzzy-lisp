;; usage[1]: cmd> xyzzy.exe -q -trace -l batch-byte-cmpile.l FILENAME.l
;; usage[2]: cmd> xyzzy.exe -q -trace -l batch-byte-cmpile.l *.l

(defun batch-byte-compile (target)
  (let ((files (if (file-exist-p target)
                   (list target)
                 (directory target :absolute t))))
    (dolist (f files)
      (byte-compile-file f)))
  ;; (kill-xyzzy)
  t)

;; %XYZZYHOME%/lisp/estartup.l L98-99 �Q��
(add-hook '*process-command-line-hook* 'batch-byte-compile)