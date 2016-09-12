;; xyzzy 0.2.2.236 ˆÈ~‚ÉŠg’£‚³‚ê‚½ŠÖ”‚È‚Ç‚ğg‚¤ê‡‚Í‚±‚¿‚ç

(defun chdir-to-system-root ()
  (chdir (si:system-root)))
(add-hook '*post-startup-hook* 'chdir-to-system-root)

;; HTML
(setq *html-default-doctype* "HTML5.0")
