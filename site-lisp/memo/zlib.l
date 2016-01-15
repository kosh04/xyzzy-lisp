;; zlib.l

;; zlibのバインディングを作ろうとした途中 (2015-05-26)
;; http://www.zlib.net/manual.html


;; <zconf.h>
(c:define-c-type :uint8 Bytef)

(c:define Z_NULL 0)

(c:define Z_DEFAULT_COMPRESSION   -1)

(c:define-c-struct z-stream
  (Bytef * next-in)
  (c:u_int avail-in)
  (c:u_long total-in)

  (Bytef * next-out)
  (c:u_int avail-out)
  (c:u_long total-out)

  (c:char * msg)
  (c:void* state)

  (c:void * zalloc)
  (c:void * zfree)
  (c:void * opaque)

  (c:int data-type)
  (c:u_long adler)
  (c:u_long reserved)
  )

(c:define-c-type (z-stream *) z-streamp)

;; ZEXTERN const char * ZEXPORT zlibVersion OF((void));
(c:define-dll-entry c:char* zlibVersion () "zlib1.dll")

(defun zlib-version ()
  (si:unpack-string (si:make-chunk nil 16 nil (zlibVersion)) 0 nil t))

;; ZEXTERN int ZEXPORT deflateInit OF((z_streamp strm, int level));
(c:define-dll-entry
  c:int
  deflateInit_ (z-streamp
                c:int
                c:char*
                c:int)
  "zlib1.dll")

(setq z (make-z-stream))
(setf (z-stream-zalloc z) Z_NULL
      (z-stream-zfree z)  Z_NULL
      (z-stream-opaque z) Z_NULL)

(deflateInit_ (si:make-chunk nil
                             (si:chunk-size z)
                             nil
                             (si:chunk-data z))
              Z_DEFAULT_COMPRESSION
              (si:make-string-chunk "1.2.3")
              (si:chunk-size z))

;; (char *)z.msg
;; -> Win32例外が発生しました
;; (si:unpack-string (si:make-chunk nil 1024 nil (z-stream-msg z)) 0 nil t)

(mapcar (lambda (s)
          (cons s (funcall s z)))
        '(z-stream-next-in
          z-stream-avail-in
          z-stream-total-in
          z-stream-next-out
          z-stream-avail-out
          z-stream-total-out
          z-stream-msg
          z-stream-state
          z-stream-zalloc
          z-stream-zfree
          z-stream-opaque
          z-stream-data-type
          z-stream-adler
          z-stream-reserved))

;;=> ((z-stream-next-in . 2949226)
;;    (z-stream-avail-in . 6619251)
;;    (z-stream-total-in . 0)
;;    (z-stream-next-out . 6815843)
;;    (z-stream-avail-out . 2097210)
;;    (z-stream-total-out . 0)
;;    (z-stream-msg . 0)
;;    (z-stream-state . 2402016)
;;    (z-stream-zalloc . 1659403428)
;;    (z-stream-zfree . 1659403452)
;;    (z-stream-opaque . 0)
;;    (z-stream-data-type . 2)
;;    (z-stream-adler . 1)
;;    (z-stream-reserved . 6815852))
