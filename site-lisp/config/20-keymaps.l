;;; config/keymaps

(global-set-key #\C-h 'delete-backward-char-or-selection)

(global-set-key #\C-a 'beginning-of-virtual-line)
(global-set-key #\C-e 'end-of-virtual-line)

(global-unset-key '(#\C-x #\C-n)) ; lisp/buffer.l:rename
(global-unset-key #\Apps)         ; lisp/mouse.l:apps-popup

(setq *std-control-next-char* #\C-v
      *std-control-prior-char* #\C-^)

;; Toggle (Ctrl-c t KEY)
(defvar user-toggle-map
  (let ((map (make-sparse-keymap)))
    (define-key map #\z 'toggle-zenkaku-space)
    (define-key map #\n 'toggle-newline) ; toggle-line-number ?
    (define-key map #\t 'toggle-tab)
    (define-key map #\e 'toggle-trace-on-error)
    map)
  "トグルコマンド色々.")
(setf (symbol-function 'user-toggle-prefix) user-toggle-map)
(define-key spec-map #\t #'user-toggle-prefix)

;; abbrev を使わない
(when (modulep "abbrev")
  (undefine-key ctl-x-map #\+)   ; add-global-abbrev
  (undefine-key ctl-x-map #\C-a) ; add-mode-abbrev
  (undefine-key ctl-x-map #\-)   ; inverse-add-global-abbrev
  (undefine-key ctl-x-map #\C-h) ; inverse-add-mode-abbrev
  (undefine-key esc-map #\')     ; abbrev-prefix-mark
  (undefine-key ctl-x-map #\'))  ; expand-abbrev

;; バッファをさくさく切り替えたい
(setq *next-buffer-in-tab-order* t)
(global-set-key '(#\C-x #\C-.) 'next-buffer)
(global-set-key '(#\C-x #\C-\,) 'previous-buffer)

(set-extended-key-translate-table exkey-S-backspace #\backspace) ;  Shift+Backspace

(global-set-key '(#\C-x #\*) 'calc)
