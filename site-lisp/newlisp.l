;;; -*- Mode: Lisp; Package: Editor -*-
;;;
;;; This file is NOT part of xyzzy.
;;;

(provide "newlisp")

(in-package "editor")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "lispmode")
  (require "shell")
  (require "wip/winapi"))

(export '(*newlisp-exe* *newlisp-dll*))

(defvar *newlisp-directory* (or (si:getenv "NEWLISPDIR")
                                (merge-pathnames "newlisp" (si:getenv "PROGRAMFILES"))))
(defvar *newlisp-exe* (merge-pathnames "newlisp.exe" *newlisp-directory*))
(defvar *newlisp-dll* (merge-pathnames "newlisp.dll" *newlisp-directory*))

(export '(newlisp-eval
          newlisp-eval-region
          newlisp-eval-last-sexp
          newlisp-eval-buffer
          newlisp-eval-defun
          newlisp-mode
          newlisp-shell
          newlisp-kill-process
          newlisp-manual
          *newlisp-mode-hook*))

#|
(defun newlisp-eval-once ()
  (interactive)
  (let ((msg (user::command-substitution
              (format nil "~A -e ~S"
                      *newlisp-exe*
                      (save-excursion
                        (buffer-substring (progn (backward-sexp) (point))
                                          (progn (forward-sexp) (point))))))))
    (setq msg (string-trim '(#\LFD #\TAB #\SPC) msg))
    (if (string-match "^ERR:" msg)
        (ding))
    (cond (*prefix-args*
           (indent-for-comment)
           (insert msg))
          ((find #\LFD msg)
           (message-box msg))
          (t (message "~A" msg)))))
|#

(defvar *newlisp-process* nil)
(defvar *newlisp-process-buffer* nil)
(defvar *newlisp-process-buffer-name* " *newLISP log*")
(defvar *newlisp-process-encoding* *encoding-utf8n*)
(defvar *newlisp-output-stream* nil)
(defvar *newlisp-context* "MAIN")

(defun newlisp-process (&key (if-does-not-exist :error))
  (or *newlisp-process*
      (case if-does-not-exist
        (:error (error "サブプロセスが走ってないで"))
        (:create (newlisp-make-process)))))

(defun newlisp-make-process ()
  (setq *newlisp-process-buffer* (get-buffer-create *newlisp-process-buffer-name*)
        *newlisp-output-stream* (make-buffer-stream *newlisp-process-buffer*))
  ;; options: -C force prompts
  (let ((proc (make-process (format nil "~A -C -w \"~A\""
                                    (get-short-path-name *newlisp-exe*)
                                    (default-directory))
                            :output *newlisp-process-buffer*
                            :incode *newlisp-process-encoding*
                            :outcode *newlisp-process-encoding*)))
    (set-process-filter proc 'newlisp-filter)
    (set-process-sentinel proc 'newlisp-sentinel)
    (setq *newlisp-process* proc)
    *newlisp-process*))

(defun newlisp-filter (proc str)
  (format *newlisp-output-stream* "~A" str)
  (let (next-context)
    ;; trim PROMPT "> "
    (if (string-match "\n\\(.*\\)> $" str)
        (setq str (substring str 0 (match-beginning 0))))
    (setq next-context (let ((match (match-string 1)))
                         (cond ((null match) "")
                               ((string= match "") "MAIN")
                               (t match)))
          str (string-left-trim '(#\LFD) str))
    (funcall *newlisp-output-function* str *newlisp-context*)
    (setq *newlisp-context* next-context)))

(defun newlisp-sentinel (proc)
  (let ((buf *newlisp-process-buffer*))
    ;; プロセス死んだ後もログ残した方がいいの？
    (and buf (delete-buffer buf)))
  (close *newlisp-output-stream*)
  (setq *newlisp-process* nil
        *newlisp-process-buffer* nil
        *newlisp-output-stream* nil)
  ;; (run-hook-with-args '*newlisp-kill-process-hook*)
  (refresh-screen))

(defparameter *newlisp-output-function*
  #'(lambda (str context)
      (when (string-match "^ERR:" str) (ding))
      ;; *prefix-args* をここで参照するのがありなのか分からない
      (cond (*prefix-args*
             (if (find #\LFD str) (newline) (indent-for-comment))
             (insert str))
            ((find #\LFD str)
             (popup-string str (point)))
            (t
             (minibuffer-message "~A> ~A"
                                 (if (string= context "MAIN") "" context)
                                 str)))
      (refresh-screen)))

(defun newlisp-eval (str-sexp &optional stream)
  (interactive "snewLISP eval: ")
  (let ((proc (newlisp-process :if-does-not-exist :create)))
    (format *newlisp-output-stream* "~A~%" str-sexp)
    (labels ((sendln (str)
               (process-send-string proc (concat str *shell-ret*))))
      (sendln "[cmd]")
      (sendln str-sexp)
      (sendln "[/cmd]"))))

(defun newlisp-eval-region (from to &optional stream)
  (interactive "r")
  (newlisp-eval (buffer-substring from to) stream))

(defun newlisp-eval-last-sexp (&optional stream)
  (interactive "p")
  (let ((opoint (point)))
    (unwind-protect
        (newlisp-eval-region (progn (backward-sexp 1 'noerror) (point))
                             (progn (forward-sexp) (point))
                             stream)
      (goto-char (max (point) opoint)))))
  
(defun newlisp-eval-defun ()
  (interactive)
  (save-excursion
    (mark-defun)
    (unwind-protect
        (newlisp-eval-region (region-beginning) (region-end))
      (set-mark t))))

(defun newlisp-kill-process ()
  (interactive)
  ;; (newlisp-eval "(exit)")
  (kill-process (newlisp-process)))

#|
;; UTF-8 で通信することで日本語もそこそこ使える
;; call-process より make-process かなあ
;; (call-process ~ :wait nil) <= 待たない方が良い
(defun newlisp-eval-buffer (args)
  ;; (interactive "P")
  (interactive (list (if *prefix-args* (read-string "newLISP exec args: ") "")))
  ;; (setq args (if args (read-string "newLISP exec args: ") ""))
  (unless (stringp args)
    (error "文字列引数を頂戴な"))
  (user::with-temp-file (out)
    (user::with-temp-file (exe)
      (write-region (point-min) (point-max) exe nil *encoding-utf8n*)
      (call-process (format nil "~A ~A ~A" *newlisp-exe* exe args)
                    :output out :show :minimize :wait t))
    (cond ((plusp (file-length out))
           (and (with-open-file (e out :direction :input)
                  (let (line)
                    (dotimes (i 3 t)
                      (setq line (read-line e nil ""))
                      (if (string-match "^ERR:" line)
                          (error line)))))
                (let ((*expected-fileio-encoding* *encoding-utf8n*))
                  (declare (special *expected-fileio-encoding*))
                  (with-output-to-temp-buffer ("*newLISP output*")
                    (insert-file-contents out)))))
          (t
           (message "newLISP: no output")))))
|#

;; マルチバイト使うならファイルの文字コードはutf8n
;; 文字化けするのはコンソールの問題なのか？
(defun newlisp-eval-buffer (args)
  (interactive (list (if *prefix-args*
                         (read-string "newLISP exec args: ")
                         "")))
  (execute-subprocess (format nil "~A \"~A\" ~A"
                              (get-short-path-name *newlisp-exe*)
                              (get-buffer-file-name)
                              args)
                      nil (prog1
                              ;; バッファの文字コード変更しても意味ない気がするなあ
                              (get-buffer-create #1="*newLISP output*")
                            (set-buffer-fileio-encoding
                             *newlisp-process-encoding* #1#))))

(defun newlisp-shell (&optional usedos)
  (interactive "P")
  (let ((*eshell* (format nil "~A -C -w ~A"
                          (get-short-path-name *newlisp-exe*)
                          (default-directory)))
        (*shell-mode-hook*
         (list #'(lambda ()
                   (rename-buffer "*newLISP*")
                   (set-buffer-fold-type-none)
                   )))
        (*default-process-encoding* *newlisp-process-encoding*))
    (if usedos
        (launch-application *eshell*)
        (shell))))

(defvar *newlisp-keyword-file* "newLISP")
(defvar *newlisp-keyword-hash-table* nil)
(defvar *newlisp-mode-hook* nil)
(defvar *newlisp-completion-list* nil)

(defun newlisp-completion ()
  (interactive)
  (or *newlisp-completion-list*
      (setq *newlisp-completion-list*
            (make-list-from-keyword-table *newlisp-keyword-hash-table*))
      (return-from newlisp-completion nil))
  (user::with-lisp-syntax-table
    (let ((from (save-excursion (skip-syntax-spec-backward "w_") (point))))
      (do-completion from (point)
                     :list-ignore-case
                     *newlisp-completion-list*))))

(defvar *newlisp-mode-syntax-table* nil)
(unless *newlisp-mode-syntax-table*
  (setq *newlisp-mode-syntax-table* (make-syntax-table))
  (copy-syntax-table *lisp-mode-syntax-table* *newlisp-mode-syntax-table*)
  (set-syntax-match *newlisp-mode-syntax-table* #\{ #\})
  (set-syntax-start-comment *newlisp-mode-syntax-table* #\# nil)
  (set-syntax-end-comment *newlisp-mode-syntax-table* #\LFD nil t))

(defparameter *newlisp-mode-map*
  (let ((keymap (copy-keymap ed::*lisp-mode-map*)))
    ;; (define-key keymap #\TAB 'lisp-indent-line)
    ;; (define-key keymap #\C-j 'newlisp-eval-last-sexp)
    (define-key keymap '(#\C-x #\C-e) 'newlisp-eval-last-sexp)
    (define-key keymap #\M-C-x 'newlisp-eval-defun)
    (define-key keymap '(#\C-c #\C-i) 'newlisp-completion)
    keymap))

(defun newlisp-mode ()
  (interactive)
  (kill-all-local-variables)
  (let ((ed::*lisp-mode-hook* nil))
    (lisp-mode))
  (setq buffer-mode 'newlisp-mode
        mode-name "newLISP")
  (use-keymap *newlisp-mode-map*)
  (use-syntax-table *newlisp-mode-syntax-table*)
  (and *newlisp-keyword-file*
       (null *newlisp-keyword-hash-table*)
       (setq *newlisp-keyword-hash-table*
             (load-keyword-file *newlisp-keyword-file*)))
  (when *newlisp-keyword-hash-table*
    (make-local-variable 'keyword-hash-table)
    (setq keyword-hash-table *newlisp-keyword-hash-table*))
  ;; (newlisp-process :if-does-not-exist :create)
  (run-hooks '*newlisp-mode-hook*))

(defvar *newlisp-manual-link-alist*
  '(("!" . "shell") ("+-*/%" . "arithmetic") ("Ab" . "abort") ("Ap" . "append") ("As" . "asin") ("Ba" . "base64-dec") ("Ca" . "callback") ("Cl" . "clean") ("Co" . "copy") ("Cu" . "current-line") ("De" . "dec") ("Di" . "difference") ("Do" . "do-until") ("En" . "encrypt") ("Ex" . "exec") ("Fi" . "file-info") ("Fl" . "flat") ("Ga" . "gammaln") ("Gl" . "global") ("In" . "inc") ("La" . "lambdap") ("Li" . "listp") ("Ma" . "macrop") ("Mu" . "mul") ("Net" . "net-accept") ("New" . "new") ("Nt" . "nth") ("Pa" . "pack") ("Pr" . "pretty-print") ("Ra" . "randomize") ("Rea" . "read-buffer") ("Reg" . "regex") ("Sea" . "search") ("Seq" . "sequence") ("Sl" . "sleep") ("St" . "starts-with") ("Sy" . "sync") ("Ti" . "time-of-day") ("Tr" . "truep") ("Ut" . "utf8") ("Wr" . "write-file") ("+, -, *, /,%" . "arithmetic") ("<, >, =," . "logical") ("<=, >=, !=" . "logical") (":" . "colon") ("and" . "and") ("append" . "append") ("apply" . "apply") ("args" . "args") ("assoc" . "assoc") ("begin" . "begin") ("bind" . "bind") ("case" . "case") ("catch" . "catch") ("chop" . "chop") ("clean" . "clean") ("cond" . "cond") ("cons" . "cons") ("constant" . "constant") ("count" . "count") ("curry" . "curry") ("def-new" . "def-new") ("define" . "define") ("define-macro" . "define-macro") ("difference" . "difference") ("do-until" . "do-until") ("do-while" . "do-while") ("doargs" . "doargs") ("dolist" . "dolist") ("dostring" . "dostring") ("dotimes" . "dotimes") ("dotree" . "dotree") ("dup" . "dup") ("ends-with" . "ends-with") ("exists" . "exists") ("eval" . "eval") ("expand" . "expand") ("first" . "first") ("filter" . "filter") ("find" . "find") ("find-all" . "find-all") ("flat" . "flat") ("fn" . "fn") ("for" . "for") ("for-all" . "for-all") ("if" . "if") ("if-not" . "if-not") ("index" . "index") ("intersect" . "intersect") ("lambda" . "lambda") ("lambda-macro" . "lambda-macro") ("last" . "last") ("length" . "length") ("let" . "let") ("letex" . "letex") ("letn" . "letn") ("list" . "list") ("local" . "local") ("lookup" . "lookup") ("map" . "map") ("match" . "match") ("member" . "member") ("not" . "not") ("nth" . "nth") ("or" . "or") ("pop" . "pop") ("pop-assoc" . "pop-assoc") ("push" . "push") ("quote" . "quote") ("ref" . "ref") ("ref-all" . "ref-all") ("rest" . "rest") ("replace" . "replace") ("reverse" . "reverse") ("rotate" . "rotate") ("select" . "select") ("set" . "set") ("set-ref" . "set-ref") ("set-ref-all" . "set-ref-all") ("setf setq" . "setf") ("silent" . "silent") ("slice" . "slice") ("sort" . "sort") ("starts-with" . "starts-with") ("swap" . "swap") ("unify" . "unify") ("unique" . "unique") ("unless" . "unless") ("until" . "until") ("when" . "when") ("while" . "while") ("address" . "address") ("bits" . "bits") ("char" . "char") ("encrypt" . "encrypt") ("eval-string" . "eval-string") ("explode" . "explode") ("float" . "float") ("format" . "format") ("get-char" . "get-char") ("get-float" . "get-float") ("get-int" . "get-int") ("get-long" . "get-long") ("get-string" . "get-string") ("int" . "int") ("join" . "join") ("lower-case" . "lower-case") ("name" . "name") ("pack" . "pack") ("parse" . "parse") ("regex" . "regex") ("regex-comp" . "regex-comp") ("setf" . "setf") ("source" . "source") ("string" . "string") ("sym" . "sym") ("title-case" . "title-case") ("trim" . "trim") ("unicode" . "unicode") ("unpack" . "unpack") ("upper-case" . "upper-case") ("utf8" . "utf8") ("utf8len" . "utf8len") ("abs" . "abs") ("acos" . "acos") ("acosh" . "acosh") ("add" . "add") ("asin" . "asin") ("asinh" . "asinh") ("atan" . "atan") ("atanh" . "atanh") ("atan2" . "atan2") ("beta" . "beta") ("betai" . "betai") ("binomial" . "binomial") ("ceil" . "ceil") ("cos" . "cos") ("cosh" . "cosh") ("crc32" . "crc32") ("crit-chi2" . "crit-chi2") ("crit-z" . "crit-z") ("dec" . "dec") ("div" . "div") ("erf" . "erf") ("exp" . "exp") ("factor" . "factor") ("fft" . "fft") ("floor" . "floor") ("flt" . "flt") ("gammai" . "gammai") ("atan" . "gammaln") ("gcd" . "gcd") ("ifft" . "ifft") ("inc" . "inc") ("log" . "log") ("min" . "min") ("max" . "max") ("mod" . "mod") ("mul" . "mul") ("pow" . "pow") ("round" . "round") ("sequence" . "sequence") ("series" . "series") ("sgn" . "sgn") ("sin" . "sin") ("sinh" . "sinh") ("sqrt" . "sqrt") ("sub" . "sub") ("tan" . "tan") ("tanh" . "tanh") ("det" . "det") ("invert" . "invert") ("mat" . "mat") ("multiply" . "multiply") ("transpose" . "transpose") ("array" . "array") ("array-list" . "array-list") ("array?" . "arrayp") ("<<, >>" . "bit_shift") ("&" . "bit_and") ("|" . "bit_inclusive") ("^" . "bit_exclusive") ("~" . "bit_not") ("atom?" . "atomp") ("context?" . "contextp") ("directory?" . "directoryp") ("empty?" . "emptyp") ("file?" . "filep") ("float?" . "floatp") ("global?" . "globalp") ("integer?" . "integerp") ("lambda?" . "lambdap") ("legal?" . "legalp") ("list?" . "listp") ("macro?" . "macrop") ("NaN?" . "NaNp") ("nil?" . "nilp") ("null?" . "nullp") ("number?" . "numberp") ("primitive?" . "primitivep") ("protected?" . "protectedp") ("quote?" . "quotep") ("string?" . "stringp") ("symbol?" . "symbolp") ("true?" . "truep") ("zero?" . "zerop") ("date" . "date") ("date-value" . "date-value") ("parse-date" . "parse-date") ("now" . "now") ("time" . "time") ("time-of-day" . "time-of-day") ("amb" . "amb") ("bayes-query" . "bayes-query") ("bayes-train" . "bayes-train") ("normal" . "normal") ("prob-chi2" . "prob-chi2") ("prob-z" . "prob-z") ("rand" . "rand") ("random" . "random") ("randomize" . "randomize") ("seed" . "seed") ("search" . "search") ("fv" . "fv") ("irr" . "irr") ("nper" . "nper") ("npv" . "npv") ("pv" . "pv") ("pmt" . "pmt") ("append-file" . "append-file") ("close" . "close") ("device" . "device") ("exec" . "exec") ("load" . "load") ("open" . "open") ("peek" . "peek") ("print" . "print") ("println" . "println") ("read-buffer" . "read-buffer") ("read-char" . "read-char") ("read-file" . "read-file") ("read-key" . "read-key") ("read-line" . "read-line") ("save" . "save") ("seek" . "seek") ("write-buffer" . "write-buffer") ("write-char" . "write-char") ("write-file" . "write-file") ("write-line" . "write-line") ("change-dir" . "change-dir") ("copy-file" . "copy-file") ("delete-file" . "delete-file") ("directory" . "directory") ("file-info" . "file-info") ("make-dir" . "make-dir") ("real-path" . "real-path") ("remove-dir" . "remove-dir") ("rename-file" . "rename-file") ("abort" . "abort") ("destroy" . "destroy") ("fork" . "fork") ("pipe" . "pipe") ("process" . "process") ("semaphore" . "semaphore") ("share" . "share") ("spawn" . "spawn") ("sync" . "sync") ("wait-pid" . "wait-pid") ("base64-enc" . "base64-enc") ("base64-dec" . "base64-dec") ("delete-url" . "delete-url") ("get-url" . "get-url") ("put-url" . "put-url") ("post-url" . "post-url") ("xml-error" . "xml-error") ("xml-parse" . "xml-parse") ("xml-type-tags" . "xml-type-tags") ("net-accept" . "net-accept") ("net-close" . "net-close") ("net-connect" . "net-connect") ("net-error" . "net-error") ("net-eval" . "net-eval") ("net-interface" . "net-interface") ("net-listen" . "net-listen") ("net-local" . "net-local") ("net-lookup" . "net-lookup") ("net-peer" . "net-peer") ("net-peek" . "net-peek") ("net-ping" . "net-ping") ("net-receive" . "net-receive") ("net-receive-from" . "net-receive-from") ("net-receive-udp" . "net-receive-udp") ("net-select" . "net-select") ("net-send" . "net-send") ("net-send-to" . "net-send-to") ("net-send-udp" . "net-send-udp") ("net-service" . "net-service") ("net-sessions" . "net-sessions") ("command-event" . "command-event") ("pretty-print" . "pretty-print") ("prompt-event" . "prompt-event") ("read-expr" . "read-expr") ("$" . "systemsymbol") ("callback" . "callback") ("context" . "context") ("copy" . "copy") ("debug" . "debug") ("default" . "default") ("delete" . "delete") ("env" . "env") ("error-event" . "error-event") ("error-number" . "error-number") ("exit" . "exit") ("global" . "global") ("import" . "import") ("main-args" . "main-args") ("new" . "new") ("ostype" . "ostype") ("reset" . "reset") ("set-locale" . "set-locale") ("signal" . "signal") ("sleep" . "sleep") ("symbols" . "symbols") ("sys-error" . "sys-error") ("sys-info" . "sys-info") ("timer" . "timer") ("throw" . "throw") ("throw-error" . "throw-error") ("trace" . "trace") ("trace-highlight" . "trace-highlight") ("cpymem" . "cpymem") ("dump" . "dump"))
  "newLISP: (シンボル名 . URLリンク名) の連想リスト.")

(defun read-newlisp-symbol ()
  (assoc (completing-read "newLISP manual: "
                          #1=*newlisp-manual-link-alist*
                          :default (user::current-word t)
                          :case-fold t
                          :must-match t)
         #1# :test #'string-equal))

(defun newlisp-manual (str-function)
  (interactive (list (cdr (read-newlisp-symbol))))
  (shell-execute (concat "http://www.newlisp.org/downloads/newlisp_manual.html#"
                         str-function)
                 t))

(export 'newlisp-manual-from-text)
(defun newlisp-manual-from-text (str)
  (interactive
      (list (let (acc)
              (maphash (lambda (key val)
                         (push key acc))
                       ;; newlisp-mode を一度も呼び出していないとキーワードファイルを読み込まずにエラーになるな…
                       *newlisp-keyword-hash-table*)
              (completing-read "newLISP: " acc
                               :default (user::current-word t)
                               :must-match t :case-fold t))))
  ;; (find-file-other-window "C:/home/lxuser/newlisp/newlisp_manual.txt" nil t)
  (pop-to-buffer
   (prog2
       (find-file-other-window "C:/home/lxuser/newlisp/newlisp_manual.txt" nil t)
       (find-buffer "newlisp_manual.txt")))
  (goto-char (point-min))
  (scan-buffer (concat "*syntax: (" str)))
(define-key ed::*newlisp-mode-map* '(#\C-c #\h) 'newlisp-manual-from-text)

#|
;; その１
(long-operation
  (with-open-file (stream (merge-pathnames "newlisp_index.html" ed::*newlisp-directory*))
    (do ((kwd nil)
         (line #1=(read-line stream nil nil) #1#))
        ((null line) (nreverse kwd))
      (and (string-match "<a href=\"newlisp_manual.html#\\(.+\\)\" target=\"body\">\\(.+\\)</a>"
                         line)
           (pushnew (cons (ed::protect-match-data
                            (substitute-string (ed::protect-match-data
                                                 (substitute-string (match-string 2) "&lt;" "<"))
                                               "&amp;" "&"))
                          (match-string 1))
                    kwd :test #'equal)))))

;; その２
(save-excursion
  (set-buffer "newlisp_manual.html")
  (goto-char (point-min))
  (let ((lnk nil)
        (regex (compile-regexp "<a href=\"#\\(.+?\\)\">")))
    (while (scan-buffer regex :regexp t :no-dup t)
      (pushnew (match-string 1) lnk :test #'string-equal))
    (sort lnk #'string<)))
("GNUFDL" "GNUGPL" "NaNp" "XML" "abort" "abs" "acos" "acosh" "add" "address" "amb" "and" "append" "append-file" "appendix" "apply" "args" "arithmetic" "array" "array-funcs" "array-list" "arrayp" "arrays" "asin" "asinh" "assoc" "atan" "atan2" "atanh" "atomp" "base64-dec" "base64-enc" "bayes-query" "bayes-train" "begin" "beta" "betai" "bind" "binomial" "bit_and" "bit_exclusive" "bit_inclusive" "bit_not" "bit_operators" "bit_shift" "bits" "case" "catch" "ceil" "change-dir" "char" "chop" "cilk" "clean" "close" "cmd_help" "colon" "colon_operator" "command-event" "commas" "cond" "cons" "constant" "context" "context_data" "context_modules" "context_objects" "context_rules" "context_vars" "contextp" "contexts" "copy" "copy-file" "cos" "cosh" "count" "cpymem" "crc32" "crit-chi2" "crit-z" "current-line" "curry" "daemon" "date" "date-value" "debug" "dec" "decimal_point" "def-new" "default" "default_function" "define" "define-macro" "delete" "delete-file" "delete-url" "deprecated" "destroy" "destructice" "destructive" "det" "device" "difference" "direct_exec" "directories_unix" "directories_win32" "directory" "directory_management" "directoryp" "distributed" "div" "dll" "do-until" "do-while" "doargs" "dolist" "dolust" "dostring" "dotimes" "dotree" "dump" "dup" "emptyp" "encrypt" "ends-with" "env" "environment" "erf" "error-event" "error-number" "error-text" "error_codes" "eval" "eval-string" "eval_rules" "example_prodcons" "exec" "exists" "exit" "exp" "expand" "explode" "expressions" "factor" "fft" "file-info" "filep" "filter" "financial" "find" "find-all" "first" "flat" "float" "floating_point" "floatp" "floor" "flow_and_or" "flow_catch_throw" "flt" "fn" "foop" "for" "for-all" "forcing_prompt" "fork" "format" "func_memory" "function_ref" "functions" "functions_alphabetical" "fv" "gammai" "gammaln" "gcd" "get-char" "get-float" "get-int" "get-long" "get-string" "get-url" "global" "globalp" "hash" "http_api" "http_mode" "if" "if-not" "ifft" "implicit_default" "implicit_indexing" "implicit_modify" "implicit_rest_slice" "import" "importing_libraries" "inc" "index" "indexing" "inetd_daemon" "initialization" "input_output" "int" "int_float" "integerp" "internals" "internationalization" "intersect" "introduction" "invert" "irr" "join" "lambda" "lambda-macro" "lambda_expressions" "lambdap" "last" "legalp" "length" "let" "letex" "letn" "linking" "list" "list_processing" "listp" "load" "loading_contexts" "local" "local_domain_server" "log" "logging" "logical" "lookup" "lower-case" "macrop" "main-args" "make-dir" "make_nondestructive" "map" "mat" "match" "matrices" "max" "max_mem" "member" "min" "mod" "montecarlo" "mul" "multi_processing" "multiply" "name" "naming" "net-accept" "net-close" "net-connect" "net-error" "net-eval" "net-interface" "net-listen" "net-local" "net-lookup" "net-peek" "net-peer" "net-ping" "net-receive" "net-receive-from" "net-receive-udp" "net-select" "net-send" "net-send-to" "net-send-udp" "net-service" "net-sessions" "new" "newlisp_classes" "newlisp_objects" "nil_and_true" "nilp" "no_init" "normal" "not" "now" "nper" "npv" "nth" "nullp" "numberp" "open" "options" "or" "ostype" "overwrite" "pack" "parse" "parse-date" "pass_big" "pattern" "peek" "pipe" "pmt" "pop" "pop-assoc" "post-url" "pow" "predicates" "pretty-print" "primitivep" "print" "println" "prob-chi2" "prob-z" "process" "processes" "prompt" "prompt-event" "protectedp" "protection" "push" "put-url" "pv" "quote" "quotep" "rand" "random" "randomize" "read-buffer" "read-char" "read-expr" "read-file" "read-key" "read-line" "real-path" "ref" "ref-all" "reflection" "regex" "regex-comp" "remove-dir" "rename-file" "replace" "reset" "rest" "return" "reverse" "rotate" "round" "save" "scope_context" "scope_global" "scoping" "search" "seed" "seek" "select" "semaphore" "sequence" "sequence_creating" "serializing" "series" "set" "set-locale" "set-ref" "set-ref-all" "setf" "setq" "sgn" "share" "shared-lib" "shell" "signal" "silent" "sin" "sinh" "sleep" "slice" "socket_tcpip" "sort" "source" "spawn" "sqrt" "stack_size" "starts-with" "startup" "string" "string_operators" "stringp" "sub" "swap" "switching" "sym" "symbol_names" "symbolp" "symbols" "sync" "sys-error" "sys-info" "system_functions" "system_symbols" "systemsymbol" "tanh" "tcpip_server" "throw" "throw-error" "time" "time-of-day" "timedate" "timer" "title-case" "trace" "trace-highlight" "transpose" "trim" "truep" "type_ids" "unicode" "unicode_utf8" "unify" "unique" "unless" "unpack" "until" "upper-case" "url_files" "users_manual" "utf8" "utf8_capable" "utf8len" "uuid" "wait-pid" "when" "while" "working_dir" "write-buffer" "write-char" "write-file" "write-line" "xml-error" "xml-parse" "xml-type-tags" "zerop")
441

;; キーワード用？
(with-open-file (stream どこか :direction :output)
  (write (shell-command-to-string "newlisp -n -e \"(dolist (s (symbols)) (println s))\"")
         :stream stream
         :escape nil
         :pretty t)
  (values t))

|#

(export 'newlisp-show-log-buffer)
(defun newlisp-show-log-buffer ()
  (interactive)
  (switch-to-buffer *newlisp-process-buffer-name*))

;; prompt-debugger-mode
;; " 0>"
;; [-> 2 ] s|tep n|ext c|ont q|uit >
;; (read-char *keyboard*)
;; newlisp-show-log-buffer
;; tail-f 使えないのかね

(defmacro defindent (operator indentation)
  ;; シンボルが参照 (export) できないとインデントが効かないので注意
  (let ((symbol (intern (string operator) "user")))
    `(setf (get ',symbol 'ed:lisp-indent-hook) ',indentation)))

(defindent define defun)
(defindent fn lambda)
(defindent begin progn)
(defindent silent progn)
(defindent local let)
(defindent letex let)
(defindent for 1)
(defindent lambda-macro defmacro)
(defindent define-macro lambda)
(defindent until 1)
(defindent letn let*)
; (defindent sgn 1)
(defindent letrec let)          ; scheme?
(defindent letrec* let*)


(in-package "winapi")

(c:*define-dll-entry LPSTR newlispEvalStr (LPSTR)
  *newlisp-dll* "newlispEvalStr")

;;; newlisp.l ends here
