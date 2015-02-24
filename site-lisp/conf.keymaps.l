;;; conf.keymaps.l

(global-set-key #\C-h 'delete-backward-char-or-selection)

(global-set-key #\C-a 'beginning-of-virtual-line)
(global-set-key #\C-e 'end-of-virtual-line)

(global-unset-key '(#\C-x #\C-n)) ; lisp/buffer.l:rename
(global-unset-key #\Apps)         ; lisp/mouse.l:apps-popup

(setq *std-control-next-char* #\C-v
      *std-control-prior-char* #\C-^)

;; Toggle
(define-key *global-keymap* '(#\C-x #\t #\z) 'toggle-zenkaku-space)
(define-key *global-keymap* '(#\C-x #\t #\n) 'toggle-newline)
(define-key *global-keymap* '(#\C-x #\t #\t) 'toggle-tab)
(define-key *global-keymap* '(#\C-x #\t #\e) 'toggle-trace-on-error)

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

(set-extended-key-translate-table exkey-C-tab #\F20)   ; Ctrl+Tab
(set-extended-key-translate-table exkey-S-C-tab #\F21) ; Shift+Ctrl+Tab

(global-set-key #\F20 'next-pseudo-frame)
(global-set-key #\F21 'previous-pseudo-frame)
;;(global-set-key #\M-Left 'previous-pseudo-frame)
;;(global-set-key #\M-Right 'next-pseudo-frame)
