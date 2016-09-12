;;; takt-play.l -*- Package: Takt -*-

;; Description: Takt playing mode
;; Created: 2016-06-08
;; Version: 0.1

;;; Commentary:

;; * M-x takt-mode:play-this インタラクティブな再生

;;; TODO:

;; * ?A, ?I, ?D 等すべてのコマンドを実装
;; * 表示色を固定 (今のところ Track をそのまま利用している)
;; * 演奏位置がウィンドウ外に複数ある場合に表示が荒ぶる問題
;; * takt-mode Taktファイル編集用メジャーモード
;; * takt-mode と play を分離する

;;; Code:

(provide "takt-play")

(eval-when (compile load eval)
  (require "takt"))

(in-package "takt")

(export '(play
          play-this
          stop
          show-interp-console))

(defvar *root-directory*
  (merge-pathnames "Takt" (si:getenv "programfiles(x86)"))
  "Takt install directory.")

(defun program-path ()
  (merge-pathnames "bin/takt.exe" *root-directory*))

(defvar *buffer-name* " *Takt*"
  "Buffer name for process log output.")

(defvar *out* nil
  "output stream")

(defvar *status* nil
  ":playing or :stopped or :steprec")

(defun set-status (st)
  (setf *status* st))

(defvar *filename-alist* nil
  "Assoc list of (id . buffer)")

(defvar *track-names-alist* nil
  "Assoc list of (track-id . name)")

;;; Commands for $emacsPlay(...)

(defun track-face (track)
  (intern (format nil "takt-face-ntrack~d" track)))

