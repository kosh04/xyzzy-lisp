;;; cl-test.l

(require "cl")
(require "unittest/simple-test")

(deftest read-sequence (:compare equalp)
  ;; buffer > input
  (let ((buffer (make-array 10))
        (input (make-string-input-stream "XYZZY")))
    (values
     (read-sequence buffer input)
     buffer))
  => 5
  => #(#\X #\Y #\Z #\Z #\Y nil nil nil nil nil)

  ;; buffer < input
  (let ((buffer (make-array 5))
        (input (make-string-input-stream "0123456789ABCDEF")))
    (values
     (read-sequence buffer input)
     buffer))
  => 5
  => #(#\0 #\1 #\2 #\3 #\4)

  ;; read whole input-stream
  (let ((buffer (make-array 5))
        (input (make-string-input-stream "0123456789ABCDEF")))
    (let (acc)
      (do ((bytes (read-sequence buffer input)
                  (read-sequence buffer input)))
          ((zerop bytes))
        (push (cons bytes (subseq buffer 0 bytes)) acc))
      (nreverse acc)))
  => ((5 . #(#\0 #\1 #\2 #\3 #\4))
      (5 . #(#\5 #\6 #\7 #\8 #\9))
      (5 . #(#\A #\B #\C #\D #\E))
      (1 . #(#\F)))
  )

