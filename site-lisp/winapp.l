;;; winapp.l

(defun charmap ()
  "�����R�[�h�\:���ꕶ����I�����āA�h�L�������g�ɃR�s�[���邱�Ƃ��ł��܂��B"
  (interactive)
  (launch-application "charmap.exe"))

(defun wincalc ()
  "�d����N�����܂�."
  (interactive)
  (launch-application "calc.exe"))