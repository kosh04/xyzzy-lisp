;;; memo/setf.l --- オレオレsetf定義

;; 何でもsetfでまとめればいいってものでもないことは分かった
;; $EMACS_LISP/cl-macs.el 参照

(defsetf macro-function (symbol) (new)
  `(si:*fset ,symbol ,new))

(defsetf process-filter set-process-filter)
(defsetf process-sentinel set-process-sentinel)
(defsetf process-incode set-process-incode)
(defsetf process-outcode set-process-outcode)
(defsetf process-eol-code set-process-eol-code)

(defsetf buffer-eol-code (&optional buffer) (code)
  `(set-buffer-eol-code ,code ,buffer))
#+TEST
(setf (buffer-eol-code) *eol-cr*)

(defsetf get-buffer-file-name (&optional buffer) (file-name)
  `(set-buffer-file-name ,file-name ,buffer))
#+TEST
(setf (get-buffer-file-name) "./memo.l")

(defsetf get-buffer-alternate-file-name set-buffer-alternate-file-name)
#+TEST
(setf (get-buffer-alternate-file-name) "memo.l")

(defsetf ed::find-buffer-colors (buffer) (color)
  `(set-buffer-colors ,color ,buffer))
#+TEST
(setf (ed::find-buffer-colors (selected-buffer)) #(0 #xffffcc))

(defsetf buffer-fileio-encoding set-buffer-fileio-encoding)
#+TEST
(setf (buffer-fileio-encoding) *encoding-euc-jp*)

(defsetf get-ime-mode set-buffer-ime-mode)

(defsetf documentation (symbol doc-type) (value)
  `(si:*putprop ,symbol ,value
                ,(case doc-type
                   (function 'function-documentation)
                   (variable 'variable-documentation)
                   (t doc-type))))

(defsetf lookup-keymap define-key)

;; Converting CLtL2 to ANSI CL - http://bc.tech.coop/cltl2-ansi.htm
;; 1) ANSI replaced function get-setf-method with get-setf-expansion.
;; ANSI renamed get-setf-method-multiple-value to get-setf-expansion.
;; Note deletion:

(setf (macro-function 'define-setf-expander)
      (macro-function 'define-setf-method))
;;(setf (symbol-function 'get-setf-expansion) #'get-setf-method)
(setf (symbol-function 'get-setf-expansion) #'get-setf-method-multiple-value)

(defsetf assoc (key alist) (value)
  `(let ((#1=#:found (assoc ,key ,alist)))
     (if #1#
         (setf (cdr #1#) ,value)
       (push (cons ,key ,value) ,alist))))

#+TEST
(let ((alist '((a . 10) (b . nil))))
  (setf (assoc 'a alist) 90
        (assoc 'b alist) 20
        (assoc 'c alist) 30)
  alist)
;;=>((c . 30) (a . 90) (b . 20))


#+NIL
(progn
set-buffer-fold-type-none       ; 折り返ししない
set-buffer-fold-type-column     ; 指定位置で折り返し
set-buffer-fold-type-window     ; ウィンドウ幅で折り返し

set-buffer-fold-type-none-update
set-buffer-fold-type-column-update
set-buffer-fold-type-window-update
set-buffer-fold-width
(buffer-fold-column)
)
;;; memo/setf.l ends here.
