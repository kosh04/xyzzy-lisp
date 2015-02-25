;;; conf.winapi.l --- WIN32API

(require "wip/winapi")
(require "api")

;; �R���̂������Ńp�b�P�[�W�����ȗ��ł��邱�Ƃ�Y��Ȃ�����
(use-package "winapi")

;; ���L
(defun hwnd () (get-window-handle))
;; (setf (symbol-function 'hWndMain) #'get-window-handle)
(si:*fset 'TEXT #'si:make-string-chunk)
(c:*define NULL 0)

;; wip/winapi.l �Œ�`�ς�
;; (c:define-dll-entry winapi:BOOL ShowWindow (winapi:HWND c:int) "user32")

(defun iconify-xyzzy (&optional (hwnd (get-window-handle)))
  "�N������ xyzzy ���ŏ������܂�."
  (interactive)
  (ShowWindow hwnd SW_MINIMIZE)) ; 6

(global-set-key '(#\C-x #\C-c) 'iconify-xyzzy)
(global-set-key #\M-F4 'kill-xyzzy) ; Windows������

;; http://hie.s64.xrea.com/xyzzy/note/buffer.html#maximize-xyzzy
(c:*define-dll-entry winapi:BOOL IsZoomed (winapi:HWND) "user32")

(defun maximize-xyzzy ()
  (interactive)
  (ShowWindow (get-window-handle) SW_MAXIMIZE)) ; 3

(defun restore-xyzzy ()
  "���̃T�C�Y�ɖ߂�."
  (interactive)
  (ShowWindow (get-window-handle) SW_RESTORE)) ; 9

(defun toggle-xyzzy-window ()
  (interactive)
  (if (zerop (IsZoomed (get-window-handle)))
      (maximize-xyzzy)
      (restore-xyzzy)))

(global-set-key #\M-F10 'toggle-xyzzy-window)

;; ��O�ɕ\�� #'toggle-topmost-xyzzy
(require "topmost")
(add-hook '*post-startup-hook* 'ed::topmost-uninstall)
(defun add-menu-topmost ()
  (let ((window-menu (get-menu *app-menu* 'ed:window)))
    (add-menu-separator window-menu)
    (add-menu-item window-menu 'ed:window "��Ɏ�O�ɕ\�� (&T)"
                   'toggle-topmost-xyzzy
                   #'(lambda () (and (topmost-xyzzy-p) :check)))))
(add-hook '*init-app-menus-hook* 'add-menu-topmost)

(require "winamp")
(defun winamp-now-playing ()
  (interactive)
  (message "~A" (winamp::get-title-playing)))