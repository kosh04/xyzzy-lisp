;;; conf.edict.l --- é´èëä÷òA

(defun popup-edict (lookup-function)
  (let ((msg (save-window-excursion
               (prog2
                   (funcall lookup-function)
                   (buffer-substring (point-min) (point-max) #1="*dictionary*")
                 (delete-buffer #1#)))))
    (setq msg (string-trim "\n" msg))
    (popup-string msg (point))))

(defun lookup-current-word ()
  (interactive)
  (popup-edict #'(lambda ()
                   (if (kanji-char-p (following-char))
                       (lookup-j2e-dictionary-selection)
                       (lookup-e2j-dictionary-selection)))))

(defun lookup-reading ()
  (interactive)
  (popup-edict #'lookup-reading-dictionary-selection))

(define-key spec-map #\e 'lookup-current-word)
(define-key spec-map #\r #'lookup-reading)
