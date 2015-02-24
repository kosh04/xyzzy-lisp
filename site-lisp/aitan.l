;;; -*- Mode: Lisp; Encoding: Shift_JIS -*-
;;;
;;; This file is NOT part of xyzzy.

;;; http://xyzzy.s53.xrea.com/wiki/index.php?trash%2Faitan.l
;;; 2ch��Emacs�X��part16�ɏo������aitan��xyzzy�ɘA��Ă��܂����B
;;; ���Ђ܂ȕ��͂ǂ����B

(provide "aitan")

(in-package "user")

(defun aitan()
  "aitan ���킢���� aitan"
  (interactive)
  (split-window (- (window-height) 5))
  (set-window (next-window (selected-window)))
  (set-buffer (get-buffer-create "*aitan*")) ; �o�b�t�@���� ** ��ǉ�
  (make-local-variable 'need-not-save)
  (setq need-not-save t)
  (erase-buffer (selected-buffer))
  (let ((lngth 20) (cnt (float 0)))
    (beginning-of-line)
    (insert " �Z�Q�Z\n")
    (insert "( �(�)�)�")(insert "��\"")
    (while t
      (setq cnt (float 0))
      (while (< cnt lngth)
	(beginning-of-line)(forward-char 9)(insert "�\")
	(sit-for (calcwait cnt lngth))(setq cnt (1+ cnt)))
      (while (> cnt 0)
	(beginning-of-line)(forward-char 9)(delete-char 1)
	(sit-for (calcwait cnt lngth))(setq cnt (1- cnt)))
      (sit-for 0.2))))

(defun calcwait (cnt lngth)
  ;; setq �� let �ɕύX������ v �͊O���ϐ��Ƃ��Ďc���Ă��܂�...
  ;; �C�̂�����?
  (let ((v (/ (+ (sin (* (/ (float cnt) (float lngth)) 3.14))
		 (sin (* (/ (+ (float cnt) 1) (float lngth)) 3.14))) 2)))
    (/ (round (* (abs (/ 1.0 v)) 6)) 1000)))

;; �����܂���������܂���c