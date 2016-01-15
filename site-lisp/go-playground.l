;; -*- Mode: lisp-interaction;-*-

;; https://github.com/kosh04/emacs-go-playground on #xyzzy
;; ”ñ“¯ŠúIO‚ª‚È‚¢‚½‚ßÀs’†‚Í‘€ì–³Œø

(provide "go-playground")

(defpackage #:go-playground
  (:use
   "lisp"
   "editor"
   "json"
   "xml-http-request")
  (:export #:run))

(in-package :go-playground)

(defun -playback (events output)
  (labels ((clear ()
             (erase-buffer output)))
    (setup-temp-buffer output)
    ;(set-buffer output)
    (display-buffer output)
    (with-output-to-buffer (output)
      (clear)
      (dolist (event events)
        (let ((.Message (cdr (assoc "Message" event :test #'equal)))
              (.Delay (cdr (assoc "Delay" event :test #'equal))))
          (when (string-match "^\x0c" .Message)
            (setf (subseq .Message 0 1) "") ; not worked
            (clear))
          (princ .Message)
          (sit-for (/ .Delay 1000000000))
          (do-events))))))

;;;###autoload
(defun run (path)
  (interactive "fGo Playground: ")
  (let ((code (with-output-to-string (out)
                (user::cat path out))))
    (msxml:xhr-post-async "http://play.golang.org/compile"
                          `(:version 2 :body ,code)
                          :key 'msxml:xhr-response-text
                          :oncomplete #'(lambda (data)
                                          (setq data (json:json-decode data))
                                          (-playback (cdr (assoc "Events" data :test #'equal))
                                                     (get-buffer-create "*Go Playground*"))))))

#+nil
(progn
  (go-playground:run (merge-pathnames "Dropbox/Snippet/golang/sl/main.go" (si:getenv "USERPROFILE")))
  (go-playground:run (merge-pathnames "prog/golang/parallel-hakata.go" (si:getenv "USERPROFILE")))
  )

;; end.
