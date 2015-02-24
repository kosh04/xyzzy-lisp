;;; -*- Mode: Lisp; Package: USER; Encoding: Shift_JIS -*-
;;;
;;; libmagic.l --- �t�@�C���^�C�v���ʃ��C�u����
;;;
;;; Copyright (C) 2009-2011  KOBAYASHI Shigeru
;;;
;;; This file is NOT part of xyzzy.

#|
����͉��H
==========

�o�C�g�񂩂�t�@�C���̎�ނ����ʂ��邽�߂̃��C�u�����ł��B
file(1) �R�}���h�� magic1.dll �𗘗p���Ă��܂��B


�C���X�g�[��
============

1. ���̃t�@�C���� xyzzy/site-lisp �ȉ��ɒu���B

1a. �K�v�Ȃ�΃o�C�g�R���p�C������B

2. GnuWin32 <http://gnuwin32.sourceforge.net/> ����
   File, Regex �̃o�C�i���������Ă��āA���L���C�u���� magic1.dll,
   regex2.dll �� �f�[�^�x�[�X�t�@�C�� magic.mgc �� xyzzy/etc �ȉ��ɒu���B

3. .xyzzy �Ɏ��̈�s��ǉ�����B

   (require "libmagic")


�g����
======

(magic-file "~/etc/magic1.dll")
;=> "PE32 executable for MS Windows (DLL) (console) Intel 80386 32-bit"

(magic-file "~/etc/magic1.dll" :mime-type t)
;=> "application/octet-stream"

(magic-buffer "Hello, World!")
;=> "ASCII text, with no line terminators"

(let ((*magic-flags* (+ MAGIC_MIME_TYPE MAGIC_MIME_ENCODING))
      ;; �ʂ�magic�f�[�^�x�[�X���g���Ă݂�
      ;; (�f�[�^�x�[�X�̃o�[�W�������قȂ�\������)
      (*magic-database-file* "C:/cygwin/usr/share/file/magic.mime"))
  (magic-buffer "#!/bin/sh\necho -n 'Hello, World!'\n"))
;=> "text/x-shellscript; charset=us-ascii"


���p��
======

(defun get-file-type (pathname)
  "�t�@�C���̎�ނ��X�e�[�^�X�o�[�ɕ\������."
  (interactive "fFile type" :default0 (get-buffer-file-name))
  (message "~A" (magic-file pathname)))

;; �t�@�C�����痘�p����
(defun filer-get-file-type ()
  (get-file-type (ed::filer-fetch-file nil nil)))
(define-key filer-keymap #\? 'filer-get-file-type)


Known bugs
==========

* MAGIC_COMPRESS ���w�肵�Ďg���� xyzzy ���Ɨ�����\������
  This compressed file format not implemented. # �����钼�O�̃G���[
  ���̂Ƃ���A�g���q "zip" �Ŋm�F
* magic_load �Ƀf�B���N�g���܂��͋󕶎�����w�肷��Ɩ������[�v
* ���݂��Ȃ��t�@�C���� magic_file �ɓn���ƁA"cannot open ~" ��
  �Ԃ��Ă��� (magic_error �ɃG���[���b�Z�[�W���Z�b�g����Ȃ�)

ChangeLog
=========

2009-*  first post
2011-09-28 chunk-get-string �̒l���������炵��
2012-05-21 ??? DLL�̃p�X���኱�C��

|#

;;; Code:


(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "foreign"))

(provide "libmagic")

(in-package "user")

(defvar *regex-dll* (merge-pathnames "bin/regex2.dll" (directory-namestring (or *load-pathname* "."))))
(defvar *magic-dll* (merge-pathnames "bin/magic1.dll" (directory-namestring (or *load-pathname* "."))))
(defvar *zlib-dll* (merge-pathnames "bin/zlib1.dll" (directory-namestring (or *load-pathname* "."))))

;; �ꉞ����Ȃ��œǂݍ���ł��g���邪
;; ���W���[���I�u�W�F�N�g��GC�����\��������
(defvar *regex-module* (si:load-dll-module (namestring *regex-dll*)))
(defvar *zlie-module* (si:load-dll-module (namestring *zlib-dll*)))

#|
#include <magic.h>

magic_t magic_open(int flags);
void magic_close(magic_t cookie);
const char * magic_error(magic_t cookie);
int magic_errno(magic_t cookie);
const char * magic_file(magic_t cookie, const char *filename);
const char * magic_buffer(magic_t cookie, const void *buffer, size_t length);
int magic_setflags(magic_t cookie, int flags);
int magic_check(magic_t cookie, const char *filename);
int magic_compile(magic_t cookie, const char *filename);
int magic_load(magic_t cookie, const char *filename);
|#

(c:*define-dll-entry c:int magic_open (c:int)
  *magic-dll* "magic_open")
(c:*define-dll-entry c:int magic_close (c:int)
  *magic-dll* "magic_close")
(c:*define-dll-entry c:char* magic_error (c:int)
  *magic-dll* "magic_error")
(c:*define-dll-entry c:int magic_errno (c:int)
 *magic-dll* "magic_errno")
(c:*define-dll-entry c:char* magic_file (c:int c:char*)
*magic-dll* "magic_file")
(c:*define-dll-entry c:char* magic_buffer (c:int c:void* c:size_t)
 *magic-dll* "magic_buffer")
(c:*define-dll-entry c:int magic_setflags (c:int c:int)
 *magic-dll* "magic_setflags")
(c:*define-dll-entry c:int magic_ckeck (c:int c:char*)
 *magic-dll* "magic_check")
(c:*define-dll-entry c:int magic_compile (c:int c:char*)
 *magic-dll* "magic_compile")
(c:*define-dll-entry c:int magic_load (c:int c:char*)
  *magic-dll* "magic_load")
(c:*define-dll-entry c:char* magic_discriptor (c:int c:int)
  *magic-dll* "magic_discriptor")

(c:*define MAGIC_NONE              #x000000)
(c:*define MAGIC_DEBUG             #x000001)
(c:*define MAGIC_SYMLINK           #x000002)
(c:*define MAGIC_COMPRESS          #x000004)
(c:*define MAGIC_DEVICES           #x000008)
(c:*define MAGIC_MIME_TYPE         #x000010)
(c:*define MAGIC_CONTINUE          #x000020)
(c:*define MAGIC_CHECK             #x000040)
(c:*define MAGIC_PRESERVE_ATIME    #x000080)
(c:*define MAGIC_RAW               #x000100)
(c:*define MAGIC_ERROR             #x000200)
(c:*define MAGIC_MIME_ENCODING     #x000400)
(c:*define MAGIC_MIME              (logior MAGIC_MIME_TYPE MAGIC_MIME_ENCODING))
(c:*define MAGIC_APPLE             #x000800)
(c:*define MAGIC_NO_CHECK_COMPRESS #x001000)
(c:*define MAGIC_NO_CHECK_TAR      #x002000)
(c:*define MAGIC_NO_CHECK_SOFT     #x004000)
(c:*define MAGIC_NO_CHECK_APPTYPE  #x008000)
(c:*define MAGIC_NO_CHECK_ELF      #x010000)
(c:*define MAGIC_NO_CHECK_TEXT     #x020000)
(c:*define MAGIC_NO_CHECK_CDF      #x040000)
(c:*define MAGIC_NO_CHECK_TOKENS   #x100000)
(c:*define MAGIC_NO_CHECK_ENCODING #x200000)

(c:*define MAGIC_NO_CHECK_ASCII    MAGIC_NO_CHECK_TEXT)

(c:*define MAGIC_NO_CHECK_FORTRAN  #x000000)
(c:*define MAGIC_NO_CHECK_TROFF    #x000000)

(c:*define NULL 0)


;;; Other Functions

;; FIXME: �`�����N�̃A�h���X�͂ǂ̂��炢�͈̔͂��K���H
(defun chunk-get-string (addr)
  ;; XXX: `addr'�̒l`616608'��(integer 1048576 *)�ł͂���܂���
;  (check-type addr (integer #x100000 *))
  (si:unpack-string (si:make-chunk nil 1024 nil addr) 0 nil t))

;; (c:*define-dll-entry c:char* strerror (c:int) "msvcrt.dll")
;; (c:*define-dll-entry c:void perror (c:char*) "msvcrt.dll")

;;; User Interface

(defvar *magic-database-file*
  (merge-pathnames "./bin/magic.mgc" (directory-namestring (or *load-pathname* ".")))
  "magic �f�[�^�x�[�X�t�@�C���̃p�X��.")

(defvar *magic-flags* nil
  "libmagic �ɓn���I�v�V�����t���O.")

(defmacro with-open-magic ((ms &optional flags) &body body)
  `(labels (($ (ptr)
              (if (= ptr NULL)
                  (error "~A" (chunk-get-string (magic_error ,ms)))
                  (chunk-get-string ptr))))
     ;; �����I�Ƀf�[�^�x�[�X�t�@�C�����w�肵�Ȃ��Ƃ��̋������͂߂Ȃ��̂�
     ;; xyzzy ���Ő��G���[��ł�.
     (unless (and *magic-database-file*
                  (file-exist-p *magic-database-file*)
                  (not (file-directory-p *magic-database-file*)))
       (error "could not find any magic files!"))
     (let ((,ms (magic_open (logior (or ,flags 0) MAGIC_NONE))))
       (if (= ,ms NULL)
           ;; FIXME: errno �̎擾���@�́H
           (error "magic_open: error occurred"))
       (unwind-protect
           (progn
             (if (= (magic_load ,ms (si:make-string-chunk
                                     (namestring *magic-database-file*)))
                    -1)
                 (error "~A" (chunk-get-string (magic_error ,ms))))
             ,@body)
         (if (/= ,ms NULL)
             (magic_close ,ms))))))
(setf (get 'with-open-magic 'ed:lisp-indent-hook) 1)

;;; ##autoload
(defun magic-file (filename &key mime-type mime-encoding)
  "determine file type."
  (setq filename (namestring filename))
  (unless (file-exist-p filename)
    (error "cannot open `~A' (No such file or directory)" filename))
  (with-open-magic (cookie (logior
                            (or *magic-flags* 0)
                            (if mime-type     MAGIC_MIME_TYPE 0)
                            (if mime-encoding MAGIC_MIME_ENCODING 0)
                            MAGIC_NONE))
    ($ (magic_file cookie (si:make-string-chunk filename)))))

;;; ##autoload
(defun magic-buffer (string)
  (with-open-magic (cookie *magic-flags*)
    ($ (magic_buffer cookie
                     (si:make-string-chunk string)
                     (length string)))))

;;; libmagic.l ends here