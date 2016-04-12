;;; wandbox-test.l

(require "wandbox")
(require "unittest/simple-test")

;; test assoc
(defun alist-subsetp (x y &key (test #'equal))
  (check-type x list)
  (check-type y list)
  (loop for (key . value) in x
        always (funcall test value (cdr (assoc key y :test #'equal)))))

(defun alist-equal (x y &key (test #'equal))
  (and (alist-subsetp x y :test test)
       (alist-subsetp y x :test test)))

;; test plist
(defun plist-subsetp (pitem plist &key (test #'equal))
  (check-type pitem list)
  (check-type plist list)
  (loop for (key value) on pitem by #'cddr
        always (funcall test value (getf plist key))))

(defun plist-equal (x y)
  (and (plist-subsetp x y)
       (plist-subsetp y x)))


(deftest alist-subsetp ()
  "Test alist-subsetp for test."
  (alist-subsetp '()
                 '())
  => t
  (alist-subsetp '()
                 '((a . 10)))
  => t
  (alist-subsetp '((a . 10))
                 '())
  => nil
  (alist-subsetp '((a . 10))
                 '((a . 10)))
  => t
  (alist-subsetp '(("a" . 10))
                 '(("a" . 10)))
  => t
  (alist-subsetp '((a . 10))
                 '((a . 10) (b . 10)))
  => t
  (alist-subsetp '((a . 10))
                 '((b . 10) (a . 10) (c . 30)))
  => t
  (alist-subsetp '((a . 10) (b . 10))
                 '((a . 10)))
  => nil)

(deftest alist-equal ()
  "Test alist-equal for test."
  (alist-equal '() '())
  => t
  (alist-equal '((b . 20) (c . 30) (a . 10))
               '((a . 10) (b . 20) (c . 30)))
  => t
  (alist-equal '((a . 10) (b . 20) (c . 30))
               '((a . 10) (b . 20)))
  => nil)


(deftest merge-plist ()
  "Test merge-plist."
  (wandbox::merge-plist)
  => ()
  (wandbox::merge-plist '(:a 1))
  => (:a 1)
  (plist-equal (wandbox::merge-plist '(:a 1 :b 2)
                                     '(:a 9)
                                     '(:c 3))
               '(:a 9 :b 2 :c 3))
  => t)

(deftest pick ()
  "Test plist pick util."
  (wandbox::pick '())
  => ()
  (wandbox::pick '(:a 1 :b 2 :c 3 :d 4))
  => ()
  (plist-equal (wandbox::pick '(:a 1 :b 2 :c 3 :d 4) :a :b :z)
               '(:b 2 :a 1))
  => t)

(deftest request-data ()
  "Test build-request-data."
  (alist-equal (wandbox::build-request-data
                :compiler "gcc-head"
                :options "warning"
                :code "main(){}")
               '(("compiler" . "gcc-head")
                 ("options" . "warning")
                 ("code" . "main(){}")
                 ("stdin" . "")
                 ("compiler-option-raw" . "")
                 ("runtime-option-raw" . "")
                 ("save" . wandbox::false)))
  => t
  (alist-subsetp '(("compiler" . "ruby-head"))
                 (wandbox::build-request-data :name "ruby HEAD"))
  => t
  (alist-subsetp '(("compiler" . "mruby-head"))
                 (wandbox::build-request-data :name "mruby HEAD"))
  => t
  (alist-subsetp '(("compiler" . "ruby-head"))
                 (wandbox::build-request-data :lang "ruby"))
  => t)

(deftest profile ()
  "Test profile."
  (plist-subsetp '(:lang "C++" :name "gcc HEAD" :compiler "gcc-head")
                 (wandbox::find-profile :compiler "gcc-head"))
  => t
  (alist-subsetp '(("compiler" . "gcc-4.8.2-c"))
                 (wandbox::build-request-data :lang "C"))
  => t)

(deftest nickname ()
  "Test profile nickname"
  (let ((p '(:nickname "mruby")))
    (plist-subsetp p (apply #'wandbox::find-profile p)))
  => t)

(deftest buffer-profile ()
  "Test buffer-profile."
  (plist-equal (let ((file (merge-pathnames "Documents/GitHub/emacs-wandbox/test/sample.c" (si:getenv "USERPROFILE"))))
                 (with-open-file (s file)
                   (wandbox::scan-profile s)))
               '(:compiler "clang-3.3-c"
                 :compiler-option "-lm"))
  => t
  ;; buffer-profile より直接のオプション指定が優先される
  (alist-subsetp '(("compiler" . "gcc-head")
                   ("options" . "warnings")
                   ("compiler-option-raw" . "-lm")
                   ("runtime-option-raw" . ""))
                 (let ((file (merge-pathnames "Documents/GitHub/emacs-wandbox/test/sample.c" (si:getenv "USERPROFILE"))))
                   (wandbox::build-request-data :file file
                                                :compiler "gcc-head"
                                                :options "warnings")))
  => t)

(deftest compile ()
  "Test compile."
  (alist-equal (wandbox :compiler "gcc-head" :code "int main(){ return 1; }" :sync t)
               '(("status" . "1")))
  => t)

(deftest other-server ()
  "Test server wnadbox.fetus.jp"
  (alist-equal (wandbox :compiler "php-7.0.0"
                        :code "<?php echo phpversion();"
                        :server-name "fetus"
                        :sync t)
               '(("program_message" . "7.0.0")
                 ("program_output" . "7.0.0")
                 ("status" . "0")))
  => t)

;;(run-tests)
