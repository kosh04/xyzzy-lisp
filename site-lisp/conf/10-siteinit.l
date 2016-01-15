;;; -*- Mode: Lisp; Package: USER -*-
;;;
;;; This file is NOT part of xyzzy.
;;;

;; xyzzy_-q �ł��g����悤��
;; �K�v�Œ���̐ݒ�ƕW�����C�u�����̃��[�h���s��

(provide "siteinit")

;; �X�e�[�^�X�o�[�ɐF�X�\��
(setq *status-bar-format* "cuT")

;; IME�̏�Ԃ����[�h���C����Emacs����
(setq mode-line-format "[%i] --%*- %b (%M) [%k:%l] %P %f")

;; �i�C�X�A���h�D (non-nil �Ȃ� undo ��̃J�[�\���ʒu�͍폜�͈̖͂���)
(setq *move-forward-after-undo-deletion* t)

;; �p������o�b�t�@�̃t�@�C�������~�j�o�b�t�@�ɕ\�� (C-x C-v)
(setq *find-other-file-requires-file-name* t)


;; transient-mark-mode ���ǂ�
(defun keyboard-quit ()
  (interactive)
  (set-mark t)                  ; �}�[�N���N���A (ChangeLog Version 0.1.0.107)
  (error 'quit))
(global-set-key #\C-g 'keyboard-quit)

;; �⊮�\�����Ȃ��g���q
(pushnew ".elc" ignored-extensions :test #'equal)
(pushnew ".o" ignored-extensions :test #'equal)

;; �c�[���o�[�̕\�������܂ɂ��������Ȃ�̂�
;; http://lisperblog.blogspot.com/2010/01/xyzzy.html
(defun load-command-bar-info-if-xyzzy-q ()
  (let ((cl (car si:*command-line-args*)))
    (when (or (equal cl "-q")
              (equal cl "-no-init-file"))
      (ed::load-command-bar-info))))

;(add-hook '*pre-startup-hook* #'load-command-bar-info-if-xyzzy-q)

;; �O�����C�u����

;; xyzzyWiki �� reference.xml(->txt) �𗘗p���� Help ��֗���
(require "ref2doc")
(reference-to-docstring)

;; �N���b�J�u�� URI
(require "clickable-uri")
(global-set-key '(#\C-c #\C-o) 'clickable-uri-open)
(defun goto-next-url ()
  (interactive)
  (scan-buffer ed::*clickable-uri-regexp* :regexp t :no-dup t))

;; �^�u���E�N���b�N�����Ƃ��̃��j���[�g��
(require "tabmenu")

;; eof