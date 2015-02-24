;;; -*- Mode: Lisp; Package: EDITOR; Encoding: Shift_JIS -*-
;;;
;;; zone.l --- idle display hacks
;;;
;;; This file is NOT part of xyzzy.
;;;

;; Copyright (C) 2000, 2001, 2002, 2003, 2004,
;;   2005, 2006, 2007 Free Software Foundation, Inc.

;; Author: Victor Zandy <zandy@cs.wisc.edu>
;; Maintainer: Thien-Thi Nguyen <ttn@gnu.org>
;; Keywords: games
;; Created: June 6, 1998

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Don't zone out in front of Emacs!  Try M-x zone.
;; If it eventually irritates you, try M-x zone-leave-me-alone.

;; Bored by the zone pyrotechnics?  Write your own!  Add it to
;; `zone-programs'.  See `zone-call' for higher-ordered zoning.

;; WARNING: Not appropriate for Emacs sessions over modems or
;;          computers as slow as mine.

;; THANKS: Christopher Mayer, Scott Flinchbaugh,
;;         Rachel Kalmar, Max Froumentin, Juri Linkov,
;;         Luigi Panzeri, John Paul Wallington.

#|
### これはなに?

emacs の zone.el を xyzzy に移植したものです

### 遊び方

~/site-lisp 以下にこのファイルを置いてバイトコンパイル
.xyzzy に次の一行を追加して再起動する
(require "zone")

適当なバッファで M-x: zone

zone-when-idle - 指定した時間(秒)キー操作がないと自動的に zone を起動する
zone-leave-me-alone - `zone-when-idle' を解除する

### 仕様、バグ

- 行番号が元の表示とずれる
- 文字装飾なし、テキストのみ
- with-timeout マクロが使えないのでループ内部で時間を計るように変更
- unread-char などでキー入力が奪われる場合に zone-timer が実行されてしまう
  (例: isearch-repeat-forward)
- life-patterns(life.l) が定数のため束縛不可
- zone-when-idle から起動された zone を解除する際に別の zone が起動する場合がある
- drip 系 zone が終了しない (わりと深刻)
- 日本語を含む zone-pgm-whack-chars が重い
  (恐らく translate-region が原因)

### Change Log

2010-01-10 移植開始
2010-01-30 zone-programs が7割くらい動くようになった
2010-01-31 zone-programs が8割くらい動くようになった
2010-02-04 zone-programs が8割強動くようになった

2012-01-09 s/make-string/make-array

;;; by KOBAYASHI Shigeru (kosh)
|#

;;; Code:

(provide "zone")

(in-package "editor")

(export '(zone
          zone-when-idle
          zone-leave-me-alone))

;(export '(zone-timeout))


;;;; Emacs Lisp functions for xyzzy

(defun window-start (&optional window)
  "Return position at which display currently starts in WINDOW."
  (save-window-excursion
    (set-window window)
    (goto-line (get-window-start-line))
    (point)))

(defun window-end (&optional window update)
  "Return position at which display currently ends in WINDOW."
  (save-window-excursion
    (set-window window)
    (goto-line (if (pos-visible-in-window-p (point-max))
                   (buffer-lines)
                 (+ (window-lines) (get-window-start-line)
                    ;-1
                    )))
    (point)))

(defmacro with-current-buffer (buffer &rest body)
  "Execute the forms in BODY with BUFFER temporarily current."
  `(save-excursion
     (set-buffer ,buffer)
     ,@body))
(setf (get 'with-current-buffer 'lisp-indent-hook) 1)

(defun frame-width ()
  "Return number of columns available for display on frame."
  (window-width)
  ;(window-columns)
  )

(defun input-pending-p ()
  "Return t if command input is currently available with no wait."
  (listen *keyboard*))

(defun discard-input ()
  "Discard the contents of the terminal input buffer."
  (clear-input *keyboard*))

(defun count-lines (start end)
  "Return number of lines between START and END."
  (let (startl endl result)
    (save-excursion
      (goto-char start)
      (setq startl (current-line-number))
      (goto-char end)
      (setq endl (current-line-number)))
    (setq result (- endl startl))
    result))

