;;; -*- Mode: Lisp; Package: EDITOR; Encoding: Shift_JIS -*-
;;;
;;; newlisp.l --- newLISP編集用メジャーモード
;;;
;;; Copyright (C) 2008-2010 KOBAYASHI Shigeru (kosh)
;;;
;;; This file is NOT part of xyzzy.
;;;

#|
### これは何？

LISP風軽量スクリプト言語`newLISP'を編集するための簡単なメジャーモードです

今のところ以下の操作が出来ます

* 他のlisp-modeと同様にS式を評価する
* 作成したスクリプトの実行
* キーワード補完
* マニュアルを調べる

### インストール

(require "newlisp")
(pushnew '("\\.lsp" . newlisp-mode) *auto-mode-alist* :test #'equal)

### TODO:

* インデントをlisp-modeから間借りしているのは直すべきか
* デバッガモードが欲しい
  prompt-debugger-mode
  " 0>"
  [-> 2 ] s|tep n|ext c|ont q|uit >
  (read-char *keyboard*)
  ログ機能(-l,-L)とtail-f使えないのかね

### Known Bugs:

* 制御文字を含む出力が正しく表示されない "^@" => ""

### Change Log:

2008-11-18 version 0.01 初版
2009-04-01 version 0.02 それなりに使えるようになったはず
2009-08-01 newLISPのバージョンアップに伴うマイナーチェンジ
2009-12-01 DLLを扱えるように (newlispEvalStr)
2010-01-21 整理整頓
2010-04-19 newLISP v10.2.1に対応

|#

;;; Code:

(provide "newlisp")

(in-package "editor")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "lispmode")
  (require "shell")
  (require "wip/winapi"))

(export '(*newlisp-exe*
          *newlisp-dll*
          *newlisp-switches*
          *newlisp-load-init-p*))

(defvar *newlisp-directory*
  (or (si:getenv "NEWLISPDIR")
      (merge-pathnames "newlisp/" (si:getenv "PROGRAMFILES"))))
(defvar *newlisp-exe* (merge-pathnames "newlisp.exe" *newlisp-directory*))
(defvar *newlisp-dll* (merge-pathnames "newlisp.dll" *newlisp-directory*))

;; *** -C: Force prompt when running newLISP in pipe I/O mode for Emacs.
(defvar *newlisp-switches* "-C -s10000"
  "newLISP: コマンドラインオプション")
;; -n オプションの有無
(defvar *newlisp-load-init-p* t
  "起動時に初期化ファイル(init.lsp)を読み込むかどうか.")

(export '(newlisp-eval
          newlisp-eval-region
          newlisp-eval-last-sexp
          newlisp-eval-buffer
          newlisp-eval-defun
          newlisp-load-file
          newlisp-mode
          run-newlisp
          run-newlisp-console
          newlisp-kill-process
          newlisp-completion
          newlisp-show-log-buffer
          newlisp-browse-manual
          *newlisp-mode-hook*))

(defvar *newlisp-process* nil)
(defvar *newlisp-process-buffer* nil)
(defvar *newlisp-process-buffer-name* " *newLISP log*")
(defvar *newlisp-process-encoding* *encoding-utf8n*)
(defvar *newlisp-output-stream* nil)
(defvar *newlisp-context* "MAIN")


;;; プロセス

(defun newlisp-process (&key (if-does-not-exist :error))
  (or
   (and (processp *newlisp-process*)
        (eq :run (process-status *newlisp-process*))
        *newlisp-process*)
   (case if-does-not-exist
     (:error (error "サブプロセスが走ってないで"))
     (:create (newlisp-make-process)))))

(defun newlisp-make-process (&key (type :process))
  (setq *newlisp-process-buffer* (get-buffer-create *newlisp-process-buffer-name*)
        *newlisp-output-stream* (make-buffer-stream *newlisp-process-buffer*))
  (let ((command (if (file-exist-p *newlisp-exe*)
                     (get-short-path-name *newlisp-exe*)
                   *newlisp-exe*))
        (switches (split-string *newlisp-switches* " ")))
    (if (null *newlisp-load-init-p*)
        (pushnew "-n" switches :test #'equal))
    (let ((proc (make-process (format nil "~{~A~^ ~}" `(,command ,@switches))
                              :output *newlisp-process-buffer*
                              :incode *newlisp-process-encoding*
                              :outcode *newlisp-process-encoding*)))
      (set-process-filter proc #'newlisp-filter)
      (set-process-sentinel proc #'newlisp-sentinel)
      (setq *newlisp-process* proc)
      *newlisp-process*)))

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
          str (string-left-trim "\n" str))
    (funcall *newlisp-output-function* str *newlisp-context*)
    (refresh-screen)
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
  (refresh-screen)
  (message "newlisp exit with code ~D" (process-exit-code proc)))

