;;; conf.diff.l

(require "diff")

(setq ed::*diff-command-name* (namestring "~/bin/diff.exe")
      ed::*diff-command-option* "-awi")

(defun diff-same-name-buffer (buffer)
  "���O������2�̃o�b�t�@���r���܂�."
  (interactive "bDiff same buffer: ")
  (let* ((name (or (and (string-match "\\(.+\\)\\(<[0-9]+>\\)"
                                      #1=(buffer-name buffer))
                        (match-string 1))
                   #1#))
         (buflst (find-name-buffer name)))
    (if (second buflst)
        (diff (get-buffer-file-name (first buflst))
              (get-buffer-file-name (second buflst)))
      (plain-error "�����̃o�b�t�@������܂���: ~S" buffer))))

(defun diff-directory (new old)
  "�f�B���N�g�����r���܂�."
  (interactive "Ddiff(new dir): \nDdiff(old dir): ")
  (let ((*diff-command-option* "-rwuai"))
    (if (find-buffer #1="*diff directory*")
        (setup-temp-buffer #1#))
    (execute-shell-command (format nil "~a ~a \"~a\" \"~a\""
                                   (namestring *diff-command-name*)
                                   *diff-command-option*
                                   (remove-trail-slash old)
                                   (remove-trail-slash new))
                           nil #1#)))

;; http://www1.odn.ne.jp/ymtz/tips.html#diff
(defun filer-diff ()
  (interactive)
  (let ((new (ed::filer-fetch-file nil t))
        (old (ed::filer-fetch-file nil nil)))
    (unless (and new old)
      (error "��r����t�@�C�����w�肵�Ă�������"))
    (if (and (file-directory-p new)
             (file-directory-p old))
        (diff-directory old new)
        ;; ���ʂ�diff
        (diff new old))
    (filer-cancel)))

(define-key filer-keymap #\M-d 'filer-diff)