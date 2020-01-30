;;; config/hexl

;; バイナリファイル編集 (hexl-mode)
(defparameter hexl-program "hexl.exe")
(require "hexl/hexl")

(defun query-hexl-mode ()
  "ファイルサイズが大きすぎるとhexlがもたつくのでユーザに尋ねる."
  (interactive)
  (let ((size (file-length (get-buffer-file-name)))
	(max (* #.(expt 2 20) 3))) ; 3Mbyteくらい
    (if (and (< max size)
             (not (y-or-n-p "読み込みが遅くなると思うけどいい？(~A byte)" size)))
        (fundamental-mode)
        (progn
          (revert-buffer *encoding-binary*)
          (hexl-mode)))))

;; (pushnew '("\\.exe$" . query-hexl-mode) *auto-mode-alist* :test 'equal)
;; (pushnew '("\\.dll$" . query-hexl-mode) *auto-mode-alist* :test 'equal)
;; (delete "\\.exe$" *auto-mode-alist* :key #'car :test #'equal)

(defun hexl-coloring-hook ()
  (make-local-variable 'regexp-keyword-list)
  (setq regexp-keyword-list (compile-regexp-keyword-list
                             '(("^\\w\\{8\\}:" nil 2)
                               ("  .+$" nil :comment)))))

(add-hook 'hexl-mode-hook 'hexl-coloring-hook)
(add-hook 'hexl-mode-hook 'toggle-read-only)
