;;; 20-menu.l

;; メニューにクローズボックス (ChangeLog Version 0.2.1.180)
(defun add-menu-close-box ()
  (add-menu-item *app-menu* 'close-box :close-box #'kill-selected-buffer))

(add-hook '*init-app-menus-hook* 'add-menu-close-box)

;; 常に手前に表示 (M-x: toggle-topmost-xyzzy)
(require "topmost")
;(add-hook '*post-startup-hook* 'ed::topmost-uninstall)
(defun add-menu-topmost ()
  (let ((window-menu (get-menu *app-menu* 'ed:window)))
    (add-menu-separator window-menu)
    (add-menu-item window-menu 'ed:window "常に手前に表示 (&T)"
                   'toggle-topmost-xyzzy
                   #'(lambda () (and (topmost-xyzzy-p) :check)))))

(add-hook '*init-app-menus-hook* 'add-menu-topmost)

(defun add-menu-user-init ()
  (let ((edit-menu (get-menu *app-menu* 'ed::edit)))
    ;; 編集＞書込み禁止
    (add-menu-separator edit-menu)
    (add-menu-item edit-menu nil "書込み禁止(&%)" 'toggle-read-only
                   #'(lambda () (when buffer-read-only :check)))
    ;; 編集＞タブインデントモード
    (add-menu-separator edit-menu)
    (add-menu-item edit-menu nil
                   "タブインデントモード(&T)"
                   #'(lambda (&optional (arg nil sv))
                       (interactive)
                       (ed::toggle-mode 'indent-tabs-mode arg sv))
                   #'(lambda ()
                       (when indent-tabs-mode :check)))))

(add-hook '*init-app-menus-hook* 'add-menu-user-init)

;; メニューから文字コード指定して #'revert-buffer
;; ファイルに関連付けられていないバッファだとエラーになるのは仕様
;; xyzzy Part7 >>804
(defun add-menu-revert ()
  (let ((file-menu (get-menu *app-menu* 'ed::file)))
    (insert-popup-menu file-menu 8
                       (make-char-encoding-popup-menu
                        #'revert-buffer
                        #'(lambda (e) (and (eq (buffer-fileio-encoding) e) :check)))
                       "開き直す(&?)")
    (insert-menu-separator file-menu 8)))

(add-hook '*init-app-menus-hook* 'add-menu-revert)
