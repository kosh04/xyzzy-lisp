;;; -*- Mode: Lisp; Package: USER -*-
;;;
;;; ls-l.l --- 指定したディレクトリ以下のファイル一覧を表示
;;;
;;; This file is NOT part of xyzzy.
;;;

;; Author: KOBAYASHI Shigeru (kosh)
;; Created: 2011-01-06

(provide "ls-l")

(in-package "user")

;;; TODO:

;; ## 出力形式
;; `dir` 形式 (windows)
;; `ls -l` 形式 (unix)
;; アーカイブもバッファで扱いたい

;; ## ソート
;; ディレクトリは先頭に置くべきか、ファイルと一緒にすべきか
;; 少なくとも "." ".." は常に先頭
;; 名前順、サイズ順、更新日時順、拡張子順

;; ## Bugs
;; ? (get-file-info "C:/") -> 指定されたファイルが見つかりません。

(defun ls-l-attribute-to-string (attr)
  "attrib /? 参照"
  (concat
   (if (zerop (logand attr ed::*file-attribute-directory*))  "-" "D") ; ディレクトリ
   (if (zerop (logand attr ed::*file-attribute-readonly*))   "-" "R") ; 読み取り専用
   (if (zerop (logand attr ed::*file-attribute-archive*))    "-" "A") ; アーカイブ
   (if (zerop (logand attr ed::*file-attribute-hidden*))     "-" "H") ; 隠しファイル
   (if (zerop (logand attr ed::*file-attribute-system*))     "-" "S") ; システムファイル
   (if (zerop (logand attr ed::*file-attribute-compressed*)) "-" "C") ; 圧縮?
   ))

;; "%y/%m/%d %H:%M:%S"
(defvar *ls-l-date-format* "%y/%m/%d(%a) %H:%M:%S")

(defun ls-l-decode-file-info (info)
  (let ((filename (pop info)))
    (multiple-value-bind (attr mtime size short-name)
        (values-list info)
      (list (ls-l-attribute-to-string attr)
            size
            (format-date-string *ls-l-date-format* mtime)
            (if (file-directory-p filename)
                filename
              (remove-trail-slash filename))))))

(defun ls-l-buffer-name (dir)
  (format nil "<DIR> ~A" (car (last (ed:split-string dir "/")))))

