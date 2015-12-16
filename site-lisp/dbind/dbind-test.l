;;; dbind-test.l

(require "dbind")
;(require "defmac")
(require "cmu_loop")
(require "unittest/simple-test")

(defun iota (n)
  (loop for i from 1 to n collect i))

(deftest destructuring-bind ()
  ;; http://www.lispworks.com/documentation/HyperSpec/Body/m_destru.htm
  (destructuring-bind ((a &optional (b 'bee)) one two three)
      `((alpha) ,@(iota 3))
    (list a b three two one))
  =>  (alpha bee 3 2 1)

  (destructuring-bind (x (y1 &optional y2) z) '(1 (2) 3)
    (list x y1 y2 z))
  => (1 2 nil 3)

  ;; http://d.hatena.ne.jp/tomoyuki28jp/20090210/1234254645
  (destructuring-bind (x y) (list "x" "y")
    (list :x x :y y))
  => (:x "x" :y "y")

  (destructuring-bind (x &optional y) (list "x")
    (list :x x :y y))
  => (:x "x" :y nil)

  (destructuring-bind (&key x y) (list :y "y" :x "x")
    (list :x x :y y))
  => (:x "x" :y "y")

  ;; http://d.hatena.ne.jp/Nobuhisa/20080731/1217441623
  (destructuring-bind (a (b . c) (d) . e) '(1 (2 . 3) (4) 5 6 7)
    (list a b c d e))
  => (1 2 3 4 (5 6 7))

  (destructuring-bind (a (b . c) (d) . e) '(1 (2 . 3) (4) 5 6 7)
    (append (list a b c d) e))
  => (1 2 3 4 5 6 7)

  (destructuring-bind (&rest a) '(1 (2 . 3) (4) 5 6 7)
    a)
  => (1 (2 . 3) (4) 5 6 7)

  (destructuring-bind (a &key b (c 0)) '(1 :b 2)
    (list a b c))
  => (1 2 0)

  ;; http://www.gigamonkeys.com/book/beyond-lists-other-uses-for-cons-cells.html
  (destructuring-bind (x y z) (list 1 2 3)
    (list :x x :y y :z z))
  => (:x 1 :y 2 :z 3)

  (destructuring-bind (x y z) (list 1 (list 2 20) 3)
    (list :x x :y y :z z))
  => (:x 1 :y (2 20) :z 3)

  (destructuring-bind (x (y1 y2) z) (list 1 (list 2 20) 3)
    (list :x x :y1 y1 :y2 y2 :z z))
  => (:x 1 :y1 2 :y2 20 :z 3)

  (destructuring-bind (x (y1 &optional y2) z) (list 1 (list 2 20) 3)
    (list :x x :y1 y1 :y2 y2 :z z))
  => (:x 1 :y1 2 :y2 20 :z 3)

  (destructuring-bind (x (y1 &optional y2) z) (list 1 (list 2) 3)
    (list :x x :y1 y1 :y2 y2 :z z))
  => (:x 1 :y1 2 :y2 nil :z 3)

  (destructuring-bind (&key x y z) (list :x 1 :y 2 :z 3)
    (list :x x :y y :z z))
  => (:x 1 :y 2 :z 3)

  (destructuring-bind (&key x y z) (list :z 1 :y 2 :x 3)
    (list :x x :y y :z z))
  => (:x 3 :y 2 :z 1)

  ;; http://kyle-burton.livejournal.com/14446.html
  (destructuring-bind (first second &key third)
      '(1 2 :third 3)
    (list first second third))
  => (1 2 3)

  (destructuring-bind (a (b (c d e (f g) h i j)) &rest remainder)
      '(1 (2 (3 4 5 (6 7) 8 9 10)) 11 12 13 14 15)
    (list a b c d e f g h i j remainder))
  => (1 2 3 4 5 6 7 8 9 10 (11 12 13 14 15))
  )
