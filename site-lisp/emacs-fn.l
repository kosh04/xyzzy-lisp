;;; -*- Mode: Lisp; Package: User; Encoding: Shift_JIS -*-
;;;
;;; This file is NOT part of xyzzy.
;;; 

;;; Emacs Lisp 移植キットとは別に自前で定義したもの

(provide "emacs-fn")

(in-package "user")

(eval-when (compile load eval)
  (require "shell"))

;; $EMACS/lisp/comint.el
;; (point) が EOF ならプロセス終了
(defun comit-delchar-or-maybe-eof (&optional arg)
  "Delete ARG characters forward or send an EOF to subprocess.
Sends an EOF only if point is at the end of the buffer and there is no input."
  (interactive "p")
  (let ((proc (buffer-process (selected-buffer))))
    (if (and (eobp)
             proc
             (eq (process-status proc) :run)
             (eql (point) (marker-point (process-marker proc))))
        ;; (process-send-string proc (concat "exit" *shell-ret*))
        (kill-process proc)
      (delete-char arg))))

;; slime.el:slime-repl-bol
(defun ed::shell-goto-bol ()
  (interactive)
  (let ((point-at-bol (save-excursion (goto-bol) (point)))
        (marker (ignore-errors
                 (marker-point
                  (process-marker (buffer-process (selected-buffer)))))))
    (if (and marker (<= point-at-bol marker (point)))
        (goto-char marker)
        (goto-bol))))

;; $EMACS/lisp/simple.el
(defun emacs-delete-blank-lines ()
  "On blank line, delete all surrounding blank lines, leaving just one.
On isolated blank line, delete that one.
On nonblank line, delete any immediately following blank lines."
  (interactive "*")
  (let* ((thisblank (save-excursion
                      (beginning-of-line)
                      (looking-at "[ \t]*$")))
         ;; Set singleblank if there is just one blank line here.
         (singleblank (and thisblank
                           (not (looking-at "[ \t]*\n[ \t]*$"))
                           (or (bobp)
                               (progn
                                 (forward-line -1)
                                 (not (looking-at "[ \t]*$")))))))
    (when thisblank
      (beginning-of-line)
      (if singleblank (forward-line 1))
      (delete-region (point)
                     (if (re-search-backward "[^ \t\n]" 'noerror)
                         (progn (forward-line 1) (point))
                         (point-min))))
    ;; Delete following blank lines, unless the current line is blank
    ;; and there are no following blank lines.
    (unless (and thisblank singleblank)
      (save-excursion
        (end-of-line)
        (forward-line 1)
        (delete-region (point)
                       (if (re-search-forward "[^ \t\n]" 'noerror)
                           (progn (beginning-of-line) (point))
                           (point-max)))))
    ;; Handle the special case where point is followed by newline and eob.
    ;; Delete the line, leaving point at eob.
    (if (looking-at "^[ \t]*\n\\'")
        (delete-region (point) (point-max)))))

(defun check-parens ()
  "バッファの括弧の釣り合いを調べる."
  (interactive)
  (handler-case
      (let ((home (point)))
        (goto-char (point-min))
        (while (forward-list))
        (goto-char home)
        (message "だいたいあってる")
        t)
    (simple-error (c)
      (message "このへん間違ってるかも")
      (ding)
      nil)))

;; $EMACS/lisp-mode.el
(defun xyzzy-lisp-byte-compile-and-load (&optional force-compile)
  "Byte-compile the current file (if it has changed), then load compiled code."
  (interactive "P")
  (or (file-visited-p)
      (error "The buffer must be saved in a file first"))
  ;; Recompile if file or buffer has changed since last compilation.
  (if (and (buffer-modified-p)
           (y-or-n-p "Save buffer ~A first? " (get-buffer-file-name)))
      (save-buffer))
  (let* ((buffer-file-name (get-buffer-file-name))
         (compiled-file-name (compile-file-pathname buffer-file-name)))
    (if (and (file-newer-than-file-p compiled-file-name buffer-file-name)
             (not force-compile))
	(load-file compiled-file-name)
      (and (byte-compile-file buffer-file-name)
           (load compiled-file-name)))))

;; or http://blue.ribbon.to/~aotororo/prog/200310.html#d03_t3
(defun indent-rigidly (from to &optional (arg 1))
  "リージョンを引数桁だけインデントする."
  (interactive "*r\np")
  (or (< from to)
      (rotatef from to))
  (save-excursion
    (goto-char to)
    (setq to (point-marker))
    (goto-char from)
    (or (bolp) (forward-line 1))
    (while (< (point) (marker-point to))
      (let ((bol (point))
            (indent (progn (back-to-indentation) (current-column))))
        (delete-region bol (point))
        (or (eolp)
            (indent-to (max 0 (+ indent arg)))))
      (forward-line 1))))


(global-set-key '(#\C-x #\C-o) 'emacs-delete-blank-lines)
(global-set-key '(#\C-x #\TAB) 'indent-rigidly)

(define-key *shell-mode-map* #\C-d 'comit-delchar-or-maybe-eof)
(define-key *shell-mode-map* #\C-a 'ed::shell-goto-bol)

(define-key ed::*lisp-mode-map* '(#\C-c #\C-k) 'xyzzy-lisp-byte-compile-and-load)
(define-key ed::*lisp-interaction-mode-map* '(#\C-c #\C-k) 'xyzzy-lisp-byte-compile-and-load)
