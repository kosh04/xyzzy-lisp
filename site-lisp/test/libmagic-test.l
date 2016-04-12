;;; libmagic-test.l

(require "libmagic")
(require "unittest/simple-test")

(deftest magic-buffer ()
  (magic-buffer "")
  => "empty"
  (magic-buffer "#!/bin/bash")
  => "a /bin/bash script text executable"
  (magic-buffer (map-internal-to-euc
                 (map 'string #'identity
                      #(#\hiragana_letter_ko
                        #\hiragana_letter_n
                        #\hiragana_letter_ni
                        #\hiragana_letter_ti
                        #\hiragana_letter_ha))))
  => "ISO-8859 text, with no line terminators")

(deftest magic-file ()
  (magic-file "~/xyzzy.exe")
  => "PE32 executable for MS Windows (GUI) Intel 80386 32-bit"
  (magic-file "~/xyzzy.exe" :mime-type t)
  => "application/octet-stream"
  (magic-file "~/xyzzy.exe" :mime-type t :mime-encoding t)
  => "application/octet-stream; charset=binary"
  (magic-file *magic-database-file*)
  => "magic binary file for file(1) cmd (version 7) (little endian)"
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
