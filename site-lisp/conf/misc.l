;; conf.misc.l --- 雑多な設定

;; nilなら、JIS X0208に存在する文字をUnicodeから内部コードに変換する際、
;; 日本語の文字として扱う (ChangeLog Version 0.2.2.205)
;; デフォルトは t
(setq *unicode-to-half-width* nil)

;; transient-mark-mode もどき
(defun keyboard-quit ()
  (interactive)
  (set-mark t)                  ; マークをクリア (ChangeLog Version 0.1.0.107)
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
;; (add-date-format "%Y-%m-%dT%H:%M:%S%#Z") ; 標準?
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
;; メールはGmailを利用するので基本的にxyzzyから利用しない
;(require "kamail/config")

;; ミニバッファ内で単語削除
;; http://white.s151.xrea.com/wiki/index.php?memo%2Fxyzzy%2Fminibuffer#w95b8c17
;; http://xyzzy.s53.xrea.com/wiki/index.php?tips%2F%A5%DF%A5%CB%A5%D0%A5%C3%A5%D5%A5%A1%A4%C7%A4%D2%A4%C8%A4%C4%BE%E5%A4%CE%A5%C7%A5%A3%A5%EC%A5%AF%A5%C8%A5%EA%A4%D8
(defun delete-word (&optional (arg 1))
  "*kill-ring*に追加しない単語削除"
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

;; ファイル名のないバッファでの save-buffer のエラーをマイルドに
(defun no-filenames-error ()
  (plain-error "ファイル名がありません"))

(add-hook '*save-buffer-no-filenames-hook* 'no-filenames-error)

(defun just-one-space+ ()
  (interactive "*")
  ;; 改行もまとめて削除する
  (delete-region (progn (skip-chars-backward " \t\n") (point))
		 (progn (skip-chars-forward " \t\n") (point)))
  (insert #\SPC))

(global-set-key '(#\ESC #\SPC) 'just-one-space+)

;; ** delete-indentation [M-^] である程度代用できるかも (2012-10-11)
;; (global-set-key '(#\ESC #\SPC) 'delete-indentation)
