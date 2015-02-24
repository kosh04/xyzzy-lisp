;;; insert-pair.l

(provide "insert-pair")

;; Emacs����̈ڐA�Ȃ񂾂��A����arg���ĉ��Ɏg����
;; ����������΃A���R�����g�ɂ���ƕ֗����� (looking-at)
;; *last-command-char*
(defun insert-pair (&optional (arg 1) open close)
  "���[�W�����܂��͌��݂̃|�C���g�ʒu��OPEN/CLOSE�ň͂�."
  (interactive "*p")
  (cond ((null (and open close))
         (error 'simple-error))
        ((mark t)
         (save-excursion (goto-char (region-end)) (insert close))
         (save-excursion (goto-char (region-beginning)) (insert open))
         (set-mark t))
        ;; (arg (save-excursion (delete-backward-char (length open))) (save-excursion (delete-backward-char (length close))))
        (t
         (insert open close)
         (backward-char (length (string close))))))

(defun insert-parentheses (arg)
  (interactive "*P")
  (insert-pair arg #\( #\)))

(defun insert-double-quote (arg)
  (interactive "*P")
  (insert-pair arg #\" #\"))

(defun insert-backq (arg)
  (interactive "*P")
  (insert-pair arg "`" "'"))

(defun insert-lisp-comments (arg)
  (interactive "*P")
  (insert-pair arg "#|" "|#"))