;;; winapp.l

(defun charmap ()
  "文字コード表:特殊文字を選択して、ドキュメントにコピーすることができます。"
  (interactive)
  (launch-application "charmap.exe"))

(defun wincalc ()
  "電卓を起動します."
  (interactive)
  (launch-application "calc.exe"))
