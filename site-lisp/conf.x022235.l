;; xyzzy 0.2.2.236 �ȍ~�Ɋg�����ꂽ�֐��Ȃǂ��g���ꍇ�͂�����

(defun chdir-to-system-root ()
  (chdir (si:system-root)))
(add-hook '*post-startup-hook* 'chdir-to-system-root)

;; HTML
(setq *html-default-doctype* "HTML5.0")