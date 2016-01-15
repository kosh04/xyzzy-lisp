;;; conf.newlisp.l

(require "newlisp")
;(require "newlispfn")

(setq *newlisp-manual*
      (merge-pathnames "Dropbox/Public/newlisp/newlisp_manual-10.5.0_firefox.txt"
                       (si:getenv "USERPROFILE")))

(pushnew '("qa-.*$" . newlisp-mode) *auto-mode-alist* :test #'equal)

(pushnew (cons "Newlisp" (si:getenv "NEWLISPDIR")) *filer-directories*)

(when (modulep "comment")
  (pushnew '(newlisp-mode #\; 2 " ") comment-mode-alist :test #'equal))

(define-key ed::*newlisp-mode-map* '(#\C-c #\C-s) 'run-newlisp)

;; (use "arglist.lsp") �Ƒg�ݍ��킹�Ďg�p���Ă݂�
(defun newlisp-arglist (f)
  (interactive "sArglist: ")
  (newlisp-eval (format nil "(arglist ~A)" f)))

(define-key ed::*newlisp-mode-map* #\C-\;
            #'(lambda ()
                (interactive)
                (newlisp-arglist (or (ed::newlisp-current-word)
                                     (error "�V���{�����Ȃ���")))))