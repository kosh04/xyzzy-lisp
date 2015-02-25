;;; -*- Mode: Lisp; Package: EDITOR; Encoding: Shift_JIS -*-
;;;
;;; newlisp.l --- newLISP編集用メジャーモード
;;;
;;; This file is NOT part of xyzzy.
;;;

#|
### これは何？

LISP風軽量スクリプト言語 newLISP を編集するための簡単なメジャーモードです

今のところ以下の操作が出来ます

* newlispファイルの編集 (インデントなどはlisp-modeに依存)
* 他のlisp-modeと同様にS式を評価する
* 作成したスクリプトの実行
* 静的キーワード補完
* マニュアルを調べる

### インストール

(require "newlisp")
;; プロセス起動時の引数指定 (お好みで)
(setq *newlisp-switches* "-C -s10000")

### TODO

* インデントをlisp-modeから間借りしているのは直すべきか
* デバッガモード用のインターフェースが欲しいかも
  prompt-debugger-mode
  " 0>"
  [-> 2 ] s|tep n|ext c|ont q|uit >
  (read-char *keyboard*)

### Known Bugs

* 制御文字を含む出力が正しく表示されない "^@" => ""

### Change Log

2008-11-18 version 0.01 初版
2009-04-01 version 0.02 それなりに使えるようになったはず
2009-08-01 newLISPのバージョンアップに伴うマイナーチェンジ
2009-12-01 DLLを扱えるように (newlispEvalStr)
2010-01-21 整理整頓
2010-04-19 newLISP v10.2.1に対応
2011-05-20 コメント行(#)や文字列({}[text]~[/text])の色付けに対応
	ドキュメント、キーワードファイルの更新
2011-06-13 ??? newlisp-view-log 関数を追加
2012-05-14 ??? キーワードファイルの更新 (v.10.4.3)
		変数 *run-newlisp-other-window* の追加

;;; by KOBAYASHI Shigeru (kosh)  <shigeru.kb[at]gmail.com>
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

(defvar *newlisp-exe* "newlisp.exe")
(defvar *newlisp-dll* "newlisp.dll")

;; NOTE: "-C" Force prompt when running newLISP in pipe I/O mode for Emacs.
(defvar *newlisp-switches* "-C"
  "プロセスを起動するためのコマンドライン引数を指定します.")

(defvar *newlisp-load-init-p* t
  "non-nilならばプロセス起動時に設定ファイル(.init.lsp)を読み込みます.")

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
          newlisp-signal-process
          newlisp-change-dir
          newlisp-completion
          newlisp-show-log-buffer
          newlisp-browse-manual
          *run-newlisp-other-window*
          *newlisp-mode-hook*))

(defvar *newlisp-process* nil)
(defvar *newlisp-process-buffer* nil)
(defvar *newlisp-process-buffer-name* " *newLISP log*")
(defvar *newlisp-process-encoding* *encoding-utf8n*)
(defvar *newlisp-output-stream* nil)
(defvar *newlisp-context* "MAIN")

;;; プロセス

(defun newlisp-process (&key (if-does-not-exist :error))
  (or (and (processp *newlisp-process*)
           (eq :run (process-status *newlisp-process*))
           *newlisp-process*)
      (case if-does-not-exist
        (:error (error "サブプロセスが走ってないで"))
        (:create (newlisp-make-process))
        (:skip nil))))