(defun emacs/highlight-line (track id line &aux (buffer (cdr (assoc id *filename-alist*))))
  "(?H track id line) Highlighting request"
  (when (and buffer (not (deleted-buffer-p buffer)))
    ;;(format *out* "(?H track=~d id=~d line=~d &aux buffer=~a)~%" track id line buffer)
    (set-buffer buffer)
    (emacs/dehighlight-line track)
    (goto-line line)
    (unless (pos-visible-in-window-p (point)) (recenter 0))
    (set-text-attribute (user::point-of #'goto-bol)
                        (user::point-of #'goto-eol)
                        (track-face track)
                        :background track
                        ;;:underline t
                        )))

(defun emacs/dehighlight-line (track)
  "(?G track)"
  ;;(format *out* "(?G track=~d)~%" track)
  ;; FIXME: バッファ名が紐づけられていないため、動作中にバッファが切り替わると無効
  (delete-text-attributes (track-face track)))

(defun emacs/beginning-of-play ()
  "(?P) beginning of play."
  (set-status :playing))

(defun emacs/end-of-play ()
  "(?Z) end of play"
  ;;(delete-all-highlights)
  (set-status :stopped))

(defun emacs/register-file (id path)
  "(?F id path) Mapping between full PATH name and file ID."
  (pushnew (cons id (get-file-buffer path))
           *filename-alist*
           :test #'equal))

(defun emacs/set-track-name (track name)
  "(?T track) contents of trackname (No.3 meta) event"
  (let ((item (assoc track *track-names-alist*)))
    (cond ((null item)
           (push (cons track name) *track-names-alist*)
           (ed::takt-track-update-if-shown))
          ((null (cdr item))
           (setf (cdr item) name)
           (ed::takt-track-update-if-shown)))))

(defun emacs/set-csmove-track (track)
  "(?A track)"
  (interactive "P")
  (setq *window-csmvtrack-alist*
        (delete-if-not (lambda (window)
                         (eq window (selected-window)))
                       *window-csmvtrack-alist*
                       :key #'car))
  (push (cons (selected-window) track) *window-csmvtrack-alist*)

  (if (find *status* '(:playing :recording))
      (cmd/update-csmvtracks))
  )

(defun emacs/midi-message (st n v)
  "(?I st n v) MIDI message (during step recording)"
  (warn "?I ~a" :TODO))

(defun emacs/insert-notes ()
  "(?D)"
  (warn "?D ~a" :TODO))

(defun get-cursor-moving-track ()
  (find (selected-window) *window-csmvtrack-alist*))

(defun emacs/move-point (id track line column)
  "(?C id track line column) cursor movement request"
  (let ((buf (cdr (assoc id *filename-alist*))))
    (check-type buf buffer)
    (set-buffer buf)
    (goto-line line)
    (goto-column (1- column))))

(defparameter *emacs-events*
  `((?A . ,#'emacs/set-csmove-track)
    (?I . ,#'emacs/midi-message)
    (?D . ,#'emacs/insert-notes)
    (?P . ,#'emacs/beginning-of-play)
    (?Z . ,#'emacs/end-of-play)
    (?F . ,#'emacs/register-file)
    (?H . ,#'emacs/highlight-line)
    (?G . ,#'emacs/dehighlight-line)
    (?C . ,#'emacs/move-point)
    (?T . ,#'emacs/set-track-name))
  "Set of (?command . handler)")

(defun show-interp-console (&optional (proc (find-interp)))
  (interactive)
  (switch-to-buffer-other-window (process-buffer proc))
  (goto-char (point-max)))

(defun interp-filter (proc str)
  (format *out* "~a~%" str)
  (dolist (line (split-string str #\LFD))
    ;; Error?
    (when (string-match "\\(Line .*: Col \\)\\|\\(Run-time error:\\)" line)
      (show-interp-console proc)
      (return))
    (when (string-match "#\\$\\((.*)\\)" line)
      (let* ((msg (read-from-string (match-string 1)))
             (event (cdr (assoc (car msg) *emacs-events* :test #'string=))))
        ;;(minibuffer-message "Event: ~a" msg)
        (apply event (cdr msg))))
    (refresh-screen)))

(defun interp-sentinel (find-interp)
  (set-status :stopped))

(defun find-interp ()
  (let ((proc (ignore-errors
                (buffer-process *buffer-name*))))
    (if (and proc (eq (process-status proc) :run))
        proc)))

(defun new-interp ()
  (let ((output (get-buffer-create *buffer-name*)))
    (setup-temp-buffer output)
    (setf *out* (make-buffer-stream output))
    (let* ((takt-bin (merge-pathnames "bin" *root-directory*))
           (proc (make-process "takt -NP -femacs" ;;"-m0"
                               :environ `(("PATH" . ,(concat (si:getenv "PATH") ";" takt-bin)))
                               :output output
                               :show nil)))
      (set-process-filter   proc 'interp-filter)
      (set-process-sentinel proc 'interp-sentinel)
      proc)))

(defun start-interp ()
  (or (find-interp) (new-interp)))

(defun shutdown-interp ()
  (let ((proc (find-interp)))
    (if (processp proc)
        (kill-process proc))))

(defun restart-interp ()
  (shutdown-interp)
  (sleep-for 1.0)
  (start-interp))

;; Command

(defun interp-eval (proc stmts)
  (when stmts
    (process-send-string proc (concat stmts "\n"))))

(defun cmd/bool% (b) (if b "true" "false"))

(defun cmd/emacsPlay (file highlight solo &optional begin end)
  (declare (ignore begin end))
  (format nil "$emacsPlay(\"~a\", ~a, ~a)"
          (namestring file)
          (cmd/bool% highlight)
          (cmd/bool% solo)))

(defvar-local *muted-tracks* nil)

(defun cmd/update-track-list ()
  (mapc #'emacs/dehighlight-line *muted-tracks*)
  (format nil "$emacsSetMute(%[~{~a~^,~}])" *muted-tracks*)
  )

(defvar-local *window-csmvtrack-alist* nil
  "Pairs of Emacs window object and track number for automatic cursor moving.
Type (window . track)")

(defun cmd/update-csmvtracks ()
  (format nil "$emacsSetCursorMovingTracks(%[~{~a~^,~}])"
          (mapcar #'cdr *window-csmvtrack-alist*)))

(defun play (file &optional solo mode csmove)
  (interactive "FTakt file: ")
  (unless (get-cursor-moving-track)
    (emacs/set-csmove-track 2))
  (let ((proc (start-interp)))
    (setq *filename-alist* nil)
    (setq *track-names-alist* nil)
    (find-file file nil 'nomsg)
    (ed::takt-track-update-if-shown)
    (interp-eval proc (cmd/update-csmvtracks))
    (interp-eval proc (cmd/update-track-list))
    (interp-eval proc (cmd/emacsPlay file t nil))
    )
  t)

(defun play-this ()
  (interactive)
  (play (get-buffer-file-name)))

(defun stop ()
  (interactive)
  (shutdown-interp)
  (set-status :stopped))
