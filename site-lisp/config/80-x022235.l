;; xyzzy 0.2.2.236 以降に拡張された関数などを使う場合はこちら

(defun chdir-to-system-root ()
  (chdir (si:system-root)))
;;(add-hook '*post-startup-hook* 'chdir-to-system-root)

;; HTML
(setq *html-default-doctype* "HTML5.0")
