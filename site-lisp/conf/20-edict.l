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
(define-key spec-map #\r 'lookup-reading)

;; PDIC
;; ê›íËÉÅÉÇ - http://mux03.panda64.net/diary/20110412.html
;(require "pdic")
;; FIXME: ìÆçÏämîF (2015-02-25)
;(setq *pdic-path* "C:/Program Files/PDIC_Unicode/PDICU.EXE")
(defun pdic-lookup (word)
  (interactive "sPDIC: ")
  (let ((ans (pdic-dde-comunicate word)))
    (if ans (popup-string ans (point)))))
