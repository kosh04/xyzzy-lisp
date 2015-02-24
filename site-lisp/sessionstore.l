;;; -*- Mode: Lisp; Package: Sessionstore -*-

;; ����
;; ----
;; �ʏ�v���O�����I�����ɍ쐬����� .xyzzy.resume.N �����I�ɕۑ�����
;; �v���O�����ُ̈�I�������������ꍇ�ł��Z�b�V�����������ł���悤�ɂ���B
;; �C���X�^���X�̕����N������A�����̃��W���[���t�@�C���ɂ͑Ή����Ă��Ȃ��B

;; �g����
;; ------
;; 1. ���̃t�@�C����ǂݍ���
;; 2. [���ʁ����܂��܁��I�����̏�Ԃ�ۑ�����] �Ƀ`�F�b�N������

;; Author:: KOBAYASHI Shigeru (kosh)
;; Created: 2014-07-09

(provide "sessionstore")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "history")
  (require "session"))

(defpackage "sessionstore"
  (:use "lisp" "editor"))

(in-package "sessionstore")

(defvar *session-file*
  (let ((base (ed::resume-file-name-base))
        (x 0))
    (merge-pathnames (format nil "~a~a" base x) (user-config-path))))

(defun autosave (&rest arg)
  (declare (ignore args))
  (let ((ed::*auto-save-session-file* t)
        (ed::*current-session-file-name* *session-file*))
    (ed::auto-save-session-file))
  t)

(add-hook '*find-file-hooks* 'autosave)
(add-hook '*delete-buffer-hook* 'autosave)

(defun cleanup ()
  ;; ed::save-history-file �������̃��W���[���p�t�@�C����p�ӂ��邽�߁A������͍폜���Ă���
  (when *save-resume-info*
    (delete-file *session-file* :if-does-not-exist :skip)))

(add-hook '*save-history-hook* 'cleanup)