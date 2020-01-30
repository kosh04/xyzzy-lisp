;;; -*- Mode: Lisp; Package: EDITOR; Encoding: UTF-8 -*-
;;;
;;; This file is NOT part of xyzzy.
;;;

(provide "view-minor-mode")

(in-package "editor")

(export '(*view-minor-mode-hook*
          *view-minor-mode-map*
          view-minor-mode))

(defvar-local view-minor-mode nil)

(defvar *view-minor-mode-hook* nil)

(defvar *view-minor-mode-map*
  (let ((m (make-sparse-keymap)))
    (define-key m #\SPC 'next-page)
    (define-key m #\C-h 'previous-page)
    (define-key m #\q 'kill-selected-buffer)
    m))

(defun view-minor-mode (&optional (arg nil sv))
  (interactive "p")
  (toggle-mode 'view-minor-mode arg sv)
  (if view-minor-mode
      (set-minor-mode-map *view-minor-mode-map*)
    (unset-minor-mode-map *view-minor-mode-map*))
  (update-mode-line t)
  (run-hooks '*view-minor-mode-hook*))

(pushnew '(view-minor-mode . "View") *minor-mode-alist* :key #'car)

(defun toggle-read-only (&optional (arg nil sv))
  "バッファの読み取り専用モードを切り替えます.
オンの場合は追加で簡易閲覧モードが有効になります."
  (interactive "p")
  (ed::toggle-mode 'buffer-read-only arg sv)
  (view-minor-mode buffer-read-only))
