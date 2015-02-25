;;; memo/sgml.l

;; sgml-mode.el を改変
(defvar *sgml-special-char-alist*
  '(("&nbsp;" . "\X0120")
    ("&lt;" . "<")
    ("&gt;" . ">")
    ("&quot;" . "\"")
    ("&amp;" . "&")))

;; 2重置換に注意 "&amp;#65;" -> o"&#65;" x "A"
(defun sgml-unquote-region (start end)
  "リージョン内の文字実体参照を元の文字に変換する."
  (interactive "*r")
  (labels ((uchar (str radix)
             (unicode-char
              (parse-integer str :radix radix))))
    (save-excursion
      (save-restriction
        (narrow-to-region start end)
        (goto-char (point-min))
        (while (re-search-forward
                "&\\(#\\(x\\([0-9A-Fa-f]+\\)\\|\\([0-9]+\\)\\)\\|\\([A-Za-z]+\\)\\);?"
                t)
          (replace-match (cond
                          ((match-string 3) ; &#x0000;
                           (string (uchar (match-string 3) 16)))
                          ((match-string 4) ; &#0000;
                           (string (uchar (match-string 4) 10)))
                          (t
                           (or (cdr (assoc (match-string 0)
                                           *sgml-special-char-alist*
                                           :test #'string-equal))
                               ;; not found
                               (match-string 0))))
                         :literal t))
        ))))
(compile 'sgml-unquote-region)

(defun %sgml-quote (input &optional output)
  (do ((c #1=(read-char input nil :EOF) #1#))
      ((eq c :EOF))
    (princ (or (car (rassoc (string c)
                            *sgml-special-char-alist*
                            :test #'string-equal))
               c)
           output)))
(compile '%sgml-quote)

(defun sgml-quote (input &optional output)
  (if (stringp input)
      (if (null output)
          (with-input-from-string (i input)
            (with-output-to-string (o)
              (%sgml-quote i o)))
          (with-input-from-string (i input)
            (%sgml-quote i output)))
      (if (null output)
          (with-output-to-string (o)
            (%sgml-quote input o))
          (%sgml-quote input output))))

(defun sgml-quote-region (from to &optional unquotep)
  (interactive "*r\nP")
  (if unquotep
      (sgml-unquote-region from to)
      (ed::text-decode-region #'sgml-quote from to)))

(setf (symbol-function 'html-quote-region) #'sgml-quote-region)

;(require "htmlmode")
;(require "html+-mode")
;(define-key *html-mode-map* '(#\C-c #\C-q) 'sgml-quote)
;(define-key *html+-mode-map* '(#\C-c #\C-q) 'sgml-quote-region)

(defun unhtml (input &optional output)
  (format output "~A"
          (substitute-string
           (cond ((stringp input) input)
                 (t (with-output-to-string (s)
                      (echo input s))))
           "<[^>]*>" "")))

(defun unhtml-region (start end)
  "HTMLタグを除去する."
  (interactive "*r")
  #+xyzzy (ed::text-decode-region #'unhtml start end)
  #+emacs (save-excursion
            (save-restriction
              (narrow-to-region start end)
              (goto-char (point-min))
              (replace-buffer "<[^>]*>" "" :regexp t))))