(defun char-width (ch)
  "Return width of CH when displayed in the current buffer."
  (case ch
    (#\TAB *tab-columns*)
    (#\LFD 0)
    (otherwise (char-columns ch))))

(defun move-to-column (column &optional force)
  "Move point to column COLUMN in the current line."
  (let ((n (goto-column column)))
    (when force
      (insert " " (max (- column n) 0))))
  (current-column))

(defun translate-region (start end table &aux char)
  "From START to END, translate characters according to TABLE."
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (goto-char (point-min))
      (while (not (eobp))
        (setq char (following-char))
        (delete-char 1)
        (insert (or (ignore-errors
                     (elt table (char-code char)))
                    char))
        (forward-char 1)))))



(defvar zone-timer nil
  "The timer we use to decide when to zone out, or nil if none.")

(defvar zone-timeout nil
  "*Seconds to timeout the zoning.
If nil, don't interrupt for about 1^26 seconds.")

;; Vector of functions that zone out.  `zone' will execute one of
;; these functions, randomly chosen.  The chosen function is invoked
;; in the *zone* buffer, which contains the text of the selected
;; window.  If the function loops, it *must* periodically check and
;; halt if `input-pending-p' is t (because quitting is disabled when
;; Emacs idle timers are run).
(defvar zone-programs
  '(
    zone-pgm-jitter
    zone-pgm-putz-with-case
    zone-pgm-dissolve
    ;; zone-pgm-explode
    zone-pgm-whack-chars
    zone-pgm-rotate
    zone-pgm-rotate-LR-lockstep
    zone-pgm-rotate-RL-lockstep
    zone-pgm-rotate-LR-variable
    zone-pgm-rotate-RL-variable
    zone-pgm-drip
    zone-pgm-drip-fretfully
    zone-pgm-five-oclock-swan-dive
    zone-pgm-martini-swan-dive
    zone-pgm-paragraph-spaz
    zone-pgm-stress
    zone-pgm-stress-destress
    zone-pgm-random-life
    ))

