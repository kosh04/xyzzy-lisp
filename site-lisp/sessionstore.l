;;; -*- Mode: Lisp; Package: Sessionstore -*-

;; 説明
;; ----
;; 通常プログラム終了時に作成される .xyzzy.resume.N を定期的に保存して
;; プログラムの異常終了が発生した場合でもセッションが復元できるようにする。
;; インスタンスの複数起動時や、複数のリジュームファイルには対応していない。

;; 使い方
;; ------
;; 1. このファイルを読み込む
;; 2. [共通＞さまざま＞終了時の状態を保存する] にチェックを入れる

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
  ;; ed::save-history-file が同名のリジューム用ファイルを用意するため、こちらは削除しておく
  (when *save-resume-info*
    (delete-file *session-file* :if-does-not-exist :skip)))

(add-hook '*save-history-hook* 'cleanup)
