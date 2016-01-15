;;; libmagic-test.l

(require "libmagic")
(require "unittest/simple-test")

(deftest magic-buffer ()
  (magic-buffer "")
  => "empty"
  (magic-buffer "#!/bin/bash")
  => "a /bin/bash script text executable")

(deftest magic-file ()
  (magic-file "~/xyzzy.exe")
  => "PE32 executable for MS Windows (GUI) Intel 80386 32-bit"
  (magic-file (si:getenv "ComSpec"))
  => "PE32 executable for MS Windows (console) Intel 80386 32-bit"
  (magic-file ".")
  => "directory"
  (magic-file "/")
  => "directory"
  (magic-file (si:system-root))
  => "directory"
  (magic-file "foobar.exe")
  !! simple-error)