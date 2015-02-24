;;; -*- Mode: Lisp; Package: EDITOR; Encoding: Shift_JIS -*-
;;;
;;; cmacexp.l --- expand C macros in a region
;;;
;;; This file is NOT part of xyzzy.
;;;

;; Copyright (C) 1992, 1994, 1996, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008
;; Free Software Foundation, Inc.

;; Author: Francesco Potorti` <pot@gnu.org>
;; Adapted-By: ESR
;; Keywords: C

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; USAGE =============================================================

;; In C mode C-C C-e is bound to c-macro-expand.  The result of the
;; expansion is put in a separate buffer.  A user option allows the
;; window displaying the buffer to be optimally sized.
;;
;; When called with a C-u prefix, c-macro-expand replaces the selected
;; region with the expansion.  Both the preprocessor name and the
;; initial flag can be set by the user.  If c-macro-prompt-flag is set
;; to a non-nil value the user is offered to change the options to the
;; preprocessor each time c-macro-expand is invoked.  Preprocessor
;; arguments default to the last ones entered.  If c-macro-prompt-flag
;; is nil, one must use M-x set-variable to set a different value for
;; c-macro-cppflags.

;; A c-macro-expansion function is provided for non-interactive use.

;; INSTALLATION ======================================================

;; Put the following in your ~/.emacs file.

;; If you want the *Macroexpansion* window to be not higher than
;; necessary:
;;(setq c-macro-shrink-window-flag t)
;;
;; If you use a preprocessor other than /lib/cpp (be careful to set a
;; -C option or equivalent in order to make the preprocessor not to
;; strip the comments):
;;(setq c-macro-preprocessor "gpp -C")
;;
;; If you often use a particular set of flags:
;;(setq c-macro-cppflags "-I /usr/include/local -DDEBUG"
;;
;; If you want the "Preprocessor arguments: " prompt:
;;(setq c-macro-prompt-flag t)

;; BUG REPORTS =======================================================

;; Please report bugs, suggestions, complaints and so on to
;; pot@gnu.org (Francesco Potorti`).

;; IMPROVEMENTS OVER emacs 18.xx cmacexp.el ==========================

;; - A lot of user and programmer visible changes.  See above.
;; - #line directives are inserted, so __LINE__ and __FILE__ are
;;   correctly expanded.  Works even with START inside a string, a
;;   comment or a region #ifdef'd away by cpp. cpp is invoked with -C,
;;   making comments visible in the expansion.
;; - All work is done in core memory, no need for temporary files.

;; ACKNOWLEDGEMENTS ==================================================

;; A lot of thanks to Don Maszle who did a great work of testing, bug
;; reporting and suggestion of new features.  This work has been
;; partially inspired by Don Maszle and Jonathan Segal's.

;; BUGS ==============================================================

;; If the start point of the region is inside a macro definition the
;; macro expansion is often inaccurate.


#|
### これはなに？

Cプリプロセッサを利用してプログラムの指定した範囲のマクロを展開
してくれるEmacsのライブラリ(cmacexp.el)をxyzzyに移植したものです。
(移植とはいっても内部のコードはほとんど別物ですが…)

### インストール

1. $XYZZYHOME/site-lisp 以下にこのファイルを置く
2. 必要ならばバイトコンパイル
3. .xyzzy(またはsiteinit.l)に以下を記述する

(require "cmacexp")
(define-key ed::*c-mode-map* '(#\C-c #\C-e) 'c-macro-expand-region)
(define-key ed::*c++-mode-map* '(#\C-c #\C-e) 'c-macro-expand-region)

### 使い方

 FUNCTION c-macro-expand-region (start end &optional subst)

   指定した範囲のマクロを展開して別ウィンドウに表示します。[C-c C-e]
   前置引数(C-u)を付けると指定した範囲をマクロ展開したものに置換します。
  
### Known Bugs

* プリプロセッサの入出力に使う一時ファイルが削除されない場合がある
* (setq *cppcommand* "c:/MinGW/bin/cpp.exe -C") にて以下の警告が出る
  cc1.exe: warning:  is shorter than expected

### Change Log

2010-02-08 移植開始
2010-04-19 見た目かなり別物になったが、それなりに動くようになった

;;; by KOBAYASHI Sigeru (kosh) <shigeru.kb@gmail.com>
|#

;;; Code:

(provide "cmacexp")

(in-package "editor")

(export '(*cppcommand*
          c-macro-expand-region))

#|
(defun buffer-disable-undo (&optional buffer)
  (save-excursion
    (set-buffer buffer)
    (setq kept-undo-information nil)))
