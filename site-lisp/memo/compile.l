;;; memo/compile

;; XyzzyLisp �̃R���p�C����Bytecode�ɂ���

(require "compile")

(compiler::process-toplevel
 '(defun 1+- (x) (cons (1+ x) (1- x))))
 