;;;###autoload
(defun ls-l (&optional (dir (default-directory)))
  (interactive "DList directory: ")
  (let ((dirname (ls-l-buffer-name dir))
        (dirs-info (directory dir :show-dots t :file-info t :directory-only t))
        (files-info (directory dir :show-dots nil :file-info t :file-only t)))
    (save-window-excursion
      (with-output-to-temp-buffer (dirname)
        (set-default-directory dir)
        ;; 表示するディレクトリ
        (format t "~2T~A:" dir) (set-text-attribute (point-min) (point-max) 'dir :foreground 4)
        (format t "~%")
        (format t (concat
                   "~2TAttrib" "~10TSize(Bytes)" "~22TLast Modified" "~47TName~%"))
        ;; ディレクトリ
        (format t #1=(concat
                      "~:{"
                      "~2T~A"  "~10T~A"          "~22T~A"            "~47T~A~%"
                      "~}")
                (mapcar #'ls-l-decode-file-info dirs-info))
        ;; ファイル
        (format t #1#
                ;; (directory ... :file-info t)
                ;; => (0:filename 1:attr 2:last-modified-time 3:size 4:short-name)
                (mapcar #'ls-l-decode-file-info
                        ;; (sort (copy-seq files-info) #'string<= :key #'first) ; 名前順
                        ;; (sort (copy-seq files-info) #'>= :key #'fourth)      ; サイズ順
                        ;; (sort (copy-seq files-info) #'(lambda (x y) (string<= (pathname-type x) (pathname-type y))) :key #'first) ; 種類順(拡張子順)
                        ;; (sort (copy-seq files-info) #'>= :key #'third) ; 更新日時順
                        files-info
                        ))
        (toggle-read-only t)))
    (switch-to-buffer dirname)
    (view-mode)
    (message "~D director~:@P, ~D file~:P"
             (length dirs-info) (length files-info))))

(setf (symbol-function 'dired) #'ls-l)

(defun ls-l-other-window ()
  (interactive)
  (display-buffer
   (save-window-excursion
     (call-interactively #'ls-l)
     (selected-buffer))))

#|
(format t "~:{~A    ~A  ~A ~A~%~}"
        (mapcar #'ls-l-decode-file-info
                (directory "." :file-info t)))
|#

;; 中途半端
(defun archiver-mode (file)
  (interactive "fArchive: ")
  (let ((filename (file-namestring file))
        (dirname (directory-namestring file)))
    (save-window-excursion
      (with-output-to-temp-buffer (filename)
        (set-default-directory dirname)
        (format t (concat
                   "~2TAttrib" "~10TSize(Bytes)" "~22TLast Modified" "~47TName~%"))
        (format t #1=(concat
                      "~:{"
                      "~2T~A"  "~10T~A"          "~22T~A"            "~47T~A~%"
                      "~}")
                (mapcar #'(lambda (info)
                            ;; attr size mtime name
                            (list (nth 1 info)
                                  (nth 2 info)
                                  (apply #'format
                                         nil "~d/~2,'0d/~2,'0d ~2,'0d:~2,'0d"
                                         (nth 3 info))
                                  (nth 0 info)))
                        (list-archive file)))
        (toggle-read-only t)))
    (switch-to-buffer filename))
  t)

;; (list-archive "~/src/nkf-2.1.0.tar.gz")
;; (("nkf-2.1.0/" "----" 0 (2009 11 17 9 33 4)) ("nkf-2.1.0/nkf_test.pl" "----" 45377 (2009 11 17 9 33 4)) ("nkf-2.1.0/make_test.pl" "----" 582 (2009 11 17 9 33 4)) ("nkf-2.1.0/nkf.doc" "----" 15215 (2009 11 17 9 33 4)) ("nkf-2.1.0/utf8tbl.h" "----" 2093 (2009 11 17 9 33 4)) ("nkf-2.1.0/MANIFEST" "----" 306 (2009 11 17 9 33 4)) ("nkf-2.1.0/INSTALL.j" "----" 634 (2009 11 17 9 33 4)) ("nkf-2.1.0/nkf32.c" "----" 17 (2009 11 17 9 33 4)) ("nkf-2.1.0/test.pl" "----" 3015 (2009 11 17 9 33 4)) ("nkf-2.1.0/Makefile" "----" 1555 (2009 11 17 9 33 4)) ("nkf-2.1.0/nkf.c" "----" 158753 (2009 11 17 9 33 4)) ("nkf-2.1.0/dll.rc" "----" 883 (2009 11 17 9 33 4)) ("nkf-2.1.0/nkf.1j" "----" 24270 (2009 11 17 9 33 4)) ("nkf-2.1.0/INSTALL" "----" 525 (2009 11 17 9 33 4)) ("nkf-2.1.0/nkf.1" "----" 14603 (2009 11 17 9 33 4)) ("nkf-2.1.0/nkf32.h" "----" 3940 (2009 11 17 9 33 4)) ("nkf-2.1.0/utf8tbl.c" "----" 501062 (2009 11 17 9 33 4)) ("nkf-2.1.0/nkf32dll.c" "----" 27520 (2009 11 17 9 33 4)) ("nkf-2.1.0/NKF.mod/" "----" 0 (2009 11 17 9 33 4)) ("nkf-2.1.0/nkf.h" "----" 4412 (2009 11 17 9 33 4)) ("nkf-2.1.0/nkf.mak" "----" 965 (2009 11 17 9 33 4)) ("nkf-2.1.0/version.rc" "----" 835 (2009 11 17 9 33 4)) ("nkf-2.1.0/dll.def" "----" 454 (2009 11 17 9 33 4)) ("nkf-2.1.0/config.h" "----" 1066 (2009 11 17 9 33 4)) ("nkf-2.1.0/NKF.mod/MANIFEST" "----" 51 (2009 11 17 9 33 4)) ("nkf-2.1.0/NKF.mod/NKF.pm" "----" 9455 (2009 11 17 9 33 4)) ("nkf-2.1.0/NKF.mod/NKF.xs" "----" 5207 (2009 11 17 9 33 4)) ("nkf-2.1.0/NKF.mod/Makefile.PL" "----" 482 (2009 11 17 9 33 4)) ("nkf-2.1.0/NKF.mod/Changes" "----" 115 (2009 11 17 9 33 4)) ("nkf-2.1.0/NKF.mod/README" "----" 834 (2009 11 17 9 33 4)) ("nkf-2.1.0/NKF.mod/test.pl" "----" 3315 (2009 11 17 9 33 4)))

;; EOF
