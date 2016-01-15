;;; xyttr.conf.l --- Twitter Client (M-x: xyttr)

(require "xyttr")
;(load "~/.xyttr/config.l")

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

;; �딚�h�~
(undefine-key xyttr::*xyttr-timeline-keymap* #\f)                       ; 'xyttr::toggle-favorite
(define-key xyttr::*xyttr-timeline-keymap* #\F 'xyttr::toggle-favorite) ; 'user::xyttr-favorites


#|
(defun xytty-open-link-in-browser ()
  (interactive)
  (let ((*open-url-by*
	 #'(lambda (url)
	     (shell-execute url t))))
    (declare (special *open-url-by*))
    (xyttr::open-link)))

|#