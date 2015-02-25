;;; conf.filer.l

;; �t�@�C���֌W

;; �S�~�̓S�~����
(setq *filer-use-recycle-bin* t)

;; �f�t�H���g�̃t�@�C���}�X�N
(setq *filer-primary-file-mask*   '("*")
      *filer-secondary-file-mask* '("*")
      *filer-last-file-mask*      '("*"))

(setq *filer-mark-file-size-unit* #\M)

#+nil
(setq *filer-guide-text*
      '("(A)ttribute (B)yteCompile (C)opy (D)elete (E)xtract (F)ind (G)o <I>DeleteMask (J)ump m(K)dir (L)ogicalDrive (M)ove file(N)ame"
        "c(O)mpress <P>sync1 <Q>uit (R)ename (S)ync2 toDesk(T)op (U)sage listArchi(V)e vie(W)er e(X)ecute <Y>Shortcut <Z>Property"
        "<*>load <.>SetMask </>MarkMask <\\>Root (<)Top (>)Bottom (=)Compare (@)CopyAs (])SendTo (^)Eject (End)Reload"
        "<C-s/r>isearch <M-g>grep <M-r>Gresreg <M-v>view <F3>Exec <F5>ToggleMarkFiles <F6>Sort"))

(setq *filer-directories*
      (list
       (cons "XYZZYHOME" (or (si:getenv "XYZZYHOME")
                             (si:system-root)))
       (cons "Backup" (namestring *backup-directory*))
       (cons "HOME" (or (si:getenv "USERPROFILE")
			(si:getenv "HOME")
			(si:getenv "HOMEPATH")))
       (cons "Cygwin" "C:/cygwin/")
       (cons "Desktop" (get-special-folder-location :desktop))
       (cons "ProgramFiles" (or (si:getenv "ProgramFiles")
				(si:getenv "ProgramFiles(x86)")))
       (cons "SystemRoot" (or (si:getenv "SystemRoot")
			      (get-system-directory)))
       (cons "APPDATA" (si:getenv "APPDATA"))
       (cons "LOCALAPPDATA" (si:getenv "LOCALAPPDATA"))
       (cons "TEMP" (or (si:getenv "TEMP")
			(si:getenv "TMP")))

       (cons "Documents" (merge-pathnames "Documents" (si:getenv "USERPROFILE")))
       (cons "Pictures"  (merge-pathnames "Pictures" (si:getenv "USERPROFILE")))
       (cons "Videos"    (merge-pathnames "Videos" (si:getenv "USERPROFILE")))
       (cons "Music"     (merge-pathnames "Music" (si:getenv "USERPROFILE")))
       (cons "Downloads" (merge-pathnames "Downloads" (si:getenv "USERPROFILE")))

       (cons "�X�^�[�g���j���[" (get-special-folder-location :start-menu))
       (cons "SendTo" (get-special-folder-location :send-to))
       (cons "�ŋߎg�����t�@�C��" (get-special-folder-location :recent))
       (cons "Startup" (get-special-folder-location :startup))
       ))

;; �f�B���N�g�����w�����ϐ����V���[�g�J�b�g�ɒǉ�
(dolist (e (sort (si:environ) #'string< :key #'car))
  (multiple-value-bind (name path)
      (values (car e) (cdr e))
    (when (and (< (length path) 256)
               (file-directory-p path))
      ;;(pushnew (cons name path) *filer-directories* :test #'equal)
      (or (find name *filer-directories* :test #'equal)
          ;; append tail
          (setq *filer-directories* (append *filer-directories* (list (cons name path)))))
      )))

(defun open-filer* ()
  "�o�b�t�@�̍�ƃf�B���N�g���Ńt�@�C�����J���܂�."
  (interactive)
  (let ((*filer-primary-directory* nil))
    (open-filer)))

(defun run-console* ()
  (interactive)
  (let ((ed::*launch-app-directory*
	 (ignore-errors (filer-get-directory))))
    (run-console)))

(defun open-explorer ()
  "���݂̃f�B���N�g�����G�N�X�v���[���ŊJ��."
  (interactive)
  (shell-execute (or (ignore-errors (filer-get-directory))
                     (default-directory))))

(defun filer-delete-backups ()
  "�o�b�N�A�b�v�t�@�C�����܂Ƃ߂č폜����."
  (dolist (mask *filer-delete-mask-list*)
    (filer-mark-match-files (cdr mask)))
  (message "~D backup file~:P marked." (filer-count-marks))
  (if (/= (filer-count-marks) 0)
      (filer-delete)))

;; ���L�t�H���_���t�@�C�����爵��
;; http://xyzzy.s53.xrea.com/wiki/index.php?cmd=read&page=tips%2F%A5%D5%A5%A1%A5%A4%A5%E9%A4%C7%B6%A6%CD%AD%A5%D5%A5%A9%A5%EB%A5%C0%A4%F2%C1%AA%C2%F2
(require "filer-servers")


(defun filer-transpose-window ()
  "�t�@�C���̍��E��ʂ��������܂�."
  (interactive)
  (when (filer-dual-window-p)
    (let ((x (filer-get-directory nil))
          (y (filer-get-directory t)))
      (and (filer-set-directory y nil)
           (filer-reload nil nil))
      (and (filer-set-directory x t)
           (filer-reload nil t)))
    t))

;; *filer-follow-links* �� non-nil �Ȃ珟��ɃV���[�g�J�b�g
;; (�f�B���N�g������) ��W�J���Ă����݂���
(defun filer-chdir->link ()
  "�����N��̃f�B���N�g�����J��"
  (interactive)
  (filer-chdir (directory-namestring
                (ed::filer-read-link
                 (filer-get-current-file)))))
(define-key filer-keymap #\C-j 'filer-chdir->link)

;; �u�i�ށv����肽����...
(defun filer-backward-directory ()
  "�u�߂�v"
  (interactive)
  (tagbody
    #1=continue
    (pop ed::*filer-directory-history*)
    (cond ((null ed::*filer-directory-history*)
           (error "����ȏ�߂�܂���"))
          ((not (file-exist-p (nth 0 ed::*filer-directory-history*)))
           (go #1#))))
  (filer-set-directory (nth 0 ed::*filer-directory-history*))
  (filer-reload)
  (message "Next Back: ~A" (nth 1 ed::*filer-directory-history*)))
(define-key filer-keymap #\C-b 'filer-backward-directory)

(defun filer-open-dual-window ()
  "���ʃt�@�C��������ʃt�@�C�����J��."
  (interactive)
  (unless (filer-dual-window-p)
    (let ((*filer-primary-directory* (filer-get-directory)))
      (filer-close nil)
      (open-filer))))

;; http://goo.gl/WSlOd - tips/.lnk��W�J����
(defparameter *find-file-follow-link* t
  "non-nil�Ȃ�΃t�@�C�����J���ۂɃV���[�g�J�b�g��W�J���܂�.")

(defun find-file-follow-link (file)
  "tips/.link��W�J���� - XyzzyWiki���"
  (if *find-file-follow-link*
      (let ((sh (ignore-errors
                 (resolve-shortcut file))))
        (when sh
          (find-file sh)
          (get-file-buffer sh)))))

(add-hook '*before-find-file-hook* 'find-file-follow-link)

;; keymap
(global-set-key '(#\C-c #\C-f) 'open-filer*)
(define-key filer-keymap #\C-c 'run-console*)
(define-key filer-keymap #\C-e 'open-explorer)
(define-key filer-keymap #\C-t 'filer-transpose-window)
(define-key filer-keymap #\M-2 'filer-open-dual-window)
(define-key filer-keymap #\C-u 'filer-up-directory)
(define-key filer-keymap #\G 'filer-reload)
(define-key filer-keymap #\~ 'filer-delete-backups)
(define-key filer-keymap #\F2 'filer-rename)
(define-key filer-keymap #\Delete #'filer-delete)
(define-key filer-keymap #\M-g 'grep-dialog)