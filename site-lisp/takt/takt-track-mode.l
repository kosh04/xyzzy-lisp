;;; takt-track-mode.l -*- Package: editor -*-

;;; Code:

(eval-when (compile load eval)
  (require "takt"))

(in-package "editor")

(export '(takt-track-mode
          takt-track-update-buffer
          takt-show-track-summary
          *takt-track-mode-map*
          *takt-track-mode-hook*))

(defvar *takt-track-buffer* nil)

(defparameter *takt-track-mode-map*
  (let ((map (make-sparse-keymap)))
    ;;(define-key #\q 'exit)
    (define-key map #\C-l 'takt-track-update-buffer)
    map))

(defvar *takt-track-mode-hook* nil)

(defun takt-track-mode ()
  "Major mode of displaying track information and track muting status."
  (interactive)
  (kill-all-local-variables)
  (setq buffer-mode 'takt-track-mode
        mode-name "Takt Tracks")
  ;;(toggle-read-only t)
  (use-keymap *takt-track-mode-map*)
  (run-hooks '*takt-track-mode-hook*))

(defun takt-track-setup-buffer% ()
  (setq *takt-track-buffer* (get-buffer-create "*takt-track*"))
  (setup-temp-buffer *takt-track-buffer*)
  (erase-buffer *takt-track-buffer*)
  (save-excursion
    (set-buffer *takt-track-buffer*)
    (takt-track-mode)))

(defun takt-track-update-buffer ()
  (interactive)
  (takt-track-setup-buffer%)
  (with-output-to-buffer (*takt-track-buffer*)
    (format t "  Trk  Track/Sequence Name~%")
    (format t "= ===  ====================================================~%")
    (dolist (_name (sort (copy-seq takt::*track-names-alist*) #'< :key #'car))
      (let ((track (car _name))
            (name  (cdr _name)))
        (format t "~c ~3d  ~a~%"
                (if (find track #+TODO *muted-tracks* #-TODO nil) #\space #\P)
                track name)))
    #+nil (takt-put-play-marks)
    #+nil (takt-track-show-color-bars)
    ))

(defun takt-track-update-if-shown ()
  (when (and (bufferp *takt-track-buffer*)
             (not (deleted-buffer-p *takt-track-buffer*))
             (get-buffer-window *takt-track-buffer*))
    (takt-track-update-buffer)))

(defun takt-show-track-summary ()
  (interactive)
  (takt-track-update-buffer)
  (switch-to-buffer-other-window *takt-track-buffer*))

;;(add-hook '*delete-buffer-hook* 'takt-stop t)
