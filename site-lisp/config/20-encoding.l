;;; config/encoding

;; 新規ファイル
(setq *default-fileio-encoding* *encoding-utf8n*)
(setq *default-eol-code* *eol-lf*)

;; coding:utf-8 は BOM なしでお願い
;; or http://d.hatena.ne.jp/bowbow99/20100430/1272604971
(setf (gethash "utf-8" *mime-charset-name-hash-table*) *encoding-utf8n*)

;; 文字コードの問題 '((cmd . sjis) (bash . euc-jp))
(defun switch-to-process-encoding (encoding)
  (interactive (list (intern (completing-read
                              "Process encoding: "
                              '(sjis euc-jp iso-8bit-jp utf8n)))))
  (setq *default-process-encoding*
        (cdr (assoc encoding `((sjis . ,*encoding-sjis*)
                               (euc-jp . ,*encoding-euc-jp*)
                               (iso-8bit-jp . ,*encoding-iso-8bit-jp*)
                               (utf8n . ,*encoding-utf8n*))))))

;;(global-set-key '(#\C-x #\t #\p) 'switch-to-process-encoding)

(setf (symbol-function 'encode) #'convert-encoding-from-internal
      (symbol-function 'decode) #'convert-encoding-to-internal)

(setf (symbol-function 'utf8->sjis) #'map-utf-8-to-internal
      (symbol-function 'sjis->utf8) #'map-internal-to-utf-8)

;; map-ascii-to-half-width-region
(defun hankaku-region (from to)
  "リージョンの全角->半角変換."
  (interactive "*r")
  (map-to-half-width-region from to :ascii t :katakana t))

(defun zenkaku-region (from to)
  "リージョンの半角->全角変換."
  (interactive "*r")
  (map-to-full-width-region from to :ascii t :katakana t))

(setf (symbol-function 'zenkaku) #'map-to-full-width-string)
(setf (symbol-function 'hankaku) #'map-to-half-width-string)

(setf (symbol-function 'map-url-decode-region) #'url-encoding-decode-region)
(defun url-encoding-decode-selection ()
  (interactive "*")
  (ed::map-selection #'url-encoding-decode-region))

;; 内部エンコーディングが変になる
;; (defun url-encoding-encode-region (from to)
;;   (interactive "*r")
;;   (ed::text-decode-region #'si:www-url-encode from to))