(defvar *newlisp-output-function*
  #'(lambda (str context)
      (when (string-match "^ERR:" str) (ding))
      ;; FIXME: *prefix-args* をここで参照するのがありなのか分からない
      (cond (*prefix-args*
             (when (find #\LFD str)
               (newline))
             (indent-for-comment)
             (insert str))
            ((find #\LFD str)
             (popup-string str (point)))
            (:else
             (minibuffer-message "~A> ~A"
                                 (if (string= context "MAIN") "" context)
                                 str))))
  "newLISPプロセスの出力用関数.")

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
        (newlisp-eval-region (progn (backward-sexp 1 t) (point))
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

(defun newlisp-load-file (file)
  (interactive "fnewLISP load: " :default0 (get-buffer-file-name))
  (newlisp-eval (format nil "(load {~A})" file)))

(defun newlisp-kill-process ()
  (interactive)
  #+NIL (newlisp-eval "(exit)")
  #+NIL (signal-process (newlisp-process))
  (kill-process (newlisp-process))
  )

(defun newlisp-kill-process-maybe ()
  (interactive)
  (if (ignore-errors (newlisp-process))
      (newlisp-kill-process)))

(defun newlisp-eval-buffer (args)
  "編集中のファイルをnewlisp.exeの引数として実行する."
  (interactive (list (if *prefix-args*
                         (read-string "newLISP exec args: ")
                       "")))
  (let ((*default-process-encoding* *newlisp-process-encoding*))
    (execute-subprocess (format nil "~A \"~A\" ~A"
                                (get-short-path-name *newlisp-exe*)
                                (get-buffer-file-name)
                                args)
                        nil "*newLISP output*")))

(defun run-newlisp-console (&optional command)
  (interactive)
  (launch-application (or command *newlisp-exe*)))

(defun run-newlisp (&optional consolep)
  (interactive "P")
  (let ((command (format nil "~A ~A ~A"
                         (get-short-path-name *newlisp-exe*)
                         (if *newlisp-load-init-p* "" "-n")
                         *newlisp-switches*))
        (*default-process-encoding* *newlisp-process-encoding*))
    (when consolep
      (run-newlisp-console command)
      (return-from run-newlisp t))
    (set-buffer (get-buffer-create "*newLISP*"))
    (let ((proc (buffer-process (selected-buffer))))
      (and proc (eq (process-status proc) :run)
           (return-from run-newlisp t)))
    (goto-char (point-max))
    ;; newlisp-shell-mode
    (progn
      (setq mode-name "newLISP Shell")
      (setq buffer-mode 'shell-mode)
      (use-keymap *shell-mode-map*)
      (setq need-not-save t)
      (setq auto-save nil)
      ;(set-buffer-fold-type-none)
      (setq *shell-ret* "\n" *shell-echo* nil))
    (make-process command
                  :output (selected-buffer)
                  :incode *newlisp-process-encoding*
                  :outcode *newlisp-process-encoding*
                  :eol-code *eol-guess*)))


;;; 編集

(defvar *newlisp-keyword-file* "newLISP") ; ~/etc/newLISP
(defvar *newlisp-keyword-hash-table* nil)
(defvar *newlisp-mode-hook* nil)
(defvar *newlisp-completion-list* nil)

(defun newlisp-completion ()
  (interactive)
  (or *newlisp-completion-list*
      (setq *newlisp-completion-list*
            (make-list-from-keyword-table *newlisp-keyword-hash-table*))
      (return-from newlisp-completion nil))
  (let ((from (save-excursion (skip-syntax-spec-backward "w_") (point))))
    (do-completion from (point)
                   :list-ignore-case
                   *newlisp-completion-list*)))

(defvar *newlisp-mode-syntax-table* nil)
(unless *newlisp-mode-syntax-table*
  (setq *newlisp-mode-syntax-table* (make-syntax-table))
  (copy-syntax-table *lisp-mode-syntax-table* *newlisp-mode-syntax-table*)
  (set-syntax-match *newlisp-mode-syntax-table* #\{ #\})
  ;; 効いていない気がする...
  (set-syntax-start-comment *newlisp-mode-syntax-table* #\# nil)
  (set-syntax-end-comment *newlisp-mode-syntax-table* #\LFD nil t)
  (set-syntax-start-multi-comment *newlisp-mode-syntax-table* "[text]")
  (set-syntax-end-multi-comment *newlisp-mode-syntax-table* "[/text]")
  )

(defvar *newlisp-mode-map*
  (let ((keymap (copy-keymap ed::*lisp-mode-map*)))
    ;; (define-key keymap #\TAB 'lisp-indent-line)
    ;; (define-key keymap #\C-j 'newlisp-eval-last-sexp)
    (define-key keymap #\F5 'newlisp-eval-buffer)
    (define-key keymap #\M-: 'newlisp-eval)
    (define-key keymap '(#\C-x #\C-e) 'newlisp-eval-last-sexp)
    (define-key keymap '(#\C-c #\C-r) 'newlisp-eval-region)
    (define-key keymap #\M-C-x 'newlisp-eval-defun)        ; ESC C-x
    (define-key keymap '(#\C-c #\TAB) 'newlisp-completion) ; C-c C-i
    (define-key keymap #\M-C-i 'newlisp-completion)        ; M-TAB
    (define-key keymap '(#\C-c #\C-z) 'newlisp-show-log-buffer)
    (define-key keymap '(#\C-c #\C-l) 'newlisp-load-file)
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
  (setq comment-start "; " comment-end "") ; or "# "
  ;; (newlisp-process :if-does-not-exist :create)
  (run-hooks '*newlisp-mode-hook*))

(defun newlisp-keyword-list ()
  (if (null *newlisp-keyword-hash-table*)
      (setq *newlisp-keyword-hash-table*
            (load-keyword-file *newlisp-keyword-file*)))
  (make-list-from-keyword-table *newlisp-keyword-hash-table*))

(defun newlisp-current-word ()
  (save-excursion
    (let ((from (progn (skip-syntax-spec-backward "w_") (point)))
          (to (progn (skip-syntax-spec-forward "w_") (point))))
      (when (< from to)
        (buffer-substring from to)))))

(defun newlisp-show-log-buffer ()
  (interactive)
  (unless (and *newlisp-process-buffer*
               (not (deleted-buffer-p *newlisp-process-buffer*)))
    (error "プロセスが存在しません"))
  (display-buffer *newlisp-process-buffer*))


;;; インデント

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
(defindent until 1)             ; (until exp body)
(defindent do-until 1)
(defindent letn let*)           ; (letn (vars) body)
; (defindent sgn 1)
(defindent letrec let)          ; ? scheme
(defindent letrec* let*)
(defindent doargs 1)            ; (doargs (sym [break]) body)
(defindent do-while while)      ; (do-while body)
(defindent dotree 1)            ; (dotree (sym context [bool]) body)


;;; リファレンス

(defvar *newlisp-manual-link-alist*
  '(("!" . "shell")
    ("+" . "arithmetic")
    ("-" . "arithmetic")
    ("*" . "arithmetic")
    ("/" . "arithmetic")
    ("%" . "arithmetic")
    ("<" . "logical")
    (">" . "logical")
    ("=" . "logical")
    ("<=" . "logical")
    (">=" . "logical")
    ("!=" . "logical")
    (":" . "colon")
    ("setf" . "setf")
    ("setq" . "setf")
    ("array?" . "arrayp")
    ("<<" . "bit_shift")
    (">>" . "bit_shift")
    ("&" . "bit_and")
    ("|" . "bit_inclusive")
    ("^" . "bit_exclusive")
    ("~" . "bit_not")
    ("atom?" . "atomp")
    ("context?" . "contextp")
    ("directory?" . "directoryp")
    ("empty?" . "emptyp")
    ("file?" . "filep")
    ("float?" . "floatp")
    ("global?" . "globalp")
    ("integer?" . "integerp")
    ("lambda?" . "lambdap")
    ("legal?" . "legalp")
    ("list?" . "listp")
    ("macro?" . "macrop")
    ("NaN?" . "NaNp")
    ("nil?" . "nilp")
    ("null?" . "nullp")
    ("number?" . "numberp")
    ("primitive?" . "primitivep")
    ("protected?" . "protectedp")
    ("quote?" . "quotep")
    ("string?" . "stringp")
    ("symbol?" . "symbolp")
    ("true?" . "truep")
    ("zero?" . "zerop")
    ("$" . "systemsymbol"))
  "newLISP: (シンボル名 . URLリンク名) の連想リスト.")

(defun read-newlisp-symbol (prompt)
  (completing-read "newLISP manual: "
                   #1=(newlisp-keyword-list)
                   :default (find (newlisp-current-word) #1# :test #'string=)
                   :must-match t
                   :case-fold t))

;; ブラウザから調べる
(defun newlisp-browse-manual (name)
  (interactive (list (read-newlisp-symbol "newLISP manual: ")))
  (shell-execute (concat "http://www.newlisp.org/downloads/newlisp_manual.html#"
                         (or (cdr (assoc name *newlisp-manual-link-alist*
                                         :test #'string-equal))
                             name))
                 t))

(export '(*newlisp-manual*
          newlisp-browse-manual-from-text))

;; 以下のいずれかのHTMLファイルをテキストに変換させたものを用意する必要あり
;; - "http://www.newlisp.org/downloads/newlisp_manual.html"
;; - "C:/Program Files/newlisp/newlisp_manual.html"
;; テキスト化する方法: html2txt, ブラウザの「ページを保存（テキストファイル）」
;; リファレンスのバージョンによっては使えないかもしれない
;; -> "http://github.com/kosh04/newlisp-files.git/newlisp_manual.txt"
;;    (上記のファイルをテキストに変換したもの)
(defvar *newlisp-manual* "newlisp_manual.txt")

;; テキストファイルから調べる
(defun newlisp-browse-manual-from-text (str)
  "テキストマニュアルからリファレンスを参照する."
  (interactive (list (read-newlisp-symbol "newLISP manual: ")))
  (find-file-other-window *newlisp-manual* nil 'nomsg)
  #+NIL
  (pop-to-buffer (prog2
                     (find-file-other-window *newlisp-manual* nil t)
                     (find-buffer "newlisp_manual.txt")))
  (unless (eq buffer-mode 'newlisp-mode)
    (newlisp-mode))
  (toggle-read-only t)
  (goto-char (point-min))
  ;; (scan-buffer (format nil "^    ~A[ ]?" (regexp-quote str)) :regexp t)
  ;; (recenter 0)
  ;; (scan-buffer (format nil "syntax: (~A[ )]" (regexp-quote str)) :regexp t)
  (scan-buffer (format nil "        syntax: (~A[ )]" (regexp-quote str)) :regexp t)
  nil)

(define-key ed::*newlisp-mode-map* '(#\C-c #\h) 'newlisp-browse-manual-from-text)

#|
;; 作成した後に多少の手直しが必要
(defun newlisp-make-keyword-file (&optional filename)
  "newLISPキーワードファイルを作成する."
  (or filename
      (setq filename (merge-pathnames "newLISP.kwd" (etc-path))))
  (with-open-file (out filename
                       :direction :output
                       :if-does-not-exist :create
                       :if-exists :overwrite)
    (format out ";; keyword file for xyzzy -*- mode:newlisp -*-\n")
    (write (shell-command-to-string
            (format nil "newlisp -n -e \"~A\""
                    '(dolist (s (symbols MAIN)) (println s))))
           :stream out
           :escape nil
           :pretty t))
  t)
|#


;;; 共有ライブラリ (newlisp.dll)

(export '(newlisp-eval-string))

(c:*define-dll-entry winapi::LPSTR newlispEvalStr (winapi::LPSTR)
  *newlisp-dll*)

(defun newlisp-eval-string (str)
  (let ((addr (newlispEvalStr (si:make-string-chunk str)))
        ;; FIXME: 適当すぎる
        (size #x1000))
    (if (plusp addr)
        (string-right-trim '(#\LFD)
          (si:unpack-string (si:make-chunk nil size nil addr) 0)))))

#|
(newlisp-eval-string "(+ 3 7)") ;=> "10"
|#

;;; newlisp.l ends here
