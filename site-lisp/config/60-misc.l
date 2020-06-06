;;; config/misc

(defun kill-whole-line (&optional (lines 1))
  "�s�����܂߂� LINES �s���ۂ��� kill ���܂�."
  (interactive "*p")
  (let ((from (progn
                (goto-bol)
                (point)))
        (to (progn
              (if (minusp lines)
                  (backward-line (- lines))
                (or (forward-line lines) (goto-eol)))
              (point))))
    (kill-region from to)))

(defun kill-line* ()
  "LINES �s�� kill ���܂�.
�J�[�\�����s���ɂ���ꍇ�� `kill-whole-line' �Ɠ�����������܂�."
  (interactive "*")
  (call-interactively
   (if (bolp) 'kill-whole-line 'kill-line)))

(global-set-key #\C-k 'kill-line*)