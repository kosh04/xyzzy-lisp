;;; -*- Mode: Lisp; Package: USER -*-
;;;
;;; This file is NOT part of xyzzy.
;;;

;;; 他の設定ファイル(conf.*.l)に移行したので読み込まないように
(error "古い設定ファイルです")

#|
TODO
- C 言語の標準関数 (printf etc...) も色をつける
|#

;; テストスイート
;; C:/home/lxuser/code/lisp/cl-ansi-tests-20071218/

;; eldoc (Emacs) の手抜き (M-x: turn-on-ldoc)
;; http://kitaj.no-ip.com/xyzzy/index.html
(require "ldoc")
(push 'fundamental-mode *ldoc-activated-mode-list*) ; *Help*用
(defun toggle-ldoc-with-message ()
  (interactive)
  (toggle-ldoc)
  (message "Toggle ldoc: ~:[OFF~;ON~]" ed::*ldoc-status*))
(global-set-key '(#\C-x #\t #\l) 'toggle-ldoc-with-message)


(defun grep-cmucl (str)
  (interactive "sGrep CMUCL: " :default0 (current-word t))
  (ed::scan-files str "*.lisp"
                  '("C:/home/lxuser/src/cmucl-src-2008-08.tar.bz2/src/code/")))

;; Filer
(defun filer-open-p ()
  "ファイラが開いているならばtを返す."
  (ignore-errors (progn
                   ;; 環境に影響のない filer-* 系の関数ならば何でもいい
                   (filer-modal-p)
                   t)))

(setq *grep-directory-name-hook*
      #'(lambda () (when (filer-open-p) (filer-get-directory))))

;; タグジャンプ
(defvar *xyzzy-source-directories*
  (list (cons "lisp"  "~/lisp")
        (cons "site-lisp" "~/site-lisp")
        (cons "src" "~/src/src")))

(defun jump-xyzzy-tag ()
  (interactive)
  (dolist (dir (cons (default-directory) *load-path*))
    (with-set-directory dir (jump-tag)))
  #+nil
  (or (with-set-directory "~/lisp" (jump-tag))
      (with-set-directory "~/site-lisp" (jump-tag))
      (jump-tag))
  )
(define-key esc-map #\. 'jump-xyzzy-tag)
(define-key esc-map #\, 'back-tag-jump)
(defun direct-xyzzy-tag-jump ()
  (interactive)
  (with-set-directory (merge-pathnames "lisp" (si:system-root))
    (direct-tag-jump)))
(if (boundp 'help-map)
    ;; F1 j
    (define-key help-map #\j 'direct-xyzzy-tag-jump)
  (global-set-key '(#\C-x #\j) 'direct-xyzzy-tag-jump))


(defun tags-jump (dir)
  (interactive "DTags directory: ")
  (with-set-directory dir
    (direct-tag-jump)))

;; ctag
(require "ctags")
(setq *ctags-command-path* (merge-pathnames "bin/ctags.exe" (si:system-root)))
;; (global-set-key #\M-. 'ctags-jump-tag)
;; (global-set-key #\M-\, 'ctags-back-tag-jump)
;; (global-set-key #\M-/ 'ctags-make-tags-file-recursive)
;; (global-set-key #\M-? 'ctags-select-stack)

;; リファレンスを調べる
(require "info-modoki-mode")
(defun imm-refer-symbol (sym)
  (interactive "SReference: ")
  (imm-refer (symbol-name sym)))
(defun imm-describe-function (f)
  (interactive "aDescrive function: ")
  (imm-refer (symbol-name f)))
(defun imm-describe-variable (v)
  (interactive "vDescrive variable: ")
  (imm-refer (symbol-name v)))
(define-key ed::*lisp-mode-map* #\F3 'imm-refer-selection)
(define-key ed::*lisp-interaction-mode-map* #\F3 'imm-refer-selection)
(define-key *info-modoki-mode-map* #\q 'kill-selected-buffer)
(pushnew 'info-modoki-mode *ldoc-activated-mode-list*) ; ldoc を使えるように
(add-hook '*info-modoki-mode-hook* 'turn-on-paren)


;; http://ohkubo.s53.xrea.com/xyzzy/scratch.html 'auto-find-file-read-only も参考
(defun read-only-if-load-path ()
  "*load-path* 内のファイルは read-only にトグルする."
  (when (in-load-path-p (directory-namestring (get-buffer-file-name)))
    (toggle-read-only t)))
(add-hook '*find-file-hooks* 'read-only-if-load-path)

(defun in-load-path-p (dir)
  "DIR が *load-path* のサブディレクトリかどうか."
  (some #'(lambda (parent)
            (sub-directory-p dir parent))
        *load-path*))

;; temp-buffer の削除方法 (暫定)
;; (define-key ed::*fundamental-mode-map* #\q 'kill-selected-buffer)
;; *default-buffer-mode* => 'fundamental-mode

(defun one-line (str &optional (padding #\SPC))
  "文字列を一行にまとめる."
  (if padding
      (substitute padding #\LFD str)
      (remove #\LFD str)))

;; コンソールを使いやすくする
;; nyacus はバッファ上ではうまく動作しないので注意
(defvar *ckw-path* (merge-pathnames "bin/ckw.exe" (si:system-root)))
(defun run-nyacus&ckw-console ()
  (interactive)
  (let ((*eshell* *ckw-path*))
    (run-console)))
;(global-set-key '(#\C-x #\r #\n) 'run-nyacus&ckw-console)
;; (setq *eshell* "bash -i")
;; (setq *eshell* "cmd.exe")

;; 外部コマンドのファイル名だけわかれば、
;; (shell-execute *pathname*) 以外はマクロでまとめられそうだ
;; 起動中のEmacsに渡したい(emacsclient?)
(defvar *emacs-path* "C:/home/emacs/22.1/bin/runemacs.exe")
(defun run-emacs (&optional file)
  "Emacs を起動します。
編集中のファイルを引数に与えることもできます。"
  (interactive (list (when *prefix-args*
                       (read-exist-file-name "To emacs: "
                                             :default (get-buffer-file-name)))))
  (shell-execute *emacs-path* (cwd) (and file (get-short-path-name file))))
;(global-set-key '(#\C-x #\r #\e) 'run-emacs)

;; funsigの代わり。どこまで通用するかな？
(defun arglist-symbol->string (x)
  (cond ((consp x) (mapcar #'arglist-symbol->string x))
        ((member x lambda-list-keywords) (symbol-name x))
        ((stringp x) x)
        (t (string-upcase (prin1-to-string x)))))
;; (arglist-symbol->string (arglist 'reduce))
;; ("FUNCTION" "SEQUENCE" "&key" "FROM-END" ("START" "0") "END" ("INITIAL-VALUE" "NIL" "SV"))

;; http://xyzzy.s53.xrea.com/wiki/index.php?patch%2F28
;; ldoc2で(in-package :editor) なども探すようにする
(defun find-in-package ()
  "Find current package"
  (let ((goal-column (goal-column)))
    (unwind-protect
        (save-excursion
          (and (scan-buffer "^(in-package[ \t\n]" :regexp t :reverse t)
               (find-package (second
                              (read-from-string
                               (buffer-substring (point)
                                                 (progn
                                                   (goto-matched-parenthesis)
                                                   (1+ (point))))
                               nil nil)))))
      (set-goal-column goal-column))))

(defun eldoc ()
  (interactive)
  (let* ((from (save-excursion
                 (while (eq (parse-point-syntax) :string)
                   (backward-char))
                 (up-list -1 t)
                 (forward-char)
                 (point)))
         (to (save-excursion (goto-char from) (forward-sexp 1 t) (point)))
         (symbol nil))
    ;; (if (= from to) (return-from eldoc))
    (multiple-value-bind (name package)
        (values-list (reverse (split-string (buffer-substring from to) ":")))
      ;; (msgbox "~S" (list name package))
      (setq symbol (ignore-errors
                    (find-symbol name (or package
                                          (find-package *buffer-package*)
                                          (find-in-package)
                                          *package*))))
      (if (fboundp symbol)
          (let ((args (arglist-symbol->string (arglist symbol))))
            (popup-string (format nil (cond ((stringp args) "(~S ~A)")
                                            ((consp args) "(~S ~{~A~^ ~})"))
                                  symbol args)
                          (point)))
          (message "関数が見つかりません: ~A" (one-line name))))))

(define-key ed::*lisp-mode-map* #\C-\; 'eldoc)
(define-key ed::*lisp-interaction-mode-map* #\C-\; 'eldoc)

;; (require "re-builder")
(export 'ed::re-builder "editor")
(autoload 'ed::re-builder "re-builder" t nil)


;; Fundamental モードでも括弧の色付け
(defun add-paren-syntax ()
  (let ((syntab (syntax-table)))
    (set-syntax-match syntab #\( #\))
    (set-syntax-match syntab #\[ #\])
    (set-syntax-match syntab #\{ #\})
    ;; 効いてない？
    (set-syntax-match syntab #\（ #\）)
    (set-syntax-match syntab #\「 #\」)
    (set-syntax-match syntab #\【 #\】)
    (set-syntax-match syntab #\『 #\』)
    ))
(add-hook '*fundamental-mode-hook* 'add-paren-syntax)
(add-hook '*text-mode-hook* 'add-paren-syntax)


;; Filer

(defun filer-transpose-window ()
  (interactive)
  (when (filer-dual-window-p)
    (let ((x (filer-get-directory nil))
          (y (filer-get-directory t)))
      (and (filer-set-directory y nil)
           (filer-reload nil nil))
      (and (filer-set-directory x t)
           (filer-reload nil t)))
    t))

;; *filer-follow-links* が non-nil なら勝手にショートカット
;; (ディレクトリ限定) を展開してくれるみたい
(defun filer-chdir->link ()
  "リンク先のディレクトリを開く"
  (interactive)
  (filer-chdir (directory-namestring
                (ed::filer-read-link
                 (filer-get-current-file)))))
(define-key filer-keymap #\C-j 'filer-chdir->link)

;; 「進む」も作りたいが...
(defun filer-backward-directory ()
  "「戻る」"
  (interactive)
  (tagbody
    #1=continue
    (pop ed::*filer-directory-history*)
    (cond ((null ed::*filer-directory-history*)
           (error "これ以上戻れません"))
          ((not (file-exist-p (nth 0 ed::*filer-directory-history*)))
           (go #1#))))
  (filer-set-directory (nth 0 ed::*filer-directory-history*))
  (filer-reload)
  (message "Next Back: ~A" (nth 1 ed::*filer-directory-history*)))
(define-key filer-keymap #\C-b 'filer-backward-directory)

(defun filer-open-dual-window ()
  "一画面ファイラから二画面ファイラを開く."
  (interactive)
  (unless (filer-dual-window-p)
    (let ((*filer-primary-directory* (filer-get-directory)))
      (filer-close nil)
      (open-filer))))

;; http://goo.gl/WSlOd
(defparameter *find-file-follow-link* t
  "non-nilならばファイルを開く際にショートカットを展開します.")
(defun find-file-follow-link (file)
  "tips/.linkを展開する - XyzzyWikiより"
  (if *find-file-follow-link*
      (let ((sh (ignore-errors
                 (resolve-shortcut file))))
        (when sh
          (find-file sh)
          (get-file-buffer sh)))))
(add-hook '*before-find-file-hook* 'find-file-follow-link)


(global-set-key '(#\C-c #\C-f) 'open-filer*)
(define-key filer-keymap #\C-c 'run-console*)
(define-key filer-keymap #\C-e 'open-explorer)
(define-key filer-keymap #\C-t 'filer-transpose-window)
(define-key filer-keymap #\M-2 'filer-open-dual-window)
(define-key filer-keymap #\C-u 'filer-up-directory)
(define-key filer-keymap #\G 'filer-reload)
(define-key filer-keymap #\~ 'filer-delete-backups)
(define-key filer-keymap #\F2 'filer-rename)
(define-key filer-keymap #\Delete #'filer-delete)
(define-key filer-keymap #\M-g 'grep-dialog)


;; 手前に表示 #'toggle-topmost-xyzzy
(require "topmost")
(add-hook '*post-startup-hook* 'ed::topmost-uninstall)
(defun add-menu-topmost ()
  (let ((window-menu (get-menu *app-menu* 'ed:window)))
    (add-menu-separator window-menu)
    (add-menu-item window-menu 'ed:window "常に手前に表示 (&T)"
                   'toggle-topmost-xyzzy
                   #'(lambda () (and (topmost-xyzzy-p) :check)))))
(add-hook '*init-app-menus-hook* 'add-menu-topmost)

;; (provide ".xyzzy") => ".xyzzy"
;; FIXME: goal-column を考慮してない、てか移動するの？
(defun find-buffer-provide ()
  (save-excursion
    (ed::protect-match-data
      (goto-char (point-min))
      (and (or (re-search-forward "(provide \"\\(.+\\)\")" t) ; (privide "foo")
               (re-search-forward "(provide '\\(.+\\))" t))   ; (probide 'foo)
           (match-string 1)))))

;; 再ロードするには以下の要素が必要.
;; - ファイルが一度ロードされている
;; - (provide "***")
(defun recompile-and-load-file ()
  "*.lc があれば再コンパイルとロード."
  (let* ((file (get-buffer-file-name))
         (lc (compile-file-pathname file))
         (encoding (buffer-fileio-encoding)))
    (when (and file
               (member buffer-mode '(lisp-mode lisp-interaction-mode))
               (file-exist-p lc)
               ;; 括弧が足りないとコンパイル時に怒られるので
               (check-parens))
      (if (eq encoding *encoding-sjis*)
          (byte-compile-file file)
          (mc-compile-file file encoding))
      (let ((provide
             ;; pathname-name では"*/*"などの階層provideに対応できない
             (find-buffer-provide)))
        (and provide
             (modulep provide)
             ;; バイトコンパイルされたファイルはsjisなのでmc-*でなくてOK
             (load-file lc))))
    ))

;(defvar *after-save-buffer-hook* nil)
(add-hook '*after-save-buffer-hook* 'recompile-and-load-file)
(defun toggle-recompile ()
  (interactive)
  (let ((hook (member 'recompile-and-load-file *after-save-buffer-hook*)))
    (cond (hook
           (delete-hook '*after-save-buffer-hook* 'recompile-and-load-file))
          (t
           (add-hook '*after-save-buffer-hook* 'recompile-and-load-file)))
    (message "Recompile: ~:[OFF~;ON~]" hook)))
;; (delete-hook 'ed::*after-save-buffer-hook* 'recompile-file)

(defvar *paren-regexp-keyword-list*
  (compile-regexp-keyword "[()]" nil '(:color 15)))
(defun set-paren-color ()
  "括弧を薄くしたらS式が見やすいかもしれない"
  (make-local-variable 'regexp-keyword-list)
  ;; ed::*clickable-uri-regexp* 共存
  (push *paren-regexp-keyword-list* regexp-keyword-list))
(add-hook '*lisp-mode-hook* 'set-paren-color)
(add-hook '*lisp-interaction-mode-hook* 'set-paren-color)

(global-set-key #\F12 'lisp-mode)
(global-set-key #\C-F12 'lisp-interaction-mode)
(set-function-bar-label #\F12 "Lisp mode")
(set-function-bar-label #\C-F12 "Lisp Interaction mode")

#|
(symbol-describe 'ed::search)
=> ("search" #<package: editor> nil nil (editor::minibuffer-history-variable *minibuffer-search-string-history*))

先に'user::searchが定義されると
名前が衝突するためexportできません: lisp::search

先に'lisp::searchを定義すると
(symbol-package 'user::search)	; #<package: lisp>

->シンボルの共有?
(package-use-list :user)	; (#<package: lisp> #<package: editor>)
|#
;; (load-library "cmu_search")
;(load-library "corman_search")

;; cmu_loop より性能がいいみたい
;; 今のcmuclのloop移植したら便利かな？
;; http://homepage1.nifty.com/bmonkey/lisp/ :xyzzy/loop.lzh
;; (defun install-loop () (trap-errors (load-library "loop") (use-package "loop")))
;; (add-hook '*post-startup-hook* 'install-loop)
(require "cmu_loop")
#|
siteinit に書いておくと動作が変。
初回ダンプ時は問題なし、起動2回目かおかしくなる -> ダンプのためには siteinit を読み込んでいるから？
(si:dump-image-path) に siteinit の内容が入っているんだろう

si:*trace-on-error* によると、
関数(clause)内にて
(gethash :with loop::*loop-clauses*)
がnil;nilを返すからエラーを投げるらしい

106,123行目の (mapc~ ) あたりがあやしい。2度目は初期化されてないとか?

[追記] 2009-03-19T05:38:12+09:00
ビンゴ。

ハッシュテーブルを使う変数2つ (*loop-clauses*,*for-as-subclauses*) がダ
ンプファイルから読み込まれる場合、*なぜか*
(gethash *loop-keyword* *loop-clauses*) が nil になる。ハッシュに要素は
入っているはずなのに。仕方ないから、起動時にハッシュの初期化をするように変更。
ただし、純 LISP ファイルとしては行儀が悪いので (editor パッケージを使うから)
なるべく .xyzzy に放り込むようにしましょう。

|#

(add-hook '*post-startup-hook* 'clear-message)
;; (add-hook '*post-startup-hook* 'delete-other-windows)

(defun toggle-buffer-fold (&optional default)
  "折り返しの切り替え."
  (interactive "P")
  (let ((foldp (buffer-fold-width)))
    (cond
     ;; 引数があれば折り返さない
     (default (set-buffer-fold-type-none))
     ;; 折り返さない->ウィンドウ幅で
     ((null foldp) (set-buffer-fold-type-column))
     ;; 指定桁で-> 折り返さない
     ((integerp foldp) (set-buffer-fold-type-window))
     ;; ウィンドウ幅で->指定桁で
     (t (set-buffer-fold-type-none))))
  (message (let ((f (buffer-fold-width)))
             (cond ((null f)
                    "[折り返さない]->指定幅で折り返す(~D)->ウィンドウ幅で折り返す")
                   ((integerp f)
                    "折り返さない->[指定幅で折り返す(~D)]->ウィンドウ幅で折り返す")
                   (t
                    "折り返さない->指定幅で折り返す(~D)->[ウィンドウ幅で折り返す]")))
           (default-value 'buffer-fold-width)))
(global-set-key '(#\C-x #\t #\f) 'toggle-buffer-fold)

;; シンボル名補完
;; SLIME, acl と同じく '(#\C-c #\Tab) がいい？
(dolist (keymap (list ed::*lisp-mode-map*
                      ed::*lisp-interaction-mode-map*
                      minibuffer-local-map))
  ;; (define-key keymap #\C-. 'lisp-complete-symbol)
  (define-key keymap '(#\C-c #\TAB) 'lisp-complete-symbol)
  ;; (define-key keymap '(#\M-TAB) 'lisp-complete-symbol)
  )
(global-set-key '(#\C-c #\C-r) 'eval-region)

;; lispmode以外で何度か誤爆したので...
;; (when (eq (lookup-keymap esc-map #\TAB) 'lisp-complete-symbol)
;;   (define-key esc-map #\TAB 'undefined))

;; newLISP
(require "newlisp")
(require "newlispfn")
(setq *newlisp-switches* "-C -s10000 --verbose --strict")
(pushnew '("\\.lsp$" . newlisp-mode) *auto-mode-alist* :test #'equal)
(pushnew '("qa-.*$" . newlisp-mode) *auto-mode-alist* :test #'equal)
(pushnew (cons "Newlisp" (si:getenv "NEWLISPDIR")) *filer-directories*)
;; ファイルはUTF-8Nで開きたい
;; (作成もUTF-8にしたい)
(defun encoding-utf8n () *encoding-utf8n*)
(push '("\\.lsp$" . encoding-utf8n) *auto-encoding-alist*)
;(setq *newlisp-manual* (merge-pathnames "doc/newlisp_manual-10.3.2.txt" (si:getenv "NEWLISPDIR")))
(setq *newlisp-manual* (merge-pathnames "share/doc/newlisp/newlisp_manual.txt" (si:getenv "HOME")))
;; (add-hook '*kill-xyzzy-hook* 'newlisp-kill-process) ; 効かね
;(global-set-key #\F6 'newlisp-eval-last-sexp)
(define-key ed::*newlisp-mode-map* #\M-F6 'newlisp-kill-process)
(define-key ed::*newlisp-mode-map* '(#\C-c #\F4) 'newlisp-kill-process)
;; (define-key ed::*newlisp-mode-map* #\F5 'newlisp-eval-buffer)
(define-key ed::*newlisp-mode-map* '(#\Esc #\C-c) 'newlisp-signal-process)
(defun run-newlisp64 (&optional arg)
  (interactive "P")
  (let ((*newlisp-exe* "C:/cygwin/home/shigeru/src/lang/newlisp-10.3.3/newlisp.exe"))
    (run-newlisp arg)))

;; comment.l
;(pushnew '(newlisp-mode #\; 2 " ") comment-mode-alist :test #'equal)

;; for swank-newlisp.lsp
(setf (get 'defslimefun 'ed:lisp-indent-hook) 'defun)

;; newlisp-c-mode
;(setq indent-tabs-mode t)
;(setq ed::*hide-ifdef-cpp* "gcc -E -DWIN_32")

;; (use "arglist.lsp") と組み合わせて使用
(defun newlisp-arglist (f)
  (interactive "sArglist: ")
  (newlisp-eval (format nil "(arglist ~A)" f)))
(define-key ed::*newlisp-mode-map* #\C-\;
            #'(lambda ()
                (interactive)
                (newlisp-arglist (or (ed::newlisp-current-word)
                                     (error "シンボルがないよ")))))

;; XML
(require "xml/xml-mode")
(import 'xml:xml-mode)          ; 他にもinteractiveな関数はあるけど使わないからいいや
(pushnew '("\\.jnlp$" . xml-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.mainfest$" . xml-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.rdf\\'" . xml-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.xhtml$" . xml-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.jff$" . xml-mode) *auto-mode-alist* :test #'equal) ; JFLAP
;(add-hook 'xml:*xml-mode-hook* 'clickable-uri-emphasis)
(setq xml::*xml-cdata-attribute* '(:foreground 15))
(defun xml-mode-user-hooks ()
  (setq comment-indent-function #'xml:xml-comment-indent))
;(add-hook 'xml:*xml-mode-hook* 'xml-mode-user-hooks)

;; (require "xml-parser-modoki")
(autoload 'ed::xmlpm-parse-file "xml-parser-modoki")
(setf (symbol-function 'xml-parse-file) #'ed::xmlpm-parse-file)


;; (defun load-selected-file ()
;;   (interactive)
;;   (if (file-visited-p)
;;       (load (or (probe-file (concat (get-buffer-file-name) "c"))
;;                 (get-buffer-file-name))
;;             :verbose t :print t)
;;       (error "ファイル名がありません")))
;; (global-set-key #\M-* 'load-selected-file)

;; lispmode.l -40
;; then-form/else-form のインデントを同じにする
;CLはこれでいいけど、公開するxlispやelisp,newlispも強制する必要はないのかも
;(setf (get 'if 'ed:lisp-indent-hook) 3)

(setf (get 'string-trim 'ed:lisp-indent-hook) 1)
(setf (get 'string-right-trim 'ed:lisp-indent-hook) 1)
(setf (get 'string-left-trim 'ed:lisp-indent-hook) 1)

;; バイナリファイル編集 hexl-mode
(require "hexl/hexl")
(defun hexl-coloring-hook ()
  (make-local-variable 'regexp-keyword-list)
  (setq regexp-keyword-list (compile-regexp-keyword-list
                             '(("^\\w\\{8\\}:" nil 2)
                               ("  .+$" nil :comment)))))
(add-hook 'hexl-mode-hook 'hexl-coloring-hook)
(defun query-hexl-mode ()
  "ファイルサイズが大きすぎるとhexlがもたつくのでユーザに尋ねる."
  (interactive)
  (let ((size (file-length (get-buffer-file-name)))
	(max (* (expt 2 20) 3))) ; 3Mbyteくらい
    (if (and (< max size)
             (not (y-or-n-p "読み込みが遅くなると思うけどいい？(~A byte)" size)))
        (fundamental-mode)
        (progn
          (revert-buffer *encoding-binary*)
          (hexl-mode)))))
;; (pushnew '("\\.exe$" . query-hexl-mode) *auto-mode-alist* :test 'equal)
;; (pushnew '("\\.dll$" . query-hexl-mode) *auto-mode-alist* :test 'equal)
;; (delete "\\.exe$" *auto-mode-alist* :key #'car :test #'equal)
(add-hook 'hexl-mode-hook
          (defun turn-on-read-only ()
            (toggle-read-only t)))

;(pushnew (cons "[CMUCL]" "C:/home/lxuser/src/cmucl-src-2008-08.tar.bz2/src/code/") *filer-directories* :test #'equal)

;; 共有フォルダをファイラから扱う
(require "filer-servers")
#+NIL
(dolist (host (list-servers))
  (dolist (dir (list-server-resources host))
    (let ((path (format nil "//~A/~A/" host dir)))
      (pushnew (cons path path)
               *filer-directories*
               :test #'equal))))

(defun simple-eval ()
  (interactive)
  ;; 自分を評価すると無限ループになるので
  (when (interactive-p)
    (command-execute (format nil "~{~C~}" '(#\C-u #\C-x #\C-e #\M-\; #\C-d)))))
(global-set-key #\M-e 'simple-eval)

(proclaim '(special *lisp-implementation-alist* *lisp-default-lisp*))
(setq *lisp-implementation-alist*
      `(
        ;; *terminal-encoding* => #<ENCODING "CP932" :DOS>
        (clisp "C:/usr/local/clisp-2.44/clisp.exe")
        (olio "C:/usr/local/clisp-2.47-full/bin/clisp.exe")
        (gcl-cltl1 "C:/PROGRA~1/GCL-26~1.7-C/lib/GCL-26~1.7/unixport/SAVED_~1.EXE")
        (gcl-ansi "C:/PROGRA~1/GCL-26~1.7-A/lib/GCL-26~1.7/unixport/SAVED_~1.EXE")
        (newlisp "C:/PROGRA~1/newlisp/newlisp.exe -C")
        (newlisp-sjis "C:/PROGRA~1/newlisp/NEWLIS~2.EXE -C" ,*encoding-sjis*)
        )
      *lisp-default-lisp* 'gcl-ansi)

(defun slime? (&optional (cmd *lisp-default-lisp*))
  (interactive (list (if *prefix-args*
                         (intern (completing-read "Which LISP? "
                                                  *lisp-implementation-alist*
                                                  :must-match t))
                         *lisp-default-lisp*)))
  (multiple-value-bind (name command encoding)
      (values-list (assoc cmd *lisp-implementation-alist*))
    (let ((*eshell* command)
          (*shell-mode-hook* (list
                              #'(lambda ()
                                  (rename-buffer (format nil "*~A*" name))
                                  (set-buffer-fold-type-none))))
          (*default-process-encoding* (or encoding *encoding-utf8n*)))
      (shell))))
;(global-set-key '(#\C-x #\r #\l) 'slime?)

(defun run-gcl (&optional ansi)
  (interactive "P")
  (shell-execute (if ansi
                     "C:/PROGRA~1/GCL-26~1.7-A/bin/gcl.bat"
                     "C:/PROGRA~1/GCL-26~1.7-C/bin/gcl.bat")))
;(global-set-key '(#\C-x #\r #\g) 'run-gcl)

(defun run-lisp (&optional arg)
  (interactive "P")
  (if arg
      ;; clisp のあるディレクトリにDOS窓を開く
      (let ((ed::*launch-app-directory*
             (directory-namestring *lisp-exec-path*)))
        (launch-application *ckw-path*))
    ;; これだとウィンドウ消してもlisp.exeプロセスだけ残るんだが
    (launch-application (concat *ckw-path* " -e " *lisp-exec-path*))))
;; (global-set-key '(#\C-x #\r #\l) 'run-lisp)

(defun run-lispbox ()
  (interactive)
  (shell-execute "C:/usr/local/lispbox-0.7/lispbox.bat"))

(defun set-local-tab-columns (col)
  "タブ幅の設定をします (バッファローカル)"
  (interactive "nTab tolumn: ")
  (unless (<= 1 col 32)
    (error "範囲外の整数です"))
  (set-tab-columns col (selected-buffer)))

(defun file-name-as-directory (pathname)
  (append-trail-slash (map-backslash-to-slash pathname)))

(defun rotate-split-window (&optional clockwise)
  "ウィンドウの縦分割⇔横分割を切り替えます."
  (interactive "P")
  (let ((coordinates (mapcar #'(lambda (x) (car (last x)))
                             (third (current-window-configuration)))))
    (when (= (length coordinates) 2)
      ;; horizontal: ((0 0 X Y) (0 Y X *))
      ;; vertical: ((0 0 X Y) (X 0 * Y))
      (delete-other-windows)
      (cond ((zerop (cadadr coordinates))
             (split-window))
            ((zerop (caadr coordinates))
             (split-window-vertically)))
      ;; 引数の有無によって時計回り、反時計回りを制御したいんだが。
      ;; このコードは失敗
      (when clockwise (other-window))
      (switch-to-buffer (other-buffer))
      (other-window))))
(global-set-key '(#\C-x #\t #\w) 'rotate-split-window)

(defun do-completion-dwim ()
  (interactive)
  ;; (unless (or (boundp 'keyword-hash-table) keyword-hash-table) (error "キーワードがありません"))
  (if (member buffer-mode '(lisp-mode
                            lisp-interaction-mode
                            fundamental-mode))
      (lisp-complete-symbol)
    (do-completion (save-excursion (skip-syntax-spec-backward "w_") (point))
                   (point)
                   :list-ignore-case
                   (make-list-from-keyword-table keyword-hash-table))))
(global-set-key '(#\C-c #\C-i) 'do-completion-dwim)
;; (global-set-key #\M-TAB 'do-completion-dwim)

;; JavaScript
;; http://xyzzy.s53.xrea.com/wiki/index.php?%B3%C8%C4%A5lisp%2Fjavascript-mode
(export 'ed::javascript-mode "editor")
(autoload 'ed::javascript-mode "javascript-mode" t)
;(set-syntax-string ed::*javascript-mode-syntax-table* #\/)
;(push '("\\.js$" . java-mode) *auto-mode-alist*)
(push '("\\.js$" . ed::javascript-mode) *auto-mode-alist*)
(push '("\\.as$" . ed::javascript-mode) *auto-mode-alist*) ; ActionAcript
(push '("\\.ds$" . ed::javascript-mode) *auto-mode-alist*) ; DMDScript
;(define-key *javascript-mode-map* #\C-/ 'undo)
(defun javascript-user-hook ()
  ;; keymap
  (define-key ed::*javascript-mode-map* #\Tab 'ed::javascript-indent-line)
  (define-key ed::*javascript-mode-map* #\M-Tab 'ed::javascript-completion)
  (define-key ed::*javascript-mode-map* #\C-\/ 'undo)
  ;; (define-key *javascript-mode-map* '(#\C-c #\C-i) 'ed::javascript-completion)

  (setq comment-column (default-value 'comment-column))
  (setq comment-start "// " comment-end "")
  )
(add-hook 'ed::*javascript-mode-hook* 'javascript-user-hook)

;; バッファ上でreplを走らせる場合のテンプレート (2011-11-08)
;; コレでもまだ細かいところには手が届かないorz
#|
(defun defshell (x)
  (let ((command (cdr (assoc :command x)))
        (name (cdr (assoc :name x)))
        (fname (intern (string-downcase (concat "run-" (cdr (assoc :name x))))))
        (bname (concat "*" (cdr (assoc :name x)) "*"))
        (incode (or (cdr (assoc :incode x)) *default-process-encoding*))
        (outcode (or (cdr (assoc :outcode x)) *default-process-encoding*))
        (eol-code (or (cdr (assoc :eol-code x)) *eol-guess*)))
    (eval
     `(defun ,fname ()
        (interactive)
        (let ((obuf (selected-buffer)))
          (set-buffer (get-buffer-create ,bname))
          (let ((proc (buffer-process obuf)))
            (and proc (eq (process-status proc) :run)
                 (return-from ,fname t)))
          (goto-char (point-max))
          (progn
            (setq mode-name ,name)
            (setq buffer-mode 'shell-mode)
            (use-keymap *shell-mode-map*)
            (setq need-not-save t)
            (setq auto-save nil)
            (set-buffer-fold-type-window)
            (setq *shell-ret* "\r\n"
                  *shell-echo* nil))
          (make-process ,command
                        :output ,bname
                        :incode ,incode
                        :outcode ,outcode
                        :eol-code ,eol-code)
          (display-buffer obuf)
          t)))
    )
  )
|#

(defun defshell (&key name
                      command
                      (incode *default-process-encoding*)
                      (outcode *default-process-encoding*)
                      (eol-code *eol-guess*))
  (unless (and name command)
    (error "引数が足りません"))
  (let ((fname (intern (string-downcase (concat "run-" name))))
        (bname (concat "*" name "*")))
    (eval
     `(defun ,fname ()
        (interactive)
        (let ((obuf (selected-buffer)))
          (set-buffer (get-buffer-create ,bname))
          (let ((proc (buffer-process obuf)))
            (and proc (eq (process-status proc) :run)
                 (return-from ,fname t)))
          (goto-char (point-max))
          (progn
            (setq mode-name ,name)
            (setq buffer-mode 'shell-mode)
            (use-keymap *shell-mode-map*)
            (setq need-not-save t)
            (setq auto-save nil)
            (set-buffer-fold-type-window)
            (setq *shell-ret* "\r\n"
                  *shell-echo* nil))
          (make-process ,command
                        :output ,bname
                        :incode ,incode
                        :outcode ,outcode
                        :eol-code ,eol-code)
          (display-buffer obuf)
          t)))
    )
  )

(defshell :name "JavaScript"    ; rhino
          :command "java -classpath C:/Users/shigeru/bin/js.jar org.mozilla.javascript.tools.shell.Main -strict")
(defshell :name "JScript"
          :command "cscript C:/cygwin/home/shigeru/code/wsh/shell.js")
(defshell :name "jrunscript"
          :command "C:/Program Files/Java/jdk1.6.0_30/bin/jrunscript.exe")
(defshell :name "Clojure"
          :command "java -cp C:/Users/shigeru/bin/clojure-1.3.0.jar clojure.main")
(defshell :name "OpenLisp"
          :command
          ;"C:/Users/shigeru/src/lang/openlisp-9.8.0/gmlisp-AMD64.exe -emacs"
          (format nil "~s -emacs" (merge-pathnames "opt/openlisp/ntalisp-i386.exe" (si:getenv "HOME")))
          )

(defun charmap ()
  "文字コード表:特殊文字を選択して、ドキュメントにコピーすることができます。"
  (interactive)
  (launch-application
   (merge-pathnames "system32/charmap.exe" (get-windows-directory))))

(defun wincalc ()
  (interactive)
  (launch-application "C:/WINDOWS/system32/calc.exe"))

(setq *std-control-next-char* #\C-v
      *std-control-prior-char* #\C-^)



;; CL の基本関数を調べる
(require "hyperspec")
;(import '(hyperspec:hyperspec hyperspec:hyperspec-format))
(define-key ed::*lisp-mode-map* '(#\C-c #\h) 'hyperspec:hyperspec)
(define-key ed::*lisp-interaction-mode-map* '(#\C-c #\h) 'hyperspec:hyperspec)
(setq hyperspec::*hyperspec-root* "http://www.lispworks.com/documentation/HyperSpec/")
;(setq hyperspec::*hyperspec-root* "C:/home/lxuser/code/lisp/HyperSpec-7-0/HyperSpec/")

;; 一発インデント
(defun indent-buffer ()
  "バッファをインデントします."
  (interactive "*")
  (when mode-specific-indent-command
    (save-excursion
      (goto-char (point-min)) ; 1行目もインデント
      (funcall mode-specific-indent-command)
      (indent-region (point-min) (point-max))
      (message "indent buffer...done"))))
(global-set-key #\C-F8 'indent-buffer)

;; xyzzy@wine対策
(when (string-match "^Z:/" (si:system-root))
  (cd (si:system-root))
  ;; バックアップのパスが調子悪いので
  (setq ed::*backup-directory* nil))

(defun execute-buffer-file (&optional buffer)
  "編集中のバッファを関連付けられたプログラムで開く."
  (interactive)
  (shell-execute (or (get-buffer-file-name buffer)
                     (error "バッファを保存してください"))
                 t))

;; HTML Mode
(require "htmlmode")
(unintern 'html+-mode)
(require "html+-mode")
;(export 'ed::html+-mode "editor")
;(autoload 'ed::html+-mode "html+-mode" t)
;(setq ed::*html+-tag-attribute* '(:bold t :foreground 5))
(pushnew '("\\.html?$" . html+-mode) *auto-mode-alist* :test #'equal)
;(pushnew '("\\.php?$" . html+-mode) *auto-mode-alist* :test #'equal)
(define-key *html+-mode-map* '(#\C-c #\C-v) 'execute-buffer-file)

;; sgml-mode.el を改変
(defvar *sgml-special-char-alist*
  '(("&nbsp;" . "\X0120")
    ("&lt;" . "<")
    ("&gt;" . ">")
    ("&quot;" . "\"")
    ("&amp;" . "&")))

;; 2重置換に注意 "&amp;#65;" -> o"&#65;" x "A"
(defun sgml-unquote-region (start end)
  "リージョン内の文字実体参照を元の文字に変換する."
  (interactive "*r")
  (labels ((uchar (str radix)
             (unicode-char
              (parse-integer str :radix radix))))
    (save-excursion
      (save-restriction
        (narrow-to-region start end)
        (goto-char (point-min))
        (while (re-search-forward
                "&\\(#\\(x\\([0-9A-Fa-f]+\\)\\|\\([0-9]+\\)\\)\\|\\([A-Za-z]+\\)\\);?"
                t)
          (replace-match (cond
                          ((match-string 3) ; &#x0000;
                           (string (uchar (match-string 3) 16)))
                          ((match-string 4) ; &#0000;
                           (string (uchar (match-string 4) 10)))
                          (t
                           (or (cdr (assoc (match-string 0)
                                           *sgml-special-char-alist*
                                           :test #'string-equal))
                               ;; not found
                               (match-string 0))))
                         :literal t))
        ))))
(compile 'sgml-unquote-region)

(defun %sgml-quote (input &optional output)
  (do ((c #1=(read-char input nil :EOF) #1#))
      ((eq c :EOF))
    (princ (or (car (rassoc (string c)
                            *sgml-special-char-alist*
                            :test #'string-equal))
               c)
           output)))
(compile '%sgml-quote)

(defun sgml-quote (input &optional output)
  (if (stringp input)
      (if (null output)
          (with-input-from-string (i input)
            (with-output-to-string (o)
              (%sgml-quote i o)))
          (with-input-from-string (i input)
            (%sgml-quote i output)))
      (if (null output)
          (with-output-to-string (o)
            (%sgml-quote input o))
          (%sgml-quote input output))))

(defun sgml-quote-region (from to &optional unquotep)
  (interactive "*r\nP")
  (if unquotep
      (sgml-unquote-region from to)
      (ed::text-decode-region #'sgml-quote from to)))

(setf (symbol-function 'html-quote-region) #'sgml-quote-region)
(define-key *html-mode-map* '(#\C-c #\C-q) 'sgml-quote)
;(define-key *html+-mode-map* '(#\C-c #\C-q) 'sgml-quote-region)

(defun unhtml (input &optional output)
  (format output "~A"
          (substitute-string
           (cond ((stringp input) input)
                 (t (with-output-to-string (s)
                      (echo input s))))
           "<[^>]*>" "")))

(defun unhtml-region (start end)
  "HTMLタグを除去する."
  (interactive "*r")
  #+xyzzy (ed::text-decode-region #'unhtml start end)
  #+emacs (save-excursion
            (save-restriction
              (narrow-to-region start end)
              (goto-char (point-min))
              (replace-buffer "<[^>]*>" "" :regexp t))))

;; アセンブラ (for GAS-SH)
(require "asm-mode")
(pushnew '("\\.\\(asm\\|s\\)$" . asm-mode) *auto-mode-alist* :test #'equal)

;; shell-modeの折り返しいらない
(add-hook '*shell-mode-hook* 'set-buffer-fold-type-none)

(defun add-menu-user-init ()
  (let ((edit-menu (get-menu *app-menu* 'ed::edit)))
    ;; 編集＞書込み禁止
    (add-menu-separator edit-menu)
    (add-menu-item edit-menu nil "書込み禁止(&%)" 'toggle-read-only
                   #'(lambda () (when buffer-read-only :check)))
    ;; 編集＞タブインデントモード
    (add-menu-separator edit-menu)
    (add-menu-item edit-menu nil
                   "タブインデントモード(&T)"
                   #'(lambda (&optional (arg nil sv))
                       (interactive)
                       (ed::toggle-mode 'indent-tabs-mode arg sv))
                   #'(lambda ()
                       (when indent-tabs-mode :check))))
  )
(add-hook '*post-startup-hook* 'add-menu-user-init)

(require "regexp-opt")

;; メニューバーに[バッファ(B)]を追加する
;(require "menubar")

;; Markdown
(require "markdown")
;(pushnew '(markdown-mode nil "<!-- " " -->") comment-mode-alist :test #'equal)

;(load-library "C:/usr/local/xyzzy/site-lisp/markdown.l")
(defun markdown-region (from to &optional view-browser)
  (interactive "r\nP")
  (when (and (need-buffer-save-p (selected-buffer))
             (yes-no-or-cancel-p "バッファが変更されています。保存しますか?"))
    (save-buffer))
  (let ((buffer (selected-buffer))
        (encoding (buffer-fileio-encoding)))
    (with-output-to-temp-buffer ("*markdown output*")
      (html-mode)
      (insert-buffer-substring buffer from to)
      (change-fileio-encoding encoding)
      ;; (filter-buffer "C:/home/lxuser/lib/emacs/newlisp/markdown.bat")
      (filter-buffer "C:/usr/bin/markdown.bat")
      (when view-browser
        (let ((tmpfile (make-temp-file-name "md" "html")))
          (unwind-protect
              (progn
                (write-file tmpfile)
                (shell-execute tmpfile t))
            ;; markdown-mode.el ではファイルを消さないようになっているが...
            (sit-for 0.2)
            (and (file-exist-p tmpfile)
                 (delete-file tmpfile :if-does-not-exist :skip))))))))

(defun markdown-buffer (&optional view-browser)
  (interactive "P")
  (markdown-region (point-min) (point-max) view-browser))
(setf (symbol-function 'markdown) #'markdown-buffer)

;(pushnew "C:/usr/local/xyzzy/site-lisp/" *load-path* :test #'equal)

(setf (symbol-function 'map-url-decode-region) #'url-encoding-decode-region)
(defun url-encoding-decode-selection ()
  (interactive "*")
  (ed::map-selection #'url-encoding-decode-region))

;; 内部エンコーディングが変になる
;; (defun url-encoding-encode-region (from to)
;;   (interactive "*r")
;;   (ed::text-decode-region #'si:www-url-encode from to))

(require "disassemble")
(require "profile")

;; Python
(defun py-mode-install()
  (interactive)
  (require "py-mode")
  (pushnew '("\\.py$" . ed::py-mode) *auto-mode-alist*)
  (message "Install py-mode...done"))

(require "zone")
(require "animate")
;(require "winamp")
;(defun winamp-now-playing () (interactive) (message "~A" (winamp::get-title-playing)))

;(require "xml-http-request")
;(use-package :xml-http-request)
;(defun get-url (url) (xhr-response-text (xhr-get url)))

;; 特殊文字
;(require "iso8859-1")
; C-x 8 *

(defun run-program ()
  (interactive)
  (popup-list '("C:/home/Visual Studio 2008 コマンド プロンプト.lnk"
                "C:/borland/setbcc.bat"
                "C:/msys/1.0/msys.bat"
                "C:/MinGW/setmingw.bat"
                "C:/PROGRA~1/GCL-26~1.7-A/bin/gcl.bat"
                "C:/usr/local/lispbox-0.7/lispbox.bat")
              #'(lambda (sym)
                  (shell-execute sym (default-directory)))))

(require "cmacexp")
(define-key ed::*c-mode-map* '(#\C-c #\C-e) 'c-macro-expand-region)
;(define-key ed::*c++-mode-map* '(#\C-c #\C-e) 'c-macro-expand-region)

;; ピコカキコ用
(pushnew '("\\.fml$" . c-mode) *auto-mode-alist* :test #'equal)
;; (global-set-key #\F11 'winamp::Stop-button)
;; (global-set-key #\F12 'winamp::Play-track)
(defun mml-play-file (file)
  (interactive
      (list (read-exist-file-name "MML: " :default (get-buffer-file-name))))
  (shell-execute "C:/Program Files/Winamp/winamp.exe" nil file))

; 試しにMIGEMOから始めてみる(2010-05-21)
;(migemo-toggle t)
;(setf *igsearch-init-state* :migemo)
;(setf *igsearch-init-state* nil)

;; http://white.s151.xrea.com/wiki/index.php?memo%2Fxyzzy%2Fedit#x74943ba
(defun unicode-unescape-region (&optional from to)
  (interactive "r*")
  (or (< from to)
      (rotatef from to))
  #+NIL
  (save-excursion
    (goto-char from)
    (while (scan-buffer "\\\\u\\([A-Za-z0-9_]\\{4\\}\\)" :regexp t :limit to)
      (let ((str (match-string 1)))
        (delete-region (match-beginning 0) (match-end 0))
        (insert (unicode-char (parse-integer str :radix 16))))))
  (save-excursion
    (save-restriction
      (narrow-to-region from to)
      (goto-char (point-min))
      (while (re-search-forward "\\\\u\\([A-Za-z0-9_]\\{4\\}\\)" t)
        (replace-match (string (unicode-char
                                (parse-integer (match-string 1) :radix 16)))
                       :literal t))))
  )

;(require "changelogmemo/main")
;(setq *cl-config-file-alist* '(("changelogmemo" . "~/cl/config.l")))
;(add-hook '*post-startup-hook* 'cl-start)
;(setq cl::*cl-user* "KOBAYASHI Shigeru  <shigeru@YOUR-D1BE424ADF>")
;(global-set-key '(#\C-x #\4 #\a) 'cl::add-memo-buffer)

(require "changelog")
(setq add-log-full-name "KOBAYASHI Shigeru")
(setq change-log-default-name
      (merge-pathnames "Documents/ChangeLog" (si:getenv "HOMEPATH")))
(global-set-key '(#\C-x #\4 #\a) 'add-change-log-entry)

(defun tac-region (start end)
  "行を逆順にする."
  (interactive "*r")
  (filter-region "C:/cygwin/bin/tac.exe" start end))

;; Linux設定ファイル用
(pushnew '("\\.conf\\>" . perl-mode) *auto-mode-alist*)
(setf (symbol-function 'conf-mode) #'perl-mode)

(global-set-key #\C-h 'delete-backward-char-or-selection)

(defun goto-char-interactive (point)
  (interactive "nGoto char: ")
  (goto-char point))

;; Lua
(require "lua")
(pushnew '("\\.lua\\(?:doc\\)?$" . lua-mode) *auto-mode-alist* :test #'equal)
(pushnew '("\\.nse$" . lua-mode) *auto-mode-alist* :test #'equal)

;; PDIC
;; 設定メモ - http://mux03.panda64.net/diary/20110412.html
(defun pdic-install ()
  (interactive)
  (require "pdic")
  ;(setq *pdic-path* "C:/Program Files/PDIC_Unicode/PDICU.EXE")

  (defun pdic-lookup (word)
    (interactive "sPDIC: ")
    (let ((ans (pdic-dde-comunicate word)))
      (if ans (popup-string ans (point)))))
  t)

;; coding:utf-8 を強制的にutf8nにする
(setf (gethash "utf-8" *mime-charset-name-hash-table*) *encoding-utf8n*)
;; or http://d.hatena.ne.jp/bowbow99/20100430/1272604971

;; PowerShell を使ってみる (2011-09-20T23:24:43+09:00)
;(setq *eshell* "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe")
;(setq *eshell* "cmd.exe")

(defun run-vc ()
  (interactive)
  (launch-application "cmd /k C:/PROGRA~2/MICROS~1.0/VC/VCVARS~1.BAT x86"))

(defun run-vc64 ()
  (interactive)
  (launch-application "cmd /E:on /V:on /T:0E /k C:/PROGRA~2/MIA713~1/Windows/v7.1/Bin/SetEnv.Cmd /x64"))

(defun run-mingw ()
  (interactive)
  (launch-application "C:/MinGW/msys/1.0/msys.bat"))

(defun run-mingw64 ()
  (interactive)
  (launch-application "cmd /k C:/MinGW64/mingwvars.bat"))

(defun run-powershell ()
  (interactive)
  (launch-application "powershell.exe"))

(defparameter *apps*
  '(("Windows PowerShell" . "powershell.exe")
    ("Visual Studio 2010" . "C:/PROGRA~2/MICROS~1.0/VC/VCVARS~1.BAT")
    ("MinGW64" . "C:/MinGW64/mingwvars.bat")))

(defun launch-application* (app)
  (interactive
      (list
       (completing-read "%% " *apps* :case-fold t :must-match t)))
  (let ((program (cdr (assoc app *apps* :test #'equal))))
    (when program
      (launch-application (format nil "cmd /k \"~a\"" program)))))

#|
(dolist (e (read-from-string (newlisp-eval-string "(map first (env))")))
  (if (and (file-exist-p (si:getenv e))
           (file-directory-p (si:getenv e))
           (not (find (si:getenv e) *filer-directories*
                      :test #'path-equal :key #'cdr)))
      (push (cons (concat "[" e "]") (si:getenv e)) *filer-directories*))
  )
|#

;; LaTeX.l
(require "LaTeX.l")
(defun LaTeX-user-hook ()
  (interactive)
  (setq comment-start "% "
        comment-end ""
        comment-start-skip "%+[ \t]*"
        comment-indent-function #'c-comment-indent))
(add-hook 'ed::*LaTeX-mode-hook* 'LaTeX-user-hook)

;; Blowfish
;(require "blowfish/readme_l")

;; Basic
(pushnew '("\\.vbs$" . basic-mode) *auto-mode-alist* :test 'equal) ; VBScript
(pushnew '("\\.asp$" . basic-mode) *auto-mode-alist* :test 'equal) ; Active Server Pages


;; xyzzy が終了できない事態になったらひとまずこいつを実行
(defun run-kill-xyzzy-hook ()
  "*kill-xyzzy-hook* を実行する."
  (interactive)
  (run-hooks '*kill-xyzzy-hook*))

(gc)

;;; .xyzzy ends here.
