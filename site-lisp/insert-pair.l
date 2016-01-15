;;; insert-pair.l

(provide "insert-pair")

;; Emacsからの移植なんだが、引数argって何に使うんだ
;; 引数があればアンコメントにすると便利そう (looking-at)
;; *last-command-char*
(defun insert-pair (&optional (arg 1) open close)
  "リージョンまたは現在のポイント位置をOPEN/CLOSEで囲む."
  (interactive "*p")
  (cond ((null (and open close))
         (error 'simple-error))
        ((mark t)
         (save-excursion (goto-char (region-beginning)) (insert open))
         (save-excursion (goto-char (region-end))       (insert close))
         (set-mark t))
        #+nil
        (arg
         (save-excursion (delete-backward-char (length open)))
         (save-excursion (delete-backward-char (length close))))
        ;; skip closed string
        ((and (syntax-string-p open)
              (syntax-string-p close)
              (eq (parse-point-syntax) :string)
              (eq (following-char) close))
         (forward-char arg))
        (t
         (insert open  arg)
         (insert close arg)
         ;;(let ((*last-command-char* open))  (self-insert-command arg))
         ;;(let ((*last-command-char* close)) (self-insert-command arg))
         (backward-char arg)))
  t)

(defun insert-parentheses (&optional (arg 1))
  (interactive "*p")
  (insert-pair arg #\( #\)))

(defun insert-double-quote (&optional (arg 1))
  (interactive "*p")
  (insert-pair arg #\" #\"))

(defun insert-backq (&optional (arg 1))
  (interactive "*p")
  (insert-pair arg #\` #\'))

(defun insert-lisp-comments (&optional (arg 1))
  (interactive "*p")
  (insert-pair arg "#|" "|#"))
