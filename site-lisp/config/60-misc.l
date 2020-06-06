;;; config/misc

(defun kill-whole-line (&optional (lines 1))
  "行末を含めた LINES 行を丸ごと kill します."
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
  "LINES 行を kill します.
カーソルが行頭にある場合は `kill-whole-line' と同じ動作をします."
  (interactive "*")
  (call-interactively
   (if (bolp) 'kill-whole-line 'kill-line)))

(global-set-key #\C-k 'kill-line*)
