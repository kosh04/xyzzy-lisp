;;; xyttr.conf.l --- Twitter Client (M-x: xyttr)

(require "xyttr")
;(load "~/.xyttr/config.l")

;; �딚�h�~�̂���
(let ((map xyttr::*xyttr-timeline-keymap*))
  (undefine-key map #\f)                       ; 'xyttr::toggle-favorite
  (define-key map #\F 'xyttr::toggle-favorite) ; 'user::xyttr-favorites
  nil)

(defun xyttr-user-profile (&optional username)
  "���[�U�̃v���t�B�[����\�����܂�."
  (interactive)
  (let ((url (concat "http://twitter.com/" (or username (xyttr::focused-user)))))
    (shell-execute url t)))

(defun xyttr-status ()
  "�Ԃ₫�̏ڍׂ�\�����܂�."
  (interactive)
  (shell-execute (xyttr::status-url) t))

(define-key xyttr:*xyttr-timeline-keymap* #\SPC 'next-page)
(define-key xyttr:*xyttr-timeline-keymap* #\F22 'previous-page)
(define-key xyttr:*xyttr-timeline-keymap* #\O 'xyttr-status)
(define-key xyttr:*xyttr-timeline-keymap* #\P 'xyttr-user-profile)

#|
(defun xytty-open-link-in-browser ()
  (interactive)
  (let ((*open-url-by*
	 #'(lambda (url)
	     (shell-execute url t))))
    (declare (special *open-url-by*))
    (xyttr::open-link)))

|#