(defmacro zone-orig (&rest body)
  `(with-current-buffer (get 'zone 'orig-buffer)
     ,@body))

(defmacro zone-hiding-modeline (&rest body)
  `(let ((#1=#:flag (/= 0 (logand (get-window-flags) *window-flag-mode-line*))))
     (unwind-protect
         (progn
           (toggle-window-flag *window-flag-mode-line* nil t)
           ,@body)
       (toggle-window-flag *window-flag-mode-line* #1# t))))

(defun zone-call (program &optional (timeout zone-timeout))
  "Call PROGRAM in a zoned way.
If PROGRAM is a function, call it, interrupting after the amount
 of time in seconds specified by optional arg TIMEOUT, or `zone-timeout'
 if unspecified, q.v.
PROGRAM can also be a list of elements, which are interpreted like so:
If the element is a function or a list of a function and a number,
 apply `zone-call' recursively."
  (labels ((zone-function-p (x)
             (or (functionp x)
                 (and (symbolp x)
                      (fboundp x)))))
    (zone-set-timeout timeout)
    (cond ((zone-function-p program)
           (funcall program))
          ((listp program)
           (mapcar (lambda (elem)
                     (cond ((zone-function-p elem)
                            (zone-call elem nil))
                           ((and (listp elem)
                                 (zone-function-p (car elem))
                                 (numberp (cadr elem)))
                            (apply 'zone-call elem))
                           (t (error "bad `zone-call' elem: ~A" elem))))
                   program)))))

(defun zone-sorry ()
  (start-timer 0.05 (lambda () (message "Zoning...sorry")) t))

;;;###autoload
(defun zone (&optional pgm)
  "Zone out, completely."
  (interactive (list (when *prefix-args*
                       (find (completing-read "Zone program: " zone-programs
                                              :must-match t)
                             zone-programs
                             :test (lambda (x y)
                                     (equal x (symbol-name y)))))))
  (unless pgm
    (setq pgm (elt zone-programs (random (length zone-programs)))))
  (save-window-excursion
    (let ((outbuf (get-buffer-create "*zone*"))
          (text (buffer-substring (window-start) (window-end)))
          (flags (get-window-flags))
          (blink-caret *blink-caret*)
          (status-bar-format *status-bar-format*))
      (setf (get 'zone 'orig-buffer) (selected-buffer))
      (switch-to-buffer outbuf)
      (setq mode-name "Zone")
      (erase-buffer (selected-buffer))
      (setup-temp-buffer (selected-buffer))
      (insert text)
      (untabify (point-min) (point-max))
      (setq *blink-caret* nil)
      (setq *status-bar-format* (string-trim "cup" *status-bar-format*))
      ;; suppress window flags
      (progn
        (ed::toggle-window-flag *window-flag-vscroll-bar* nil t))
      (sit-for 0 t)
      (unwind-protect
          (handler-case
              (progn
                (message "Zoning... (~A)" pgm)
                (gc 'nomsg)
                ;; If some input is pending, zone says "sorry", which
                ;; isn't nice; this might happen e.g. when they invoke the
                ;; game by clicking the menu bar.  So discard any pending
                ;; input before zoning out.
                (if (input-pending-p)
                    (discard-input))
                (zone-call pgm))
            (error ()
              (while (not (input-pending-p))
                (message "We were zoning when we wrote ~A..." pgm)
                (sit-for 3)
                (message "...here's hoping we didn't hose your buffer!")
                (sit-for 3))))
        ;; zoning finish
        (kill-buffer outbuf)
        (set-window-flags flags)
        (setq *blink-caret* blink-caret)
        (setq *status-bar-format* status-bar-format)
        (zone-sorry)))))

;;;; Zone when idle, or not.

(defun zone-timer ()
  (stop-timer 'zone)
  (start-timer zone-timer 'zone nil))

(defun zone-when-idle (secs)
  "Zone out when Emacs has been idle for SECS seconds."
  (interactive "nHow long before I start zoning (seconds): ")
  (when (< 0 secs)
    (setq zone-timer secs)
    (add-hook '*post-command-hook* 'zone-timer)))

(defun zone-leave-me-alone ()
  "Don't zone out when Emacs is idle."
  (interactive)
  (stop-timer 'zone)
  (delete-hook '*post-command-hook* 'zone-timer)
  (setq zone-timer nil)
  (message "I won't zone out any more"))

(defvar zone-start-time nil)
(defun zone-set-timeout (sec)
  (setq zone-start-time (get-internal-real-time)
        zone-timeout sec))
(defun zone-timeout-p ()
  (and zone-timeout
       zone-start-time
       (< zone-timeout
          (/ (- (get-internal-real-time) zone-start-time) 1000.0))
       ))


;;;; jittering

(defun zone-shift-up ()
  (let* ((b (point))
         (e (progn (forward-line 1) (point)))
         (s (buffer-substring b e)))
    (delete-region b e)
    (goto-char (point-max))
    (insert s)))

(defun zone-shift-down ()
  (goto-char (point-max))
  (let* ((b (point))
         (e (progn (forward-line -1) (point)))
         (s (buffer-substring b e)))
    (delete-region b e)
    (goto-char (point-min))
    (insert s)))

(defun zone-shift-left ()
  (let (s)
    (while (not (eobp))
      (unless (eolp)
        (setq s (buffer-substring (point) (1+ (point))))
        (delete-char 1)
        (end-of-line)
        (insert s))
      (forward-char 1))))

(defun zone-shift-right ()
  (goto-char (point-max))
  (end-of-line)
  (let (s)
    (while (not (bobp))
      (unless (bolp)
        (setq s (buffer-substring (1- (point)) (point)))
        (delete-char -1)
        (beginning-of-line)
        (insert s))
      (if (previous-line)
          (end-of-line)
        (goto-bol)))))

(defun zone-pgm-jitter ()
  (let ((ops '(
               zone-shift-left
               zone-shift-right
               zone-shift-down
               zone-shift-up
               )))
    (goto-char (point-min))
    (while (and (not (input-pending-p))
                (not (zone-timeout-p)))
      (funcall (elt ops (random (length ops))))
      (goto-char (point-min))
      (sit-for 0))))


;;;; whacking chars

(defun zone-pgm-whack-chars ()
  (let ((tbl (copy-seq (get 'zone-pgm-whack-chars 'wc-tbl))))
    (while (and (not (input-pending-p))
                (not (zone-timeout-p)))
      (let ((i 48))
        (while (< i 122)
          (setf (aref tbl (+ 48 (random (- 123 48)))) (code-char i))
          (incf i))
        (translate-region (point-min) (point-max) tbl)
        (sit-for 0)))))

(setf (get 'zone-pgm-whack-chars 'wc-tbl)
      (let ((tbl (make-array 128)))
        (dotimes (i 128 tbl)
          (setf (aref tbl i) (code-char i)))))

;;;; dissolving

(defun zone-remove-text ()
  (let ((working t))
    (while working
      (setq working nil)
      (save-excursion
        (goto-char (point-min))
        (while (not (eobp))
          (if (looking-at "[^(){}\n\t ]")
              (let ((n (random 5)))
                (if (not (= n 0))
                    (progn
                      (setq working t)
                      (forward-char 1))
                  (progn
                    (delete-char 1)
                    (insert " "))))
            (forward-char 1))))
      (sit-for 0))))

(defun zone-pgm-dissolve ()
  (zone-remove-text)
  (zone-pgm-jitter))


;;;; exploding

(defun zone-exploding-remove ()
  (let ((i 0))
    (while (< i 5)
      (save-excursion
        (goto-char (point-min))
        (while (not (eobp))
          (if (looking-at "[^*\n\t ]")
              (let ((n (random 5)))
                (if (not (= n 0))
                    (forward-char 1))
                (insert " ")))
          (forward-char 1)))
      (setq i (1+ i))
      (sit-for 0)))
  (zone-pgm-jitter))

(defun zone-pgm-explode ()
  (zone-exploding-remove)
  (zone-pgm-jitter))


;;;; putzing w/ case

;; Faster than `zone-pgm-putz-with-case', but not as good: all
;; instances of the same letter have the same case, which produces a
;; less interesting effect than you might imagine.
(defun zone-pgm-2nd-putz-with-case ()
  (let ((tbl (make-array 128 :initial-element #\x :element-type 'character))
        (i 0))
    (while (< i 128)
      (setf (aref tbl i) (code-char i))
      (incf i))
    (while (and (not (input-pending-p))
                (not (zone-timeout-p)))
      (setq i #.(char-code #\a))
      (while (<= i #.(char-code #\z))
        (setf (aref tbl (char-code
                         (if (zerop (random 5))
                             (char-upcase (code-char i))
                           (char-downcase (code-char i)))))
              (code-char i))
        (setq i (+ i (1+ (random 5)))))
      (setq i #.(char-code #\A))
      (while (<= i #.(char-code #\Z))
        (setf (aref tbl (char-code
                         (if (zerop (random 5))
                             (char-downcase (code-char i))
                           (char-upcase (code-char i)))))
              (code-char i))
        (setq i (+ i (1+ (random 5)))))
      (translate-region (point-min) (point-max) tbl)
      (sit-for 0))))

(defun zone-pgm-putz-with-case ()
  (goto-char (point-min))
  (while (and (not (input-pending-p))
              (not (zone-timeout-p)))
    (let ((np (+ 2 (random 5)))
          (pm (point-max)))
      (while (< np pm)
        (goto-char np)
        (let ((prec (preceding-char)))
          (insert (if (zerop (random 2))
                      (char-upcase prec)
                    (char-downcase prec))))
        (backward-char 2)
        (delete-char 1)
        (setq np (+ np (1+ (random 5))))))
    (goto-char (point-min))
    (sit-for 0)))


;;;; rotating

(defun zone-line-specs ()
  (let (ret)
    (save-excursion
      (goto-char (window-start))
      (while (< (point) (window-end))
        (when (looking-at "[\t ]*\\([^\n]+\\)")
          (setq ret (cons (cons (match-beginning 1) (match-end 1)) ret)))
        (forward-line 1)))
    ret))

(defun zone-pgm-rotate (&optional random-style)
  (let* ((specs (apply
                 'vector
                 (let (res)
                   (mapcar (lambda (ent)
                             (let* ((beg (car ent))
                                    (end (cdr ent))
                                    (amt (if random-style
                                             (funcall random-style)
                                           (- (random 7) 3))))
                               (when (< (- end (abs amt)) beg)
                                 (setq amt (random (- end beg))))
                               (unless (= 0 amt)
                                 (setq res
                                       (cons
                                        (vector amt beg (- end (abs amt)))
                                        res)))))
                           (zone-line-specs))
                   res)))
         (n (length specs))
         amt aamt cut paste txt i ent)
    (while (and (not (input-pending-p))
                (not (zone-timeout-p)))
      (setq i 0)
      (while (< i n)
        (setq ent (aref specs i))
        (setq amt (aref ent 0) aamt (abs amt))
        (if (> 0 amt)
            (setq cut 1 paste 2)
          (setq cut 2 paste 1))
        (goto-char (aref ent cut))
        (setq txt (buffer-substring (point) (+ (point) aamt)))
        (delete-char aamt)
        (goto-char (aref ent paste))
        (insert txt)
        (setq i (1+ i)))
      (sit-for 0.04))))

(defun zone-pgm-rotate-LR-lockstep ()
  (zone-pgm-rotate (lambda () 1)))

(defun zone-pgm-rotate-RL-lockstep ()
  (zone-pgm-rotate (lambda () -1)))

(defun zone-pgm-rotate-LR-variable ()
  (zone-pgm-rotate (lambda () (1+ (random 3)))))

(defun zone-pgm-rotate-RL-variable ()
  (zone-pgm-rotate (lambda () (1- (- (random 3))))))


;;;; dripping

(defun zone-cpos (pos)
  (buffer-substring pos (1+ pos)))

(defun zone-replace-char (count del-count char-as-string new-value)
  (delete-char (or del-count (- count)))
  (setf (aref char-as-string 0) new-value)
  (dotimes (i count) (insert char-as-string)))

(defun zone-park/sit-for (pos seconds)
  (let ((p (point)))
    (goto-char pos)
    (prog1 t
      (sit-for seconds)
      (goto-char p))))

(defun zone-fret (wbeg pos)
  (let* ((c-string (zone-cpos pos))
         (cw-ceil (ceiling (char-width (aref c-string 0))))
         (hmm (cond
               ((string-match "[a-z]" c-string) (string-upcase c-string))
               ((string-match "[A-Z]" c-string) (string-downcase c-string))
               (t (make-array cw-ceil :initial-element #\SPC :element-type 'character)))))
    (do ((i 0 (1+ i))
         (wait 0.5 (* wait 0.8)))
        ((= i 20))
      (goto-char pos)
      (cond ((= 0 (rem i 2))
             (delete-char 1)
             (insert hmm))
            (t
             (delete-char (length hmm))
             (insert c-string)))
      (zone-park/sit-for wbeg wait))
    (delete-char -1)
    (insert c-string)))

(defun zone-fill-out-screen (width height)
  (let ((start (window-start))
        (line (make-array width :initial-element #\SPC :element-type 'character)))
    (goto-char start)
    ;; fill out rectangular ws block
    (while (progn
             (end-of-line)
             (let ((cc (current-column)))
               (if (< cc width)
                   (insert (substring line cc))
                 (delete-char (- width cc)))
               (cond ((eobp) (insert "\n") nil)
                     (t (forward-char 1) t)))))
    ;; pad ws past bottom of screen
    (let ((nl (- height (count-lines (point-min) (point)))))
      (dotimes (i nl) (insert line "\n")))
    (goto-char start)
    (recenter 0)
    (sit-for 0)))

(defun zone-fall-through-ws (c wbeg wend)
  (let* ((cw-ceil (ceiling (char-width (aref c 0))))
         (spaces (make-array cw-ceil :initial-element #\SPC :element-type 'character))
         (col (current-column))
         (wait 0.15)
         newpos fall-p)
    (while (when (save-excursion
                   (next-line 1)
                   (and (= col (current-column))
                        (setq newpos (point))
                        (string= spaces (buffer-substring newpos (+ newpos cw-ceil)))
                        (setq newpos (+ newpos (1- cw-ceil)))))
             (setq fall-p t)
             (delete-char 1)
             (insert spaces)
             (goto-char newpos)
             (when (< (point) wend)
               (delete-char cw-ceil)
               (insert c)
               (forward-char -1)
               (zone-park/sit-for wbeg (setq wait (* wait 0.8))))))
    fall-p))

(defun zone-pgm-drip (&optional fret-p pancake-p)
  (let* ((ww #+emacs (1- (window-width))
             #+xyzzy (window-columns))
         (wh (window-height))
         (mc 0)                         ; miss count
         (total (* ww wh))
         (fall-p nil)
         wbeg wend c)
    (zone-fill-out-screen ww wh)
    (setq wbeg (window-start)
          wend (window-end))
    (catch 'done
      (while (and (not (input-pending-p))
                  (not (zone-timeout-p)))
        (setq mc 0 wend (window-end))
        ;; select non-ws character, but don't miss too much
        (goto-char (+ wbeg (random (- wend wbeg))))
        (while (looking-at "[ \n\f]")
          (do-events)
          (if (< total (setq mc (1+ mc)))
              (throw 'done 'sel)
            (goto-char (+ wbeg (random (- wend wbeg))))))
        ;; character animation sequence
        (let ((p (point)))
          (when fret-p (zone-fret wbeg p))
          (goto-char p)
          (setq c (zone-cpos p)
                fall-p (zone-fall-through-ws c wbeg wend)))
        ;; assuming current-column has not changed...
        (when (and pancake-p
                   fall-p
                   (< (count-lines (point-min) (point)) wh))
          (let ((cw (ceiling (char-width (aref c 0)))))
            (zone-replace-char cw   1 c #\@) (zone-park/sit-for wbeg 0.137)
            (zone-replace-char cw nil c #\*) (zone-park/sit-for wbeg 0.137)
            (zone-replace-char cw nil c #\_)))))))

(defun zone-pgm-drip-fretfully ()
  (zone-pgm-drip t))

(defun zone-pgm-five-oclock-swan-dive ()
  (zone-pgm-drip nil t))

(defun zone-pgm-martini-swan-dive ()
  (zone-pgm-drip t t))


;;;; paragraph spazzing (for textish modes)

(defun zone-pgm-paragraph-spaz ()
  (if (member (zone-orig buffer-mode)
              ;; there should be a better way to distinguish textish modes
              '(text-mode
                texinfo-mode
                fundamental-mode))
      ;; FIXME
      (let ((fill-column fill-column)
            (fc-min fill-column)
            (fc-max fill-column)
            (max-fc (1- (frame-width))))
        (while (progn
                 (sit-for 0.1)
                 (and (not (input-pending-p))
                      (not (zone-timeout-p))) )
          (save-excursion (fill-paragraph))
          ;(fill-paragraph)
          ;(backward-paragraph)
          (setq fill-column (+ fill-column (- (random 5) 2)))
          (when (< fill-column fc-min)
            (setq fc-min fill-column))
          (when (> fill-column max-fc)
            (setq fill-column max-fc))
          (when (> fill-column fc-max)
            (setq fc-max fill-column)) ))
    (progn
      (message "Zoning... (zone-pgm-rotate)")
      (zone-pgm-rotate))))


;;;; stressing and destressing

(defun zone-pgm-stress ()
  (goto-char (point-min))
  (let ((lines (split-string
                (buffer-substring (point-min) (point-max))
                "\n")))
    (sit-for 5)
    (zone-hiding-modeline
     (let ((msg "Zoning... (zone-pgm-stress)"))
       (while (not (string= msg ""))
         (message (setq msg (substring msg 1)))
         (sit-for 0.05)))
     (while (and (not (input-pending-p))
                 (not (zone-timeout-p)))
       (when (< 50 (random 100))
         (goto-char (point-max))
         (forward-line -1)
         (let ((kill-whole-line t))
           (kill-line))
         (goto-char (point-min))
         (insert (nth (random (length lines)) lines) "\n"))
       (message (concat (make-array (random (- (frame-width) 5))
                                    :initial-element #\SPC
                                    :element-type 'character)
                        "grrr"))
       (sit-for 0.1)))))

(defun zone-pgm-stress-destress ()
  (zone-call 'zone-pgm-stress 25)
  (zone-hiding-modeline
   (sit-for 3 t)
   (erase-buffer (selected-buffer))
   (dotimes (i (window-lines))
     (insert (make-array (random (- (window-columns) 5))
                         :initial-element #\SPC
                         :element-type 'character)
             "grrr" "\n"))
   (clear-message)
   (goto-char (point-max))
   (recenter -1)
   (sit-for 3)
   (delete-region (point-min) (window-start))
   (message "hey why stress out anyway?")
   (zone-call '((zone-pgm-rotate         30)
                (zone-pgm-whack-chars    10)
                zone-pgm-drip
                ))))


;;;; the lyfe so short the craft so long to lerne --chaucer

(defvar zone-pgm-random-life-wait nil
  "*Seconds to wait between successive `life' generations.
If nil, `zone-pgm-random-life' chooses a value from 0-3 (inclusive).")

(defun zone-pgm-random-life ()
  (require 'life)
  (zone-fill-out-screen #+emacs (1- (window-width))
                        #+xyzzy (window-columns)
                        (1- (window-height)))
  (let ((top (progn (goto-char (window-start)) (forward-line 7) (point)))
        (bot (progn (goto-char (window-end)) (forward-line -7) (point)))
        (rtc (- (frame-width) 11))
        (min (window-start))
        (max (1- (window-end)))
        s c col)
    (delete-region max (point-max))
    (while (and (progn (goto-char min) (sit-for 0.05) t)
                (progn (goto-char (+ min (random max)))
                       (or (save-restriction
                             (narrow-to-region (point) max)
                             (skip-chars-forward " @\n")
                             (not (= max (point))))
                           (unless (or (= 0 (save-restriction
                                              (let ((p (point)))
                                                (narrow-to-region p min)
                                                (skip-chars-backward " @\n")
                                                (- (point) p))))
                                       (= min (point)))
                             (forward-char -1)
                             t)))
                (and (not (input-pending-p))
                     (not (zone-timeout-p)))
                )
      (do-events)
      (unless (or (eolp) (eobp))
        (setq s (zone-cpos (point))
              c (aref s 0))
        (zone-replace-char (char-width c) 1 s
                           (cond ((or (> top (point))
                                      (< bot (point))
                                      (or (> 11 (setq col (current-column)))
                                          (< rtc col)))
                                  #\SPC)
                                 ((char<= #\a c #\z) (char-upcase c))
                                 ((char<= #\A c #\Z) #\*)
                                 (t #\@)))))
    (sit-for 3)
    (setq col nil)
    (goto-char bot)
    (while (< top (point))
      (setq c (point))
      (move-to-column 9)
      (push (buffer-substring (point) c) col)
      (if (previous-line)
          (goto-bol)
        (end-of-line))
      (forward-char -10))
    (let ((life-patterns
           (vector
            (if (and col (save-restriction
                           (narrow-to-region (point) max)
                           (search-forward "@" t)))
                (cons (make-array (length (car col))
                                  :initial-element #\SPC
                                  :element-type 'character)
                      col)
              (list (format "~{~A~^          ~}"
                            (make-list (/ (- rtc 11) 15) "@@@@@")))))))
      (unwind-protect
          (life (or zone-pgm-random-life-wait (random 1.0)))
        (kill-buffer (selected-buffer))))))

; init seed
#+emacs (random t)
#+xyzzy (make-random-state t)

;;; zone.el ends here
