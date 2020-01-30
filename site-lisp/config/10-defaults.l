;;; -*- Mode: Lisp; Package: USER -*-
;;;
;;; This file is NOT part of xyzzy.
;;;

;; xyzzy_-q でも使えるように
;; 必要最低限の設定と標準ライブラリのロードを行う

(provide "config/defaults")

;; ステータスバーに色々表示
(setq *status-bar-format* "cuT")

;; IMEの状態をモードラインにEmacs風に
(setq mode-line-format "[%i] --%*- %b (%M) [%k:%l] %P %f")

;; ナイスアンドゥ (non-nil なら undo 後のカーソル位置は削除範囲の末尾)
(setq *move-forward-after-undo-deletion* t)

;; 廃棄するバッファのファイル名がミニバッファに表示 (C-x C-v)
(setq *find-other-file-requires-file-name* t)


;; transient-mark-mode もどき
(defun keyboard-quit ()
  (interactive)
  (set-mark t)                  ; マークをクリア (ChangeLog Version 0.1.0.107)
  (error 'quit))
(global-set-key #\C-g 'keyboard-quit)

;; 補完表示しない拡張子
(pushnew ".elc" ignored-extensions :test #'equal)
(pushnew ".o" ignored-extensions :test #'equal)

;; ツールバーの表示がたまにおかしくなるので
;; http://lisperblog.blogspot.com/2010/01/xyzzy.html
(defun load-command-bar-info-if-xyzzy-q ()
  (let ((cl (car si:*command-line-args*)))
    (when (or (equal cl "-q")
              (equal cl "-no-init-file"))
      (ed::load-command-bar-info))))

;(add-hook '*pre-startup-hook* #'load-command-bar-info-if-xyzzy-q)

;; 外部ライブラリ

;; xyzzyWiki の reference.xml(->txt) を利用して Help を便利に
(require "ref2doc")
(reference-to-docstring)

;; クリッカブル URI
(require "clickable-uri")
(global-set-key '(#\C-c #\C-o) 'clickable-uri-open)
(defun goto-next-url ()
  (interactive)
  (scan-buffer ed::*clickable-uri-regexp* :regexp t :no-dup t))

;; タブを右クリックしたときのメニュー拡張
(require "tabmenu")
