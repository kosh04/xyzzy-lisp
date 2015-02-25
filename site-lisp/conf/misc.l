;; conf.misc.l --- �G���Ȑݒ�

;; nil�Ȃ�AJIS X0208�ɑ��݂��镶����Unicode��������R�[�h�ɕϊ�����ہA
;; ���{��̕����Ƃ��Ĉ��� (ChangeLog Version 0.2.2.205)
;; �f�t�H���g�� t
(setq *unicode-to-half-width* nil)

;; transient-mark-mode ���ǂ�
(defun keyboard-quit ()
  (interactive)
  (set-mark t)                  ; �}�[�N���N���A (ChangeLog Version 0.1.0.107)
  (error 'quit))

(global-set-key #\C-g 'keyboard-quit)

;(require "my-dired")
(require "ls-l")
(global-set-key '(#\C-x #\d) 'ls-l)
(global-set-key '(#\C-x #\4 #\d) 'ls-l-other-window)

(set-extended-key-translate-table exkey-S-space #\F22) ; XXX
(defun insert-space (&optional (n 1))
  (interactive "p")
  (dotimes (_ n)
    (insert #\SPC)))
(global-set-key #\F22 #'insert-space)
;(define-key *isearch-map* #\F22 #'isearch-self-insert)

;; timestmp.l
;; http://hie.s64.xrea.com/xyzzy/note/edit.html#insert-date
;; http://neta.ywcafe.net/000851.html
;; (add-date-format "%Y-%m-%dT%H:%M:%S%#Z") ; �W��?
;; (add-date-format "%Y-%m-%d(%a) %H:%M:%S %Z")
(defun insert-date (&optional self)
  (interactive "p")
  (cond (self (insert-date-string))
        (:else (insert (format-date-string "%Y-%m-%dT%H:%M:%S%#Z")))))
(global-set-key '(#\C-c #\t) 'insert-date)

;; XTAGS (tags.l)
(setf (symbol-function 'find-tag) #'direct-tag-jump)

;; calc.l
(setq ed::*calc-ratio* 'float)

;; KaMail
;; ���[����Gmail�𗘗p����̂Ŋ�{�I��xyzzy���痘�p���Ȃ�
;(require "kamail/config")

;; �~�j�o�b�t�@���ŒP��폜
;; http://white.s151.xrea.com/wiki/index.php?memo%2Fxyzzy%2Fminibuffer#w95b8c17
;; http://xyzzy.s53.xrea.com/wiki/index.php?tips%2F%A5%DF%A5%CB%A5%D0%A5%C3%A5%D5%A5%A1%A4%C7%A4%D2%A4%C8%A4%C4%BE%E5%A4%CE%A5%C7%A5%A3%A5%EC%A5%AF%A5%C8%A5%EA%A4%D8
(defun delete-word (&optional (arg 1))
  "*kill-ring*�ɒǉ����Ȃ��P��폜"
  (interactive "*p")
  (delete-region (point) (progn (forward-word arg) (point))))

(defun backward-delete-word (&optional (arg 1))
  (interactive "*p")
  (delete-word (- arg)))

(dolist (keymap (list minibuffer-local-completion-map
                      minibuffer-local-must-match-map
                      minibuffer-local-command-line-map
                      minibuffer-local-map))
  (define-key keymap #\C-w 'backward-delete-word))

;; �t�@�C�����̂Ȃ��o�b�t�@�ł� save-buffer �̃G���[���}�C���h��
(defun no-filenames-error ()
  (plain-error "�t�@�C����������܂���"))

(add-hook '*save-buffer-no-filenames-hook* 'no-filenames-error)

(defun just-one-space+ ()
  (interactive "*")
  ;; ���s���܂Ƃ߂č폜����
  (delete-region (progn (skip-chars-backward " \t\n") (point))
		 (progn (skip-chars-forward " \t\n") (point)))
  (insert #\SPC))

(global-set-key '(#\ESC #\SPC) 'just-one-space+)

;; ** delete-indentation [M-^] �ł�����x��p�ł��邩�� (2012-10-11)
;; (global-set-key '(#\ESC #\SPC) 'delete-indentation)

;; ���j���[�o�[��[�o�b�t�@(B)]��ǉ�����
(require "menubar")

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

(add-hook '*post-startup-hook* 'add-menu-user-init)

;; Blowfish
(require "blowfish/readme_l")

;; �s�R�J�L�R�p
(pushnew '("\\.fml$" . c-mode) *auto-mode-alist* :test #'equal)
;; (global-set-key #\F11 'winamp::Stop-button)
;; (global-set-key #\F12 'winamp::Play-track)
(defun mml-play-file (file)
  (interactive
      (list (read-exist-file-name "MML: " :default (get-buffer-file-name))))
  (shell-execute "C:/Program Files/Winamp/winamp.exe" nil file))

(require "re-builder")