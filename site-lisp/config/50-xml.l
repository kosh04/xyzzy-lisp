;;; conf.XML.l

(require "xml/xml-mode")
(use-package 'xml)
(require "xml/xhtml")

;; use html+
(setq *auto-mode-alist*
      (delete (cons xml::*xhtml-suffix* 'xml-mode)
              *auto-mode-alist* :test #'equal))

(pushnew '("\\.jnlp$" . xml-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.manifest$" . xml-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.jff$" . xml-mode) *auto-mode-alist* :test #'equal) ; JFLAP
(pushnew '("\\.webarchivexml$" . xml-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.wsf$" . xml-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.xsd$" . xml-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.mxml$" . xml-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.iml\\'" . xml-mode) *auto-mode-alist* :test #'equal)

(setq xml::*xml-cdata-attribute* '(:foreground 15))

(defun xml-mode-user-hooks ()
  (setq comment-indent-function #'xml:xml-comment-indent))
;(add-hook 'xml:*xml-mode-hook* 'xml-mode-user-hooks)

;; xml-parser
;; (require "xml-parser-modoki")
(autoload 'ed::xmlpm-parse-file "xml-parser-modoki")
(setf (symbol-function 'xml-parse-file) #'ed::xmlpm-parse-file)
