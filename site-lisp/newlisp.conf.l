;;; conf.newlisp.l

(require "newlisp")
;(require "newlispfn")

(setq *newlisp-manual*
      (merge-pathnames "Dropbox/Public/newlisp/newlisp_manual-10.5.0_firefox.txt"
                       (si:getenv "USERPROFILE")))

(pushnew '("\\.lsp$" . newlisp-mode) *auto-mode-alist* :test #'equal)
(pushnew '("qa-.*$" . newlisp-mode) *auto-mode-alist* :test #'equal)

(pushnew (cons "Newlisp" (si:getenv "NEWLISPDIR")) *filer-directories*)

(when (modulep "comment")
  (pushnew '(newlisp-mode #\; 2 " ") comment-mode-alist :test #'equal))

(define-key ed::*newlisp-mode-map* '(#\C-c #\C-s) 'run-newlisp)
