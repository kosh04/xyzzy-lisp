;;; config/filer

;; ファイラ関係

;; ゴミはゴミ箱へ
(setq *filer-use-recycle-bin* t)

;; デフォルトのファイルマスク
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
       (cons "VirtualStore" (merge-pathnames "VirtualStore" (si:getenv "LOCALAPPDATA")))
       (cons "TEMP" (or (si:getenv "TEMP")
			(si:getenv "TMP")))

       (cons "Documents" (merge-pathnames "Documents" (si:getenv "USERPROFILE")))
       (cons "Pictures"  (merge-pathnames "Pictures" (si:getenv "USERPROFILE")))
       (cons "Videos"    (merge-pathnames "Videos" (si:getenv "USERPROFILE")))
       (cons "Music"     (merge-pathnames "Music" (si:getenv "USERPROFILE")))
       (cons "Downloads" (merge-pathnames "Downloads" (si:getenv "USERPROFILE")))

       (cons "スタートメニュー" (get-special-folder-location :start-menu))
       (cons "SendTo" (get-special-folder-location :send-to))
       (cons "最近使ったファイル" (get-special-folder-location :recent))
       (cons "Startup" (get-special-folder-location :startup))
       ;;"shell:appsFolder"
       ))

(defun user/filer-add-env-directories ()
  "ディレクトリを指す環境変数をショートカットに追加する."
  (loop for (name . path) in (sort (si:environ) #'string< :key #'car)
    if (and (< (length path) 256)
            (file-directory-p path)
            (not (find name *filer-directories* :key #'car :test #'equalp)))
    do
    ;;(pushnew (cons name path) *filer-directories* :test #'equal)
    ;; append tail
    (setq *filer-directories* (append *filer-directories* (list (cons (format nil "%~a%" name) path))))
    ))

(add-hook '*post-startup-hook* 'user/filer-add-env-directories)

(defun open-filer* ()
  "バッファの作業ディレクトリでファイラを開きます."
  (interactive)
  (let ((*filer-primary-directory* nil))
    (open-filer)))

(defun run-console* ()
  (interactive)
  (let ((ed::*launch-app-directory*
	 (ignore-errors (filer-get-directory))))
    (run-console)))

(defun open-explorer ()
  "現在のディレクトリをエクスプローラで開く."
  (interactive)
  (shell-execute (or (ignore-errors (filer-get-directory))
                     (default-directory))))

(defun filer-delete-backups ()
  "バックアップファイルをまとめて削除する."
  (dolist (mask *filer-delete-mask-list*)
    (filer-mark-match-files (cdr mask)))
  (message "~D backup file~:P marked." (filer-count-marks))
  (if (/= (filer-count-marks) 0)
      (filer-delete)))

;; 共有フォルダをファイラから扱う
;; http://xyzzy.s53.xrea.com/wiki/index.php?cmd=read&page=tips%2F%A5%D5%A5%A1%A5%A4%A5%E9%A4%C7%B6%A6%CD%AD%A5%D5%A5%A9%A5%EB%A5%C0%A4%F2%C1%AA%C2%F2
(require "filer-servers")


(defun filer-transpose-window ()
  "ファイラの左右画面を交換します."
  (interactive)
  (when (filer-dual-window-p)
    (let ((x (filer-get-directory nil))
          (y (filer-get-directory t)))
      (and (filer-set-directory y nil)
           (filer-reload nil nil))
      (and (filer-set-directory x t)
           (filer-reload nil t)))
    t))

;; *filer-follow-links* が non-nil なら勝手にショートカット
;; (ディレクトリ限定) を展開してくれるみたい
(defun filer-chdir->link ()
  "リンク先のディレクトリを開く"
  (interactive)
  (filer-chdir (directory-namestring
                (ed::filer-read-link
                 (filer-get-current-file)))))
(define-key filer-keymap #\C-j 'filer-chdir->link)

;; 「進む」も作りたいが...
(defun filer-backward-directory ()
  "「戻る」"
  (interactive)
  (tagbody
    #1=continue
    (pop ed::*filer-directory-history*)
    (cond ((null ed::*filer-directory-history*)
           (error "これ以上戻れません"))
          ((not (file-exist-p (nth 0 ed::*filer-directory-history*)))
           (go #1#))))
  (filer-set-directory (nth 0 ed::*filer-directory-history*))
  (filer-reload)
  (message "Next Back: ~A" (nth 1 ed::*filer-directory-history*)))
(define-key filer-keymap #\C-b 'filer-backward-directory)

(defun filer-open-dual-window ()
  "一画面ファイラから二画面ファイラを開く."
  (interactive)
  (unless (filer-dual-window-p)
    (let ((*filer-primary-directory* (filer-get-directory)))
      (filer-close nil)
      (open-filer))))

;; http://goo.gl/WSlOd - tips/.lnkを展開する
(defparameter *find-file-follow-link* t
  "non-nilならばファイルを開く際にショートカットを展開します.")

(defun find-file-follow-link (file)
  "tips/.linkを展開する - XyzzyWikiより"
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

;; (define-key filer-keymap #\n 'filer-forward-line)
;; (define-key filer-keymap #\p 'filer-backward-line)