|#

(defun barf-if-buffer-read-only ()
  "Signal a `buffer-read-only' error if the current buffer is read-only."
  (if buffer-read-only
      (error "書込み禁止バッファです")))

(defmacro with-temp-file ((temp-file &rest args) &body body)
  `(let ((,temp-file ,(apply #'make-temp-file-name args)))
     (unwind-protect
         (progn ,@body)
       (delete-file ,temp-file :if-does-not-exist :error :if-access-denied :error))))
;(setf (get 'with-temp-file 'ed:lisp-indent-hook) 1)

(defun call-process-region (start end program
                                  &optional delete buffer display
                                  &rest args)
  "Send text from START to END to a synchronous process running PROGRAM.
The remaining arguments are optional.
Delete the text if fourth arg DELETE is non-nil."
  (barf-if-buffer-read-only)
  (let (errfile)
    (when (listp buffer)
      (setq errfile (nth 1 buffer))
      (setq buffer  (nth 0 buffer)))
    (with-temp-file (infile "xyzin")
      (write-region start end infile)
      (with-temp-file (outfile "xyzout")
        (prog1
            (call-process (format nil "~A ~{~A~^ ~}" program args)
                          :input infile :output outfile
                          :error errfile
                          :show :minimize :wait t)
          (if delete (delete-region start end))
          ;; nil for BUFFER means discard it;
          (when buffer
            (save-excursion
              (set-buffer (if (eq buffer t)
                              (selected-buffer)
                            buffer))
              (insert-file-contents outfile)))
          (if display
              (switch-to-buffer (if (eq buffer t) (selected-buffer) buffer))))))
    ))

(defvar *cppcommand*
  (if (some #'(lambda (dir)
                (path-equal dir "C:\\MinGW\\bin"))
            (split-string (si:getenv "PATH") ";"))
      "cpp -C"
    "gcc -E -C -"))

;;;###autoload
(defun c-macro-expand-region (start end &optional substp)
  "Expand C macros in the region, using the C preprocessor."
  (interactive "r\nP")
  (or (< start end) (rotatef start end))
  (when (and substp buffer-read-only)
    (message "Buffer is read only: displaying expansion in alternate window")
    (setq substp nil))
  (let ((inbuf (selected-buffer))
        (outbuf (get-buffer-create #1=" *C Macro Expansion*"))
        (filename (if (file-visited-p)
                      (file-namestring (get-buffer-file-name))
                    (buffer-name (selected-buffer))))
        (uniquestring "??? !!! ??? start of c-macro expansion ??? !!! ???")
        (startline (save-excursion
                     (goto-char start)
                     (current-line-number)))
        exit-status)
    (save-excursion
      (set-buffer outbuf)
      (setup-temp-buffer (selected-buffer))
      (erase-buffer (selected-buffer))
      (c-mode)

      (insert-buffer-substring inbuf 0 start)
      (insert "\n"
              uniquestring "\n"
              (format nil "#line ~d \"~a\"\n" startline filename))
      (insert-buffer-substring inbuf start end)
      (insert "\n")             ; supply "warning: no newline at end of file"

      (with-temp-file (errfile "cpperr")
        (setq exit-status
              (call-process-region (point-min) (point-max) *shell*
                                   t `(t ,errfile) nil "/c" *cppcommand*))
        (goto-char (point-min))
        (or (search-forward uniquestring t)
            (error "プリプロセッサが削除する部分かもです"))
        (next-line 2)           ; ignore lines `uniquestring' and `# nn "file.c"'
        (delete-region 0 (point))

        ;; CPP error occured
        (when (and (or (= exit-status 0)
                       (/= (file-length errfile) 0))
                   (not substp))
          (goto-char (point-min))
          ;; Put the messages inside a comment
          (insert
           (format nil (concat
                        "/* Preprocessor terminated with status ~A\n\n"
                        "   Messages from `~A\':\n\n")
                   exit-status *cppcommand*))
          (forward-char (nth 2 (multiple-value-list
                                (insert-file-contents errfile))))
          (insert "\n*/\n")) ))
    (if substp
        (prog2
            (delete-region start end)
            (insert-buffer-substring #1# (point-min) (point-max))
          (delete-buffer #1#))
      (display-buffer outbuf))))

;; (define-key ed::*c-mode-map* '(#\C-c #\C-e) 'c-macro-expand-region)
;; (define-key ed::*c++-mode-map* '(#\C-c #\C-e) 'c-macro-expand-region)

;;; cmacexp.l ends here
