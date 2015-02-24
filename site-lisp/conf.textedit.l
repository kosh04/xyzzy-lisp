;; conf.textedit.l --- テキスト編集系の設定

;; 括弧の強調表示
(require "paren")
(setq-default *paren-highlight-only-paren* t)
(setq-default *paren-show-not-visible-matched-paren* nil) ; 対応する括弧が見えない場合
(setq-default *paren-paren-attribute* '(t t :background 6))
(setf (symbol-function 'show-paren-mode) #'toggle-paren)
(global-set-key '(#\C-x #\t #\p) 'toggle-paren)
(turn-on-global-paren)
;; (add-hook '*post-startup-hook* 'turn-on-global-paren)

;; リージョンの反転表示
;; ;; http://hie.s64.xrea.com/xyzzy/mylib/rv-region.html
(require "rv-region")
(setq *rv-region-stay-on* t)

;; fill.l
(setq-default fill-column 72)   ; 72 84
(defun turn-on-auto-fill ()
  "auto-fill-mode を on にします."
  (auto-fill-mode t))
;(add-hook '*text-mode-hook* 'turn-on-auto-fill)

;; ファイルにタイムスタンプを付加
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
  "行末の空行を削除する."
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
;; emacskey.l にて定義済み
;; (global-set-key '(#\C-x #\n #\n) 'narrow-to-region)
;; (global-set-key '(#\C-x #\n #\w) 'widen)


(require "insert-pair")
(global-set-key #\( 'insert-parentheses)
(global-set-key #\" 'insert-double-quote)
;(global-set-key #\M-\` 'insert-backq)
(global-set-key #\M-# 'insert-lisp-comments)

