;;; memo/compile

;; XyzzyLisp のコンパイラやBytecodeについて

(require "compile")

(compiler::process-toplevel
 '(defun 1+- (x) (cons (1+ x) (1- x))))
 