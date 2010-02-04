;;; -*- Mode: Lisp; Package: EDITOR; Encoding: Shift_JIS -*-
;;;
;;; animate.el --- make text dance
;;;
;;; This file is NOT part of xyzzy.
;;;

;; Copyright (C) 2001, 2002, 2003, 2004, 2005,
;;   2006, 2007 Free Software Foundation, Inc.

;; Maintainer: Richard Stallman <rms@gnu.org>
;; Keywords: games

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

;; (animate-string STRING VPOS &optional HPOS)
;; makes the string STRING appear starting at VPOS, HPOS
;; by having each letter swoop into place from random starting position.

;; animate-birthday-present was the first application of this program.

#|
### これはなに?

emacs の animate.el を xyzzy に移植したものです

### Known Bugs

- animate-sequence 終了後に元のウィンドウに戻ってしまう
  > (animate-sequence '("L" "I" "S" "P") 3)

### Change Log

2010-02-04 移植

;;; by KOBAYASHI Shigeru (kosh)
|#

;;; Code:

(provide "animate")

(in-package "editor")

(export '(animate-string
          animate-sequence
          animate-birthday-present))
(export '(animate-n-steps))

#+emacs
(defun set-window-start (window pos &optional noforce)
  "Make display in window start at position pos in window's buffer."
  (or window (setq window (selected-window)))
  (set-window window)
  (goto-char pos)
  (recenter 0)
  pos)

(defun move-to-column (column &optional force)
  "Move point to column COLUMN in the current line."
  (let ((n (goto-column column)))
    (when force
      (insert " " (max (- column n) 0))))
  (current-column))

;;; STRING is the string to be displayed,
;;; and DEST-X, DEST-Y say where on the screen
;;; it should end up.

;;; This function returns a list describing
;;; all the characters and the paths they should take.
;;; Each element has the form
;;;  (CHAR START-Y START-X DEST-Y DEST-X).

;;; The start position of each character is chosen randomly.
;;; The destination is chosen to put it in the right place
;;; in the string when the whole string finally reaches its
;;; specified position.

(defun animate-initialize (string vpos hpos &aux characters)
  (dotimes (i (length string))
    (push (list (aref string i)
                ;; Random starting positions.
                (random (window-height))
                (random #+emacs (1- (window-width))
                        #+xyzzy (1- (window-columns)))
                ;; All the chars should end up
                ;; on the specified line.
                vpos
                ;; The Ith character in the string
                ;; needs to end up I positions later.
                (+ hpos i))
          characters))
  characters)

;;; Display the characters in CHARACTERS,
;;; each one FRACTION of the way from its start to its destination.
;;; If FRACTION is 0, the characters appear in their starting positions.
;;; If FRACTION is 1, the characters appear in their destinations.

(defun animate-step (characters fraction)
  (let ((remains (- 1 fraction)))
    (dolist (item characters)
      (let ((vpos (+ (* remains (nth 1 item))
                     (* fraction (nth 3 item))))
            (hpos (+ (* remains (nth 2 item))
                     (* fraction (nth 4 item)))))
        (animate-place-char (nth 0 item) vpos hpos)))))

;;; Place the character CHAR at position VPOS, HPOS in the current buffer.
(defun animate-place-char (char vpos hpos &aux wide-char-p)
  (goto-char (window-start))
  (let (abbrev-mode)
    (dotimes (i vpos)
      (end-of-line)
      (unless (forward-line)
        (insert "\n"))))
  (beginning-of-line)
  (move-to-column (floor hpos) t)
  (unless (eolp) (delete-char (char-columns char)))
  (insert char 1))

(defvar animate-n-steps 10
  "Number of steps to use `animate-string'.")

;;;###autoload
(defun animate-string (string vpos &optional hpos)
  "Display STRING starting at position VPOS, HPOS, using animation.
The characters start at randomly chosen places,
and all slide in parallel to their final positions,
passing through `animate-n-steps' positions before the final ones.
If HPOS is nil (or omitted), center the string horizontally
in the current window."
  (let ((characters
         (animate-initialize string vpos
                             (or hpos
                                 ;; HPOS unspecified, so compute
                                 ;; it so as to center the string.
                                 (max 0 (/ (- #+emacs (window-width)
                                              #+xyzzy (window-columns)
                                              (length string))
                                           2))))))
    (dotimes (i animate-n-steps)
      ;; Display the characters at the Ith position.
      ;; This inserts them in the buffer.
      (animate-step characters (/ i 1.0 animate-n-steps))
      ;; Make sure buffer is displayed starting at the beginning.
      #+emacs (set-window-start nil 1)
      ;; Display it, and wait just a little while.
      (sit-for .05)
      ;; Now undo the changes we made in the buffer.
      (undo))
    ;; Insert the characters in their final positions.
    (animate-step characters 1)
    ;; Put the cursor at the end of the text on the line.
    (end-of-line)
    ;; Redisplay so they appear on the screen there.
    (sit-for 0)
    ;; This is so that the undo command, used afterwards,
    ;; will undo the "animate" calls one by one.
    (undo-boundary)))

;;;###autoload
(defun animate-sequence (list-of-strings space)
  "Display strings from LIST-OF-STRING with animation in a new buffer.
Strings will be separated from each other by SPACE lines."
  (let ((vpos (/ (- (window-height)
                    #+emacs 1 ;; For the mode-line
                    (* (1- (length list-of-strings)) space)
                    (length list-of-strings))
                 2)))
    (switch-to-buffer (get-buffer-create "*Animation*"))
    (erase-buffer (selected-buffer))
    (setup-temp-buffer (selected-buffer))
    (setq kept-undo-information 1000)
    (sit-for 0 t)
    (setq indent-tabs-mode nil)
    (dolist (string list-of-strings)
      (animate-string string vpos)
      (setq vpos (+ vpos space 1)))
    ))

;;;###autoload
(defun animate-birthday-present (&optional name)
  "Display one's birthday present in a new buffer."
  (interactive
      (list (read-string "Name: " :default #1=(string-capitalize (user-name)))))
  (unless name
    (setq name #1#))
  ;; Make a suitable buffer to display the birthday present in.
  (switch-to-buffer (get-buffer-create (concat "*" name "*")))
  (erase-buffer (selected-buffer))
  (setup-temp-buffer (selected-buffer))
  (setq kept-undo-information 1000)
  ;; Display the empty buffer.
  (sit-for 0)
  ;; Make sure indentation does not use tabs.
  ;; They would confuse things.
  (setq indent-tabs-mode nil)

  (animate-string "Happy Birthday," 6)
  (animate-string name 7)

  (sit-for 1)

  (animate-string "You are my sunshine," 10)
  (sit-for .5)
  (animate-string "My only sunshine." 11)
  (sit-for .5)
  (animate-string "I'm awful sad that" 12)
  (sit-for .5)
  (animate-string "You've moved away." 13)
  (sit-for .5)
  (animate-string "Let's talk together" 15)
  (sit-for .5)
  (animate-string "And love more deeply." 16)
  (sit-for .5)
  (animate-string "Please bring back" 17)
  (animate-string "my sunshine" 18)
  (animate-string "to stay!" 19))

#+emacs (random t)
#+xyzzy (make-random-state t)

;;; animate.el ends here
