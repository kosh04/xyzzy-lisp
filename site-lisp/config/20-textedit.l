;; conf.textedit.l --- �e�L�X�g�ҏW�n�̐ݒ�

;; ���ʂ̋����\��
(require "paren")
(setq-default *paren-highlight-only-paren* t)
(setq-default *paren-show-not-visible-matched-paren* nil) ; �Ή����銇�ʂ������Ȃ��ꍇ
(setq-default *paren-paren-attribute* '(t t :background 6))
(setf (symbol-function 'show-paren-mode) #'toggle-paren)
(global-set-key '(#\C-x #\t #\p) 'toggle-paren)
(turn-on-global-paren)
;; (add-hook '*post-startup-hook* 'turn-on-global-paren)

;; ���[�W�����̔��]�\��
;; ;; http://hie.s64.xrea.com/xyzzy/mylib/rv-region.html
(require "rv-region")
(setq *rv-region-stay-on* t)

;; fill.l
(setq-default fill-column 72)   ; 72 84
(defun turn-on-auto-fill ()
  "auto-fill-mode �� on �ɂ��܂�."
  (auto-fill-mode t))
;(add-hook '*text-mode-hook* 'turn-on-auto-fill)

;; �t�@�C���Ƀ^�C���X�^���v��t��
(require "auto-time-stamp")
(setq *time-stamp-start* "Time-stamp:[ \t]+\\\\?[\"<]+"
      *time-stamp-end* "\\\\?[\">]")
(setq *time-stamp-format* "%Y-%m-%dT%H:%M:%S%#Z")
(add-hook '*before-save-buffer-hook*
          (defun time-stamp-maybe ()
            ;;(undo-boundary)
            (if *time-stamp-active* (ed::time-stamp))
            nil))

(defun delete-trailing-whitespace ()
  "�s���̋�s���폜����."
  (interactive "*")
  (let* ((m (mark t))
         (from (if m (region-beginning) (point-min)))
         (to (if m (region-end) (point-max))))
    (save-restriction
      (narrow-to-region from to)
      (save-excursion
        (goto-char (point-min))
        (replace-buffer "[ \t]+$" "" :regexp t)
        ;; (perform-replace "[ \t]+$" "" nil t nil t)
        ;; (replace-regexp "[ \t]+$" "")
        ;; (delete-trailing-spaces)
        ))
    (and m (set-mark t))))

(setf (symbol-function 'trim-trailing-whitespace) #'delete-trailing-whitespace)

;; narrow
(defun narrow-to-defun ()
  "Make text outside current defun invisible."
  (interactive)
  (save-excursion
    (widen)
    (narrow-to-region (progn (beginning-of-defun) (point))
                      (progn (end-of-defun)       (point)))))

(global-set-key '(#\C-x #\n #\d) 'narrow-to-defun)
;; emacskey.l �ɂĒ�`�ς�
;; (global-set-key '(#\C-x #\n #\n) 'narrow-to-region)
;; (global-set-key '(#\C-x #\n #\w) 'widen)


(require "insert-pair")
(global-set-key #\( 'insert-parentheses)
(global-set-key #\" 'insert-double-quote)
;(global-set-key #\M-\` 'insert-backq)
(global-set-key #\M-# 'insert-lisp-comments)


;; Markdown
(require "markdown")
(pushnew '("\\.md\\'" . markdown-mode) *auto-mode-alist* :test #'equal)
;(pushnew '(markdown-mode nil "<!-- " " -->") comment-mode-alist :test #'equal)

(defun markdown-region (from to &optional view-browser)
  (interactive "r\nP")
  (when (and (need-buffer-save-p (selected-buffer))
             (yes-no-or-cancel-p "�o�b�t�@���ύX����Ă��܂��B�ۑ����܂���?"))
    (save-buffer))
  (let ((buffer (selected-buffer))
        (encoding (buffer-fileio-encoding)))
    (with-output-to-temp-buffer ("*markdown output*")
      (html-mode)
      (insert-buffer-substring buffer from to)
      (change-fileio-encoding encoding)
      (filter-buffer "markdown")
      (when view-browser
        (let ((tmpfile (make-temp-file-name "md" "html")))
          (unwind-protect
              (progn
                (write-file tmpfile)
                (shell-execute tmpfile t))
            ;; markdown-mode.el �ł̓t�@�C���������Ȃ��悤�ɂȂ��Ă��邪...
            (sit-for 0.5)
            (and (file-exist-p tmpfile)
                 (delete-file tmpfile :if-does-not-exist :skip))))))))

(defun markdown-buffer (&optional view-browser)
  (interactive "P")
  (markdown-region (point-min) (point-max) view-browser))

(setf (symbol-function 'markdown) #'markdown-buffer)

;; LaTeX.l
(require "LaTeX.l")
(defun LaTeX-user-hook ()
  (interactive)
  (setq comment-start "% "
        comment-end ""
        comment-start-skip "%+[ \t]*"
        comment-indent-function #'c-comment-indent))
(add-hook 'ed::*LaTeX-mode-hook* 'LaTeX-user-hook)

;(require "changelogmemo/main")
;(setq *cl-config-file-alist* '(("changelogmemo" . "~/cl/config.l")))
;(add-hook '*post-startup-hook* 'cl-start)
;(setq cl::*cl-user* "KOBAYASHI Shigeru  <shigeru@YOUR-D1BE424ADF>")
;(global-set-key '(#\C-x #\4 #\a) 'cl::add-memo-buffer)

(require "changelog")
(setq add-log-full-name (user-name))
(setq change-log-default-name (merge-pathnames "Documents/ChangeLog" (si:getenv "HOMEPATH")))
(global-set-key '(#\C-x #\4 #\a) 'add-change-log-entry)

;; Fundamental ���[�h�ł����ʂ̐F�t��
(defun add-paren-syntax ()
  (let ((syntab (syntax-table)))
    (set-syntax-match syntab #\( #\))
    (set-syntax-match syntab #\[ #\])
    (set-syntax-match syntab #\{ #\})
    ;; �����ĂȂ��H
    (set-syntax-match syntab #\�i #\�j)
    (set-syntax-match syntab #\�u #\�v)
    (set-syntax-match syntab #\�y #\�z)
    (set-syntax-match syntab #\�w #\�x)
    ))
(add-hook '*fundamental-mode-hook* 'add-paren-syntax)
(add-hook '*text-mode-hook* 'add-paren-syntax)