(defun newlisp-make-process (&key (type :process))
  (setq *newlisp-process-buffer* (get-buffer-create *newlisp-process-buffer-name*)
        *newlisp-output-stream* (make-buffer-stream *newlisp-process-buffer*))
  (let ((command *newlisp-exe*)
        (switches (split-string *newlisp-switches* " ")))
    (if (null *newlisp-load-init-p*)
        (pushnew "-n" switches :test #'equal))
    (let ((proc (make-process (format nil "\"~A\" ~{~A~^ ~}" command switches)
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
  "プロセスの出力用関数.")

(defun newlisp-eval (str-sexp &optional stream)
  "文字列STR-SEXPをS式として評価します."
  (interactive "snewLISP eval: ")
  ;; (declare (ignore stream))
  (let ((proc (newlisp-process :if-does-not-exist :create)))
    (format *newlisp-output-stream* "~A~%" str-sexp)
    (labels ((sendln (str)
               (process-send-string proc (concat str *shell-ret*))))
      (sendln "[cmd]")
      (sendln str-sexp)
      (sendln "[/cmd]"))))

(defun newlisp-eval-region (from to &optional stream)
  "リージョンを評価します."
  (interactive "r")
  (newlisp-eval (buffer-substring from to) stream))

(defun newlisp-eval-last-sexp (&optional stream)
  "ポイントの位置から見たひとつ前のS式を評価します."
  (interactive "p")
  (let ((opoint (point)))
    (unwind-protect
        (newlisp-eval-region (progn (backward-sexp 1 t) (point))
                             (progn (forward-sexp) (point))
                             stream)
      (goto-char (max (point) opoint)))))
  
(defun newlisp-eval-defun ()
  "ポイントの位置から見たトップレベルのS式を評価します."
  (interactive)
  (save-excursion
    (mark-defun)
    (unwind-protect
        (newlisp-eval-region (region-beginning) (region-end))
      (set-mark t))))

(defun newlisp-load-file (file)
  "FILEをnewlisp用ファイルとして読み込みます."
  (interactive "fnewLISP load: " :default0 (get-buffer-file-name))
  (newlisp-eval (format nil "(load {~A})" (namestring file))))

(defun newlisp-change-dir (dir)
  "プロセスの作業ディレクトリを変更します."
  (interactive "DchangeDir: ")
  (newlisp-eval (format nil "(change-dir {~A})" dir)))

(defun newlisp-kill-process ()
  "プロセスを強制的に終了させます."
  (interactive)
  #+NIL (newlisp-eval "(exit)")
  (kill-process (newlisp-process))
  )

(defun newlisp-signal-process ()
  "プロセスにシグナルを送ります."
  (interactive)
  (signal-process (newlisp-process))) ; SIGINT?

;(defun newlisp-kill-process-maybe ()
;  (interactive)
;  (if (ignore-errors (newlisp-process))
;      (newlisp-kill-process)))

(defun newlisp-eval-buffer (&optional (args ""))
  "編集中のファイルをnewlispスクリプトとして実行します.
ARGSを追加の引数として指定することも出来ます."
  (interactive (list (if *prefix-args* (read-string "newLISP exec args: "))))
  (let ((command (format nil "\"~A\" \"~A\" ~A"
                     *newlisp-exe*
                     (get-buffer-file-name)
                     args))
        (*default-process-encoding* *newlisp-process-encoding*))
    (execute-subprocess command nil "*newLISP output*")))

(defun run-newlisp-console (&optional command)
  "コマンドプロンプト上でnewlispを起動します."
  (interactive)
  (launch-application (or command *newlisp-exe*)))

(defvar *run-newlisp-other-window* t
  "non-nilならばrun-newlispを別のウィンドウで開きます.")

(defun run-newlisp ()
  "バッファ上でnewlispを起動します."
  (interactive)
  (let ((command (format nil "\"~A\" ~A ~A"
                         *newlisp-exe*
                         (if *newlisp-load-init-p* "" "-n")
                         *newlisp-switches*))
        (*default-process-encoding* *newlisp-process-encoding*)
        (obuf (selected-buffer)))
    (set-buffer (get-buffer-create "*newLISP*"))
    (let ((proc (buffer-process (selected-buffer))))
      (and proc (eq (process-status proc) :run)
           (return-from run-newlisp t)))
    (goto-char (point-max))
    ;; newlisp-shell-mode
    (progn
      (setq mode-name "newLISP REPL")
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
                  :eol-code *eol-guess*)
    (when *run-newlisp-other-window*
      (display-buffer obuf))
    t))

;;; 編集

(defvar *newlisp-keyword-file* "newLISP") ; ~/etc/newLISP
(defvar *newlisp-keyword-hash-table* nil)
(defvar *newlisp-mode-hook* nil)
(defvar *newlisp-completion-list* nil)

(defun newlisp-completion ()
  "キーワードファイルを基に補完を行います."
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
  "newLISP編集モード."
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
  (make-local-variable 'regexp-keyword-list)
  (setq regexp-keyword-list
        (compile-regexp-keyword-list
         '(
           ; 文字列 (あまり複雑なものに対応できてない)
           ("\\[text\\]\\(?:.\\|\n\\)*?\\[/text\\]" nil :string nil)
           ("{[^{}]*?}" nil :string nil)
           ; 一行コメント
           ("#.*$" nil :comment nil)
           )))
  ;(newlisp-process :if-does-not-exist :create)
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
  "プロセスのログバッファを表示します."
  (interactive)
  (unless (and *newlisp-process-buffer*
               (not (deleted-buffer-p *newlisp-process-buffer*)))
    (error "プロセスが存在しません"))
  (display-buffer *newlisp-process-buffer*))

(export 'newlisp-view-log)

(defun newlisp-view-log (file)
  "ログファイル(-l,-L オプション)を参照します."
  (interactive "fLog file: ")
  (require "tail-f")
  (let ((*expected-eol-code* *eol-crlf*))
    (tail-f file)))


;;; インデント

(defmacro defindent (operator indentation)
  ;; シンボルが参照 (export) できないとインデントが効かないので注意
  (let ((symbol (intern (string operator) "user")))
    `(setf (get ',symbol 'ed:lisp-indent-hook) ',indentation)))

(defindent define defun)
(defindent fn lambda)
(defindent fn-macro lambda)
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
(defindent dostring 1)          ; (dostring (sym string [break]) body)


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
(defun newlisp-browse-manual (name &optional text-mode)
  "リファレンスを参照します."
  (interactive (list (read-newlisp-symbol "newLISP manual: ")
                     *prefix-args*))
  (if text-mode
      (newlisp-browse-manual-from-text name)
    (shell-execute (concat "http://www.newlisp.org/downloads/newlisp_manual.html#"
                           (or (cdr (assoc name *newlisp-manual-link-alist*
                                           :test #'string-equal))
                               name))
                   t)))

(export '(*newlisp-manual*
          newlisp-browse-manual-from-text))

;; ==========================
;; テキストファイルから調べる
;; ==========================
;; 
;; 以下のいずれかのHTMLファイルをテキストに変換させたものを用意する必要あり
;; - "http://www.newlisp.org/downloads/newlisp_manual.html"
;; - "C:/Program Files/newlisp/newlisp_manual.html"
;; テキスト化する方法: html2txt, ブラウザの「ページを保存（テキストファイル）」
;; リファレンスのバージョンによっては使えないかもしれない
;; -> "http://github.com/kosh04/newlisp-files.git/newlisp_manual.txt"
;;    (上記のファイルをテキストに変換したもの)
(defvar *newlisp-manual* "newlisp_manual.txt")

(defun newlisp-browse-manual-from-text (keyword)
  "テキストマニュアルからリファレンスを参照します."
  (interactive (list (read-newlisp-symbol "newLISP manual: ")))
  (find-file-other-window *newlisp-manual* nil 'nomsg)
  #+NIL
  (pop-to-buffer (prog2
                     (find-file-other-window *newlisp-manual* nil t)
                     (find-buffer "newlisp_manual.txt")))
  (if (equal keyword "setf") (setq keyword "setq"))
  (if (equal keyword "parse-date") (setq keyword "date-parse"))
  (unless (eq buffer-mode 'newlisp-mode)
    (newlisp-mode))
  (toggle-read-only t)
  (goto-char (point-min))
  ;; (scan-buffer (format nil "^    ~A[ ]?" (regexp-quote keyword)) :regexp t)
  ;; (recenter 0)
  ;; (scan-buffer (format nil "syntax: (~A[ )]" (regexp-quote keyword)) :regexp t)
  (scan-buffer (format nil "        syntax: (~A[ )]"
                       (regexp-quote keyword))
               :regexp t)
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
            (format nil "newlisp -n -e \"(dolist (s (symbols MAIN)) (println s))\""))
           :stream out
           :escape nil
           :pretty t))
  t)
|#


;;; 共有ライブラリ (newlisp.dll)

(export '(newlisp-eval-string))

(c:*define-dll-entry winapi::LPSTR newlispEvalStr (winapi::LPSTR)
  *newlisp-dll*)

(defun newlisp-eval-string (str-sexp)
  "文字列STR-SEXPをS式として評価します."
  (let ((addr (newlispEvalStr (si:make-string-chunk str-sexp)))
        ;; FIXME: 適当すぎる
        (size #x1000))
    (if (plusp addr)
        (string-right-trim '(#\LFD)
          (si:unpack-string (si:make-chunk nil size nil addr) 0)))))

#|
(newlisp-eval-string "(+ 3 7)") ;=> "10"
|#

(pushnew '("\\.lsp$" . newlisp-mode) *auto-mode-alist* :test #'equal)

;;; newlisp.l ends here
