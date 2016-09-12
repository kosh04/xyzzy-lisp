;;; 20-menu.l

;; ���j���[�ɃN���[�Y�{�b�N�X (ChangeLog Version 0.2.1.180)
(defun add-menu-close-box ()
  (add-menu-item *app-menu* 'close-box :close-box #'kill-selected-buffer))

(add-hook '*init-app-menus-hook* 'add-menu-close-box)

;; ��Ɏ�O�ɕ\�� (M-x: toggle-topmost-xyzzy)
(require "topmost")
;(add-hook '*post-startup-hook* 'ed::topmost-uninstall)
(defun add-menu-topmost ()
  (let ((window-menu (get-menu *app-menu* 'ed:window)))
    (add-menu-separator window-menu)
    (add-menu-item window-menu 'ed:window "��Ɏ�O�ɕ\�� (&T)"
                   'toggle-topmost-xyzzy
                   #'(lambda () (and (topmost-xyzzy-p) :check)))))

(add-hook '*init-app-menus-hook* 'add-menu-topmost)

(defun add-menu-user-init ()
  (let ((edit-menu (get-menu *app-menu* 'ed::edit)))
    ;; �ҏW�������݋֎~
    (add-menu-separator edit-menu)
    (add-menu-item edit-menu nil "�����݋֎~(&%)" 'toggle-read-only
                   #'(lambda () (when buffer-read-only :check)))
    ;; �ҏW���^�u�C���f���g���[�h
    (add-menu-separator edit-menu)
    (add-menu-item edit-menu nil
                   "�^�u�C���f���g���[�h(&T)"
                   #'(lambda (&optional (arg nil sv))
                       (interactive)
                       (ed::toggle-mode 'indent-tabs-mode arg sv))
                   #'(lambda ()
                       (when indent-tabs-mode :check)))))

(add-hook '*init-app-menus-hook* 'add-menu-user-init)

;; ���j���[���當���R�[�h�w�肵�� #'revert-buffer
;; �t�@�C���Ɋ֘A�t�����Ă��Ȃ��o�b�t�@���ƃG���[�ɂȂ�͎̂d�l
;; xyzzy Part7 >>804
(defun add-menu-revert ()
  (let ((file-menu (get-menu *app-menu* 'ed::file)))
    (insert-popup-menu file-menu 8
                       (make-char-encoding-popup-menu
                        #'revert-buffer
                        #'(lambda (e) (and (eq (buffer-fileio-encoding) e) :check)))
                       "�J������(&?)")
    (insert-menu-separator file-menu 8)))

(add-hook '*init-app-menus-hook* 'add-menu-revert)