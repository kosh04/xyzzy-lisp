;;; conf/conf.l

(setf (symbol-function 'conf-mode) #'perl-mode)

(pushnew '("\\.conf\\'" . conf-mode) *auto-mode-alist*)
(pushnew '("\\<configure\\>" . conf-mode) *auto-mode-alist*)
