;;; -*- Mode: Lisp; Package: USER; Encoding: Shift_JIS -*-

;;; libmagic.l --- マジックナンバー識別ライブラリのラッパー

;; This file is NOT part of xyzzy.

;; Copyright (C) 2009 KOBAYASHI Shigeru

#|
インストール
============

1. このファイルを xyzzy/site-lisp 以下に置く。

2. GnuWin32 <http://gnuwin32.sourceforge.net/> から
   File, Regex のバイナリを持ってきて、ライブラリファイル magic1.dll,
   regex2.dll と データベースファイル magic.mgc を xyzzy/etc 以下に置く。

3. .xyzzy に次の一行を追加する。

   (require "libmagic")

使い方
======

(magic-file "~/etc/magic1.dll")
;=> "PE32 executable for MS Windows (DLL) (console) Intel 80386 32-bit"

(magic-file "~/etc/magic1.dll" :mime-type t)
;=> "application/octet-stream"

(magic-buffer "Hello, World!")
;=> "ASCII text, with no line terminators"

(let ((*magic-flags* (+ MAGIC_MIME_TYPE MAGIC_MIME_ENCODING))
      (*magic-database-file* "C:/cygwin/usr/share/file/magic.mime"))
  (magic-buffer "#!/bin/sh\necho -n 'Hello, World!'\n"))
;=> "text/x-shellscript; charset=us-ascii"

Known bugs
==========

* MAGIC_COMPRESS を指定して使うと xyzzy ごと落ちる可能性あり
* magic_load にディレクトリまたは空文字列を指定すると無限ループ
* 存在しないファイルを magic_file に渡すと、"cannot open ~" が
  返ってくる (magic_error にエラーメッセージがセットされない)

|#

;;; Code:


(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "foreign"))

(provide "libmagic")

(in-package "user")

(defvar *regex-dll* (merge-pathnames "regex2.dll" (etc-path)))

(eval-when (:load-toplevel :execute)
  ;; 一応代入なしで読み込んでも使えるが
  ;; モジュールオブジェクトがGCされる可能性がある
  (setq regex-module (si:load-dll-module *regex-dll*)))

(defvar *magic-dll* (merge-pathnames "magic1.dll" (etc-path)))

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

;; FIXME: チャンクのアドレスはどのくらいの範囲が適当？
(defun chunk-get-string (addr)
  (check-type addr (integer #x0300000 *))
  (si:unpack-string (si:make-chunk nil 1024 nil addr) 0 nil t))


;;; User Interface

(defvar *magic-database-file* (merge-pathnames "magic.mgc" (etc-path))
  "magic データベースファイルのパス名.")

(defvar *magic-flags* nil
  "libmagic に渡すオプションフラグ.")

(defmacro with-open-magic ((ms &optional flags) &body body)
  `(labels (($ (ptr)
              (if (= ptr NULL)
                  (error "~A" (chunk-get-string (magic_error ,ms)))
                  (chunk-get-string ptr))))
     ;; 明示的にデータベースファイルを指定しないときの挙動が掴めないので
     ;; xyzzy 側で先手エラーを打つ.
     (unless (and *magic-database-file*
                  (file-exist-p *magic-database-file*)
                  (not (file-directory-p *magic-database-file*)))
       (error "could not find any magic files!"))
     (let ((,ms (magic_open (logior ,flags MAGIC_NONE))))
       (if (= ,ms NULL)
           ;; FIXME: errno の取得方法は？
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
