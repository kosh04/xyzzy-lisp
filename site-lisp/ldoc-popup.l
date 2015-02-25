;;; ldoc-popup.l

;; funsig‚Ì‘ã‚í‚è‚Æ‚µ‚Äg‚¦‚é‚Ì‚©‚Ç‚¤‚©‚Í•ª‚©‚ç‚È‚¢

(defun arglist-symbol->string (x)
  (cond ((consp x) (mapcar #'arglist-symbol->string x))
        ((member x lambda-list-keywords) (symbol-name x))
        ((stringp x) x)
        (t (string-upcase (prin1-to-string x)))))
;; (arglist-symbol->string (arglist 'reduce))
;; ("FUNCTION" "SEQUENCE" "&key" "FROM-END" ("START" "0") "END" ("INITIAL-VALUE" "NIL" "SV"))

;; http://xyzzy.s53.xrea.com/wiki/index.php?patch%2F28
;; ldoc2‚Å(in-package :editor) ‚È‚Ç‚à’T‚·‚æ‚¤‚É‚·‚é
(defun find-in-package ()
  "Find current package"
  (let ((goal-column (goal-column)))
    (unwind-protect
        (save-excursion
          (and (scan-buffer "^(in-package[ \t\n]" :regexp t :reverse t)
               (find-package (second
                              (read-from-string
                               (buffer-substring (point)
                                                 (progn
                                                   (goto-matched-parenthesis)
                                                   (1+ (point))))
                               nil nil)))))
      (set-goal-column goal-column))))

(defun ldoc-popup ()
  (interactive)
  (let* ((from (save-excursion
                 (while (eq (parse-point-syntax) :string)
                   (backward-char))
                 (up-list -1 t)
                 (forward-char)
                 (point)))
         (to (save-excursion (goto-char from) (forward-sexp 1 t) (point)))
         (symbol nil))
    ;; (if (= from to) (return-from eldoc))
    (multiple-value-bind (name package)
        (values-list (reverse (split-string (buffer-substring from to) ":")))
      ;; (msgbox "~S" (list name package))
      (setq symbol (ignore-errors
                    (find-symbol name (or package
                                          (find-package *buffer-package*)
                                          (find-in-package)
                                          *package*))))
      (if (fboundp symbol)
          (let ((args (arglist-symbol->string (arglist symbol))))
            (popup-string (format nil (cond ((stringp args) "(~S ~A)")
                                            ((consp args) "(~S ~{~A~^ ~})"))
                                  symbol args)
                          (point)))
          (message "ŠÖ”‚ªŒ©‚Â‚©‚è‚Ü‚¹‚ñ: ~A" (substitute #\SPC #\LFD name))))))

(define-key ed::*lisp-mode-map* #\C-\; 'ldoc-popup)
(define-key ed::*lisp-interaction-mode-map* #\C-\; 'ldoc-popup)
