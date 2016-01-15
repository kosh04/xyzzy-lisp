(defvar *paren-regexp-keyword-list*
  (compile-regexp-keyword "[()]" nil '(:color 15)))

(defun set-paren-color ()
  "括弧を薄くしたらS式が見やすいかもしれない"
  (make-local-variable 'regexp-keyword-list)
  ;; ed::*clickable-uri-regexp* 共存
  (push *paren-regexp-keyword-list* regexp-keyword-list))
(add-hook '*lisp-mode-hook* 'set-paren-color)
(add-hook '*lisp-interaction-mode-hook* 'set-paren-color)

(global-set-key #\F12 'lisp-mode)
(global-set-key #\C-F12 'lisp-interaction-mode)
(set-function-bar-label #\F12 "Lisp mode")
(set-function-bar-label #\C-F12 "Lisp Interaction mode")

(proclaim '(special *lisp-implementation-alist* *lisp-default-lisp*))
(setq *lisp-implementation-alist*
      `(
        ;; *terminal-encoding* => #<ENCODING "CP932" :DOS>
        (clisp "C:/usr/local/clisp-2.44/clisp.exe")
        (olio "C:/usr/local/clisp-2.47-full/bin/clisp.exe")
        (gcl-cltl1 "C:/PROGRA~1/GCL-26~1.7-C/lib/GCL-26~1.7/unixport/SAVED_~1.EXE")
        (gcl-ansi "C:/PROGRA~1/GCL-26~1.7-A/lib/GCL-26~1.7/unixport/SAVED_~1.EXE")
        (newlisp "C:/PROGRA~1/newlisp/newlisp.exe -C")
        (newlisp-sjis "C:/PROGRA~1/newlisp/NEWLIS~2.EXE -C" ,*encoding-sjis*)
        )
      *lisp-default-lisp* 'gcl-ansi)

(defun slime? (&optional (cmd *lisp-default-lisp*))
  (interactive (list (if *prefix-args*
                         (intern (completing-read "Which LISP? "
                                                  *lisp-implementation-alist*
                                                  :must-match t))
                         *lisp-default-lisp*)))
  (multiple-value-bind (name command encoding)
      (values-list (assoc cmd *lisp-implementation-alist*))
    (let ((*eshell* command)
          (*shell-mode-hook* (list
                              #'(lambda ()
                                  (rename-buffer (format nil "*~A*" name))
                                  (set-buffer-fold-type-none))))
          (*default-process-encoding* (or encoding *encoding-utf8n*)))
      (shell))))
;(global-set-key '(#\C-x #\r #\l) 'slime?)

(defun run-gcl (&optional ansi)
  (interactive "P")
  (shell-execute (if ansi
                     "C:/PROGRA~1/GCL-26~1.7-A/bin/gcl.bat"
                     "C:/PROGRA~1/GCL-26~1.7-C/bin/gcl.bat")))
;(global-set-key '(#\C-x #\r #\g) 'run-gcl)

(defun run-lisp (&optional arg)
  (interactive "P")
  (if arg
      ;; clisp のあるディレクトリにDOS窓を開く
      (let ((ed::*launch-app-directory*
             (directory-namestring *lisp-exec-path*)))
        (launch-application *ckw-path*))
    ;; これだとウィンドウ消してもlisp.exeプロセスだけ残るんだが
    (launch-application (concat *ckw-path* " -e " *lisp-exec-path*))))
;; (global-set-key '(#\C-x #\r #\l) 'run-lisp)

(defun run-lispbox ()
  (interactive)
  (shell-execute "C:/usr/local/lispbox-0.7/lispbox.bat"))

(let ((ht (make-hash-table)))
  (setf (gethash 'foo ht) 1)
  (setf (gethash 'bar ht) 2)
  (loop for key
    being the hash-keys
    in ht
    using (hash-value value)
    collect (cons key value)))
;;=> ((BAR . 2) (FOO . 1))
;; xyzzy だとエラー (car 2)
