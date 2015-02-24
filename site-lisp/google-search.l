;; google.l --- Google 検索

(provide "google-search")

;; http://hie.s64.xrea.com/xyzzy/note/search.html#search-google
(defun google-search (str)
  (interactive "sGoogle: " :default0 (current-word t))
  (unless (stringp str)
    (error "文字列ちゃうで: ~S" str))
  (let ((url (format nil "~A~{~A~^+~}"
                     "http://www.google.com/search?q="
                     ;; "http://www.google.com/search?hl=ja&lr=lang_ja&num=20&q="
                     ;; "http://search.yahoo.co.jp/search?p="
                     (mapcar #'(lambda (x)
                                 ;; `+'はエンコードされるべきかも
                                 ;; "0-9A-Za-z---._~"
                                 (si:www-url-encode (map-internal-to-utf-8 x) nil t))
                             (split-string str #\SPC)))
             ))
    ;; 標準ブラウザ
    (shell-execute url t)))

(defun google (keyword &key callback)
  (interactive "sGoogle: ")
  (unless keyword
    (setq keyword (read-string "Google: ")))
  (long-operation
    (let ((url (concat "http://www.google.com/search?"
                       "q=" (si:www-url-encode
                             (convert-encoding-from-internal *encoding-utf8n* keyword)))))
      (if (functionp callback)
          (funcall callback url)
        (shell-execute url t)))))

(defun google-search-selection ()
  (interactive)
  (if (pre-selection-p)
      (google-search (selection-start-end (beg end)
                       (buffer-substring beg end)))
      (call-interactively 'google-search)))

(defun add-menu-google ()
  (add-menu-item *app-popup-menu* nil "Google 検索 (&G)"
                 'google-search-selection nil))

(add-hook '*post-startup-hook* 'add-menu-google)

(global-set-key '(#\C-c #\g) 'google-search-selection)
