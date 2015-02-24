;;; conf.encoding.l

;; coding:utf-8 �� BOM �Ȃ��ł��肢
(setf (gethash "utf-8" *mime-charset-name-hash-table*) *encoding-utf8n*)

;; �����R�[�h�̖�� '((cmd . sjis) (bash . euc-jp))
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
  "���[�W�����̑S�p->���p�ϊ�."
  (interactive "*r")
  (map-to-half-width-region from to :ascii t :katakana t))

(defun zenkaku-region (from to)
  "���[�W�����̔��p->�S�p�ϊ�."
  (interactive "*r")
  (map-to-full-width-region from to :ascii t :katakana t))

(setf (symbol-function 'zenkaku) #'map-to-full-width-string)
(setf (symbol-function 'hankaku) #'map-to-half-width-string)
