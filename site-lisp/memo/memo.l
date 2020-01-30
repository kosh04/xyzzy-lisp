;;; -*- Mode: lisp-interaction; Package: user -*-
;;;
;;; memo.l --- xyzzy 専用メモ
;;; CommonLisp 専用は "C:/home/lxuser/code/lisp/misc.l"

;;; タイトルバーのデフォルトは nil
(setq title-bar-format "%p %v%#h - %#F")

(machine-name)
(user-name)

(defun windows-version ()
  (format nil "~A ~D.~D ~A (~D)"
          (os-platform) (os-major-version)
          (os-minor-version) (os-csd-version)
          (os-build-number)))
(windows-version)               ; "windows-xp 5.1 Service Pack 3 (2600)"

(si:base64-decode "gtmCsILZgrA=") ; "ほげほげ"
(si:base64-encode "ほげほげ")	; "gtmCsILZgrA="
(si:www-url-encode "小林")	; "%8F%AC%97%D1"

(defun test1 ()
  "プロンプト入力を表示しない"
  (interactive)
  (let ((ans ""))
    (loop
      (minibuffer-prompt "From ~d: " 12)
      (let ((c (read-char *keyboard*)))
	(case c
	  (#\RET (return ans))
	  (#\C-g (quit))
	  (t (setq ans (format nil "~a~c" ans c))))))))

;; ftp.l
(getpass)

*support-mouse-wheel*		; t
'require-mouse-move はダミー(ChangeLogより)

;;; :escape の動作の違い
;;; たぶんエスケープ文字を取り除くかどうか
(write '(\,*print-escape*) :escape *print-escape*) ; (|,*print-escape*|)
(write '(\,*print-escape*) :escape nil) ; (,*print-escape*)

;; バッククオートはクオートとほぼ等価
;; コンマのありなしで挙動が変わる
'(1 2 3 (+ 1 2 3))                 ; (1 2 3 (+ 1 2 3))
`(1 2 3 (+ 1 2 3))                 ; (1 2 3 (+ 1 2 3))
`(1 2 3 ,(+ 1 2 3))                ; (1 2 3 6)
(macroexpand '`(1 2 3 ,(+ 1 2 3))) ; (list '1 '2 '3 (+ 1 2 3))

;;;.. コマンドラインから diff を実行
;;;.. xyzzy.exe -f diff-command-line hoge.txt fuga.txt
(defun diff-command-line ()
  (require "diff")
  (let ((new-file (pop si:*command-line-args*))
	(old-file (pop si:*command-line-args*)))
    (diff new-file old-file)))

(syntax-close-p #\))		; t

(defun usr-tool-bar ()
  (create-tool-bar
   'usr-tool-bar
   (merge-pathnames "toolbar.bmp" (etc-path))
   '(("書込み禁止" 12 toggle-read-only (lambda () (if buffer-read-only :check)))
     ("罫線" 60 box-drawings-mode (lambda ()
				    (when *box-drawings-mode* :check)))
     ("太線" 38 box-drawings-toggle-line-type
      (lambda ()
	(when (eq *box-drawings-line-type* '*box-drawings-thick-line*) :check)))
     ("HTMLヘルプ" 17 show-html-help)
     ("関連付けられたプログラムで開く" 16 execute-current-file)
     ("エクスプローラ" 48 (lambda () (shell-execute (directory-namestring (get-buffer-file-name)))))
     ("辞書引きモード" 36 edict-mode (lambda () (if edict-mode :check)))
     :sep
     ("現在のウィンドウを閉じる" 6 kill-selected-buffer)
     :sep
     )))
(define-command-bar 'usr-tool-bar "ユーザー(&U)")
(show-tool-bar 'user::usr-tool-bar)
(show-command-bar 'user::usr-tool-bar)
(delete-command-bar 'usr-tool-bar) ; アンインストール

;;; *editor パッケージの builtin 関数
(let ((count 0))
  (do-symbols (sym (find-package "editor")
		   (format t "~%count: ~d~%" count))
    (when (and (not (find-symbol (symbol-name sym) "lisp"))
	       (fboundp sym)
	       (si:*builtin-function-p (symbol-function sym)))
      ;(format t "~a~%" sym)
      (incf count))))		; count: 652; nil

;;; 与えられた文字列をそれなりに展開する
(default-directory)   ; "C:/home/xyzzy/"
(namestring "")       ; "C:/home/xyzzy"
(namestring "hoge")   ; "C:/home/xyzzy/hoge"
(namestring "/hoge")  ; "C:/hoge"
(namestring "~/hoge") ; "C:/home/xyzzy/hoge"

;; "/" は常にルートディレクトリ (C:/)
;; "~/" は常に(si:system-root) $XYZZY
(list (default-directory)
      #1=(list (namestring "hoge")
               (namestring "/hoge")
               (namestring "~/hoge"))
      (set-default-directory (get-windows-directory))
      #1#)
("C:/home/xyzzy/site-lisp/"
 ("C:/home/xyzzy/site-lisp/hoge"
  "C:/hoge"
  "C:/home/xyzzy/hoge")
 t
 ("C:/WINDOWS/hoge"
  "C:/hoge"
  "C:/home/xyzzy/hoge"))

(namestring "memo.l")           ; "C:/home/xyzzy/site-lisp/memo.l"
(merge-pathnames "memo.l")	; "C:/home/xyzzy/site-lisp/memo.l"
(truename "memo.l")		; "C:/home/xyzzy/site-lisp/memo.l"

;;; これは違うだろ (そうでもないかもね)
;; たぶん (default-directory) を見てる
(file-exist-p "") ; t
(namestring "")			; "C:/home/xyzzy/site-lisp"
(merge-pathnames "")		; "C:/home/xyzzy/site-lisp"

;;; ldoc に使えそう
(get 'current-word 'lisp::function-documentation) ; "カーソル位置にある単語を返します。"
(documentation 'current-word 'function)	; "カーソル位置にある単語を返します。"
;; 引数
(safe-cadr (si:closure-body #'tailp)) ; (lisp::sublist list)
(si:get-documentation-string
 'format 'lisp::function-documentation t
 (lisp::documentation-path))	; "出力書式に従って出力します。"
(documentation 'format 'function) ; "出力書式に従って出力します。\n ..."
;; interactive の後でも doc-string が有効みたい
(defun fact (n)
  (interactive "N")
  "階乗計算"
  (labels ((! (n) (if (zerop n) 1 (* n (! (1- n))))))
    (message "~A" (! n))))
(documentation 'fact 'function)	; "階乗計算"

(lisp::find-interactive
 '("階乗計算"
   (interactive "*")
   (if (zerop n)
       1
     (* (n! (1- n))))))
;; ((interactive "*"))
;; ("階乗計算" (if (zerop n) 1 (* (n! (1- n)))))

;;; first-error/next-error をまとめる
(defun emacs-next-error (&optional arg)
  "first-error/next-error のうち、適切な方を呼び出します。"
  (interactive "p")
  (if (not ed::*error-list*)
      (progn
	(goto-char (point-min))
	(first-error arg nil))
    (next-error arg)))

;;; stepの結果をダイアログではなくバッファへ流す
;;; http://white.s151.xrea.com/wiki/index.php?memo%2Fxyzzy%2Ffor%20debug
;; 他のCLでも使えるようにしたい
(defmacro step (form &environment env)
  `(let ((*applyhook* #'step-apply-hook))
     ,form))
(defun step-apply-hook (fn args)
  (let ((values (multiple-value-list
		 (applyhook fn args nil #'step-apply-hook))))
    (format t "~&(~S ~{~S~^ ~}) => ~{ ~S~}~%"
	    fn args values)
    (values-list values)))

;;; #ifdef をプリプロセッサに頼んで処理する (デフォは "cl -E")
(autoload 'hide-ifdef "hideif" t)
(setq ed:*hide-ifdef-cpp* "gcc -E")
(setq ed:*hide-ifdef-cpp* "C:/MinGW/bin/gcc.exe -E")

;;; いつもここから
(set-default-directory (si:getenv "HOME"))

;;; 改行、タブの表示に使う文字
(setq-default display-newline-char #\downwards_arrow_with_tip_leftwards)
(setq-default display-first-tab-char #\rightwards_arrow_to_bar)
(setq-default display-rest-tab-char nil)

;;; 拡張子のモードに合わせる
(let ((filename (get-buffer-file-name)))
  (dolist (x *auto-mode-alist*)
    (when (string-matchp (car x) filename)
      (funcall (cdr x))
      (return)))
  (fundamental-mode))
;; 別の書き方
(let ((filename (get-buffer-file-name)))
  (funcall (or (cdr (assoc-if (lambda (x)
                                (string-match x filename))
                              *auto-mode-alist*))
               #'fundamental-mode)))

;;; 前回のコマンドをもう一度
(global-set-key '(#\C-c #\C-c)
		#'(lambda ()
		    (interactive)
		    (execute-subprocess (car *minibuffer-execute-history*))
		    (message "execute~S..." (car *minibuffer-execute-history*))
		    ))

;;;
(setq *print-completion-list-hook* #'popup-completion-list)
(defun popup-completion-list (lst prefix &optional str)
  "補完候補をチップヘルプにする"
  (popup-string (format nil "Possible completions are ~D items:\n~{\n~A~}"
			(length lst) lst)
		(point)))

;; C-x C-f 時にショートカットで固定文字列を挿入
(define-key minibuffer-local-completion-map #\F1
	    #'(lambda ()
		(interactive)
		(delete-region (point-min) (point-max))
		(insert (append-trail-slash (map-backslash-to-slash (si:getenv "HOME"))))))
(define-key minibuffer-local-completion-map #\F2
	    #'(lambda ()
		(interactive)
		(delete-region (point-min) (point-max))
		(insert "C:/cygwin/")))

(defun insert-environment-path ()
  "環境変数を展開して挿入"
  (interactive)
    (if (and (save-excursion (scan-buffer "$\\(\\w+\\)$" :regexp t :reverse t))
	     (si:getenv (match-string 1))
	     (check-valid-pathname (si:getenv (match-string 1))))
	(let ((env (match-string 1)))
	  (delete-region (point-min) (point-max))
	  (insert (append-trail-slash (map-backslash-to-slash (si:getenv env))))
	  (message "expand ~S" env))
      (message "No match environment path")))
(define-key minibuffer-local-completion-map #\F3 'insert-environment-path)

;; `string-replace-match' がリテラルを受け付けないためダメダメ版
(defun substitute-env-vars (string &optional when-undefined)
  "Substitute environment variables refferd to in STRING."
  (let ((start 0))
    (while (string-match "\\(?:\\$\\(\\w+\\)\\|%\\(\\w+\\)%\\)" string #?start)
      (let* ((name (match-string 1))
             ($name (or (si:getenv name) "")))
        (setq string (string-replace-match string $name)
              start (+ (match-beginning 0) (length $name)))))
    string))
(substitute-env-vars "%XYZZYHOME%")

(defun make-directory-unless-directory-exists (filename)
  "FILENAME の中に存在しないディレクトリがあればそれを作ります。"
  (unless (valid-path-p filename)
    (let ((d (directory-namestring filename)))
      (when (yes-or-no-p "~a~%ディレクトリがないけど作る？"  d)
	(create-directory d))))
  nil)
(add-hook '*before-find-file-hook* 'make-directory-unless-directory-exists)

(defun expand-shortcut-file (file)
  "FILE が *.lnk ならリンク先のファイルを開きます。(D&D用?)"
  (let ((sh (and (pathname-match-p file "*.lnk")
		 (ignore-errors (resolve-shortcut file)))))
    (when (and sh (yes-or-no-p "リンク先~%~A~%を開きます" sh))
      (find-file sh)
      (get-file-buffer sh))))
(add-hook '*before-find-file-hook* 'expand-shortcut-file)

;;; カレントドライブの取得
(substring (etc-path) 0 3)	; "E:/"
(defvar *usb-drive-letter* (substring (si:system-root) 0 3))

;;; 正規表現でC言語の数値を色付け (from:reference)
(defvar *c-number-formats*
  (compile-regexp-keyword-list
   '(("\\(^\\|\\_S\\)\\(?:[0-9]+\\.[0-9]*\\|\\.[0-9]+\\)\\(?:e[-+]?[0-9]+\\)?[fl]?\\($\\|\\_S\\)"
      t (:keyword 0 :bold) nil -1 -2)
     ("\\_<[0-9]+e[-+]?[0-9]+[fl]?\\_>" t 1)
     ("\\_<\\([1-9][0-9]*\\|0[0-7]*\\|0x[0-9a-f]+\\)\\(u?l\\|l?u\\|u?i64\\)?\\_>"
      t (:color 1 2 :underline)))))
(add-hook '*c-mode-hook*
	  #'(lambda ()
	      (interactive)
	      (make-local-variable 'regexp-keyword-list)
	      (setq regexp-keyword-list *c-number-formats*)))

;; $newLISPsrc/guiserver/java/SyntaxHighlighter.java から (効かないな…)
(defparameter *newlisp-number-formats*
  (compile-regexp-keyword-list
   '(("^-?\\d+$|^-?\\d+\\.\\d+$|^0x[0-9a-fA-F]+$" t (:keyword 0 :bold) nil -1 -2))))
(add-hook '*newlisp-mode-hook*
          #'(lambda ()
              (interactive)
              (make-local-variable 'regexp-keyword-list)
              (setq regexp-keyword-list *newlisp-number-formats*)))

;;; キルリングのデータをポップアップして貼り付け
;; (global-set-key #\M-y 'yank-popup-list)
(defun yank-popup-list ()
  "キルリングのデータをポップアップして貼り付け"
  (interactive)
  (when *kill-ring*
    (let (lst)
      (dolist (item *kill-ring*)
	(pushnew (car item) lst :test #'equal))
      (popup-list (reverse lst)
		  #'(lambda (x)
		      (insert x)
		      (refresh-screen))))))

;;; バッファ名に親ディレクトリを足す
;;; http://hie.s64.xrea.com/xyzzy/note2/wiki.cgi?page=Buffer
(defun add-parent-directory-name-to-buffer-name ()
  (let ((file-name (get-buffer-file-name)))
    (when file-name
      (setq file-name (split-string file-name "/"))
      (setq file-name (nthcdr (- (list-length file-name) 2) file-name))
      (rename-buffer (concat (car file-name) "/" (cadr file-name))))))

(let ((pathname (get-buffer-file-name)))
  (when pathname
    (format nil "~A/~A"
	    (car (last (pathname-directory pathname)))
	    (file-namestring pathname)))) ; "site-lisp/memo.l"

;;; ステップ実行 (misc.l)
(step (car (list 'a 'b (list 'c 'd))))

;;; ウィンドウ別に表示を更新したいのだが (title-bar-format でもありかも)
(defun mode-line-with-time-stamp ()
  (setq mode-line-format
	(if (file-visited-p)
	    (format nil "[%i] --%*- %b (%M) [%k:%l] %P(~A%%) %f ~TTimesStamp: ~A"
		    ;; ページ表示割合
		    (floor (/ (* (current-line-number) 100) (buffer-lines)))
		    ;; 更新時刻
		    (format-date-string "%Y-%m-%dT%H:%M:%S%Z"
					(file-write-time (get-buffer-file-name))))
	  "[%i] --%*- %b (%M) [%k:%l] %P %f"))
  (update-mode-line))
(add-hook '*post-command-hook* 'mode-line-with-time-stamp)
(delete-hook '*post-command-hook* 'mode-line-with-time-stamp)
(setq mode-line-format "[%i] --%*- %b (%M) [%k:%l] %P %f")

;;; from reference
(defun self-insert-space (&optional (arg 1))
  "連続した`SPC'はアンドゥでまとめて削除する"
  (interactive "*")
  (when (eq *last-command* 'self-insert-space)
    (clear-undo-boundary))
  (self-insert-command arg))
(define-key ed::*lisp-interaction-mode-map* #\SPC 'self-insert-space)

;; c:/home/emacs/22.1/lisp/emacs-lisp/lisp.el
(defun check-parens ()			; lame name?
  "Check for unbalanced parentheses in the current buffer.
More accurately, check the narrowed part of the buffer for unbalanced
expressions (\"sexps\") in general.  This is done according to the
current syntax table and will find unbalanced brackets or quotes as
appropriate.  (See Info node `(emacs)Parentheses'.)  If imbalance is
found, an error is signaled and point is left at the first unbalanced
character."
  (interactive)
  (condition-case data
      ;; Buffer can't have more than (point-max) sexps.
      (scan-sexps (point-min) (point-max))
    (scan-error (goto-char (nth 2 data))
		;; Could print (nth 1 data), which is either
		;; "Containing expression ends prematurely" or
		;; "Unbalanced parentheses", but those may not be so
		;; accurate/helpful, e.g. quotes may actually be
		;; mismatched.
  		(error "Unmatched bracket or quote"))
    (error (cond ((eq 'scan-error (car data))
		  (goto-char (nth 2 data))
		  (error "Unmatched bracket or quote"))
		 (t (signal (car data) (cdr data)))))))


;;; 対応する括弧に飛ぶ (Emacsでも使える)
(defun go-match-paren (&optional arg)
  (interactive "p")
  (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
	((looking-at "\\s\)") (forward-char 1) (backward-list 1))
	(t (self-insert-command (or arg 1)))))
(global-set-key #\% 'go-match-paren)

;;; おまけヘルプ
(defun popup-help ()
  (interactive)
  (popup-list '("apropos" "command-apropos" "describe-bindings"
		"describe-function" "describe-key" "describe-key-briefly"
		"describe-variable" "view-lossage" "show-html-help")
	      #'(lambda (sym)
		  (call-interactively (find-symbol sym))
		  (and (refresh-screen)
		       (clear-minibuffer-message))
		  )))
(track-popup-menu (define-popup-menu
		    (:item nil "apropos" #'apropos)
		    (:item nil "command-apropos" #'command-apropos)))

;;; VIPPER-modeｗｗｗｗｗｗｗｗｗｗｗｗｗｗｗｗｗｗｗｗｗｗ
(pushnew '(VIPPER-mode . "⊂二二二（  ＾ω＾）二⊃") *minor-mode-alist* :key #'car)
(defvar-local VIPPER-mode nil)
(defun VIPPER-mode (&optional (arg nil sv))
  (interactive "p")
  (ed::toggle-mode 'VIPPER-mode arg sv)
  (if VIPPER-mode
      (set-minor-mode-map *VIPPER-mode-map*)
    (unset-minor-mode-map *VIPPER-mode-map*))
  (update-mode-line t))
(defun rolling-insert-w()
  (interactive)
  (if (eolp)
      (while (not (read-char-no-hang *keyboard*))
	(sit-for 0.1)
	(insert #\ｗ))
    (insert #\w)))
(defvar *VIPPER-mode-map* nil)
(unless *VIPPER-mode-map*
  (setf *VIPPER-mode-map* (make-sparse-keymap))
  (define-key *VIPPER-mode-map* '#\w 'rolling-insert-w))

;; filer.l
;; filer で上下キーでループ
(defun filer-forward-line-or-goto-bof (&optional (arg 1))
  (let ((old-file (filer-get-current-file)))
    (filer-forward-line arg)
    (when (string= old-file (filer-get-current-file))
      (filer-goto-bof))))
(defun filer-backward-line-or-goto-eof (&optional (arg 1))
  (let ((old-file (filer-get-current-file)))
    (filer-forward-line (- arg))
    (when (string= old-file (filer-get-current-file))
      (filer-goto-eof))))
(define-key filer-keymap #\C-n 'filer-forward-line-or-goto-bof)
(define-key filer-keymap #\C-p 'filer-backward-line-or-goto-eof)
;; (define-key filer-keymap #\Up 'filer-backward-line-or-goto-eof)
;; (define-key filer-keymap #\Down 'filer-forward-line-or-goto-bof)

;; filer.l
(defun open-single-filer ()
  "1画面ファイラ"
  (interactive)
  (multiple-value-bind (files result)
      (let ((omode (get-ime-mode)))
        (unwind-protect
            (filer nil t nil nil (not *filer-modal*))
          (and *filer-modal* (toggle-ime omode))))
    (when result
      (ed::filer-readin-1 files))))
(define-key ctl-x-map #\C-d 'open-single-filer)

(defun get-selection-string ()
  "セレクションの文字列を返します。"
  (selection-start-end (beg end)
    (buffer-substring beg end)))

;;; isearch の色付け (うまく使えない)
(require "isearch-deco")
(setq *isearch-visible-error* nil)
(setq *coloring-pattern-hilight-match* '(:bold t :background 6))
(setq *coloring-popup* nil)

;; xyzzy 付属の ftp クライアントの使い方
(require "wip/ftp")
(with-output-to-temp-buffer ("*ftp*")
  (let ((myftp (ftp-connect "ftp.gnu.org" 21)))
    (ftp-login myftp "anonymous")
    (ftp-pwd myftp)
    (ftp-quit myftp)))

;; これだとポート番号なしURLで使えないな…
(progn
  (string-match "http://\\(.*\\):\\(.*\\)" "http://newlisp.org:80")
  (list (match-string 1)
        (match-string 2)))      ; ("newlisp.org" "80")

;; xyzzy でネットラジオは出来なくても通信くらいは出来ないだろうか
;; (make-listen-socket)
(let ((host "208.122.59.30")	; http://www.sky.fm/guitar/
      (port 7062))
  ;; see also #'open-network-stream
  (with-open-stream (stream (connect host port))
    ;; リクエスト送信
    ;; リクエストの仕方がようわからん "GET / HTTP/0.9~2%" でも通る
    (format stream "GET / HTTP/1.0~%Host: ~A~%User-Agent: outfile~%Accept: */*~2%" host)
    ;; レスポンス受信
    (loop
      (let ((line (read-line stream nil nil)))
	(when (equal line "")
	  (return))
	(format t "~A~%" line)))))
;; ICY 200 OK
;; icy-notice1:<BR>This stream requires <a href="http://www.winamp.com/">Winamp</a><BR>
;; icy-notice2:SHOUTcast Distributed Network Audio Server/Linux v1.9.8<BR>
;; icy-name:S K Y . F M - Classical & Flamenco Guitar - a mix of classical, spanish, and flamenco guitar
;; icy-genre:Flamenco Classical Guitar
;; icy-url:http://www.sky.fm/guitar/
;; content-type:audio/aacp
;; icy-pub:1
;; icy-br:24
;; nil

;; ICY 401 Service Unavailable
;; icy-notice1:<BR>SHOUTcast Distributed Network Audio Server/Linux v1.9.8<BR>
;; icy-notice2:The resource requested is currently unavailable<BR>
;; nil


(defun minibuf-resize ()
  "ミニバッファを自動的に enlarge-window"
  (when (minibuffer-window-p (selected-window))
    (let ((l (save-excursion
	       (goto-char (point-max))
	       (current-line-number)))
	  (h (window-height)))
      (when (< 10 l)
	(setq l 10))
      (unless (= l h)
	(enlarge-window (- l h))
	(refresh-screen)))))
(add-hook '*post-command-hook* 'minibuf-resize)

;; with-current-bufferでおｋ?
(defmacro save-current-buffer (buffer &body body)
  "一時的にバッファ切り替え (作りかけ)"
  `(let ((#1=#:obuffer (selected-buffer)))
     (unwind-protect
         (progn (set-buffer ,buffer) ,@body)
       (set-buffer #1#))))
(save-current-buffer (find-buffer "*scratch*")
  (error "~S" (selected-buffer))) ; #<buffer: *scratch*>

(defun get-file-info1 (pathname)
  "ファイルの状態をまとめて取得 (組み込み関数置き換えver)"
  (let ((short-pathname (file-namestring (get-short-path-name pathname))))
    (list (get-file-attributes pathname) ; 属性
	  (file-write-time pathname)     ; 更新日
	  (file-length pathname)	 ; サイズ
	  (and (string/= short-pathname "") short-pathname) ; 短い名前
	  )))
(get-file-info "~/.xyzzy")	; (32 3426995023 21733 "XYZZY~1")

;;
(defun open-explorer (dir)
  "指定したパスをエクスプローラで開く。"
  (interactive "DExplorer: ")
  (or (shell-execute dir)
      (execute-shell-command (concat "start " (cwd)))))

;;; 手抜きコンパイル (エラー行ジャンプのおまけつき)
;;; 'execute-subprocess は非同期で実行される
(defun compile-c-file (file &optional exec)
  (interactive "fCompile (gcc): \nP" :default0 (get-buffer-file-name))
  (if (pathname-match-p file "*.c")
      (long-operation
	(pop-to-buffer (get-buffer-create "*Compile*") t)
	(execute-subprocess (concat "gcc -Wall -g " file
				    ;; 実行する
				    (and exec " && a.exe"))
			    :bufname (buffer-name (selected-buffer)))
	;; (goto-char (point-min))
	;;   (first-error)
	)
    (plain-error "Not C-file: ~A" file)))

(defun compile-bcc32 (buffer)
  "簡易 Bcc32 開発環境"
  (interactive "bCompile (bcc32): ")
  (let ((filename (get-buffer-file-name buffer)))
    (and (file-exist-p filename)
	 ;; コンパイルに成功したら実行も (異常終了なら0以外の値を持つ)
	 (= (pipe-command (format nil "bcc32 -W ~A" filename)) 0)
	 (shell-execute (format nil "~A.exe" (pathname-name filename)))
	 )))

(defvar *library-files-regexp*
  (compile-regexp (concat (si:system-root) "\\(?:site-\\)?lisp/.*.l"))
  "*load-path* にある Lisp ファイルにマッチする正規表現")

;; (message "　( ﾟдﾟ)y-~~~~~~~~~~") カップ麺を作ろう
(defun make-cupmem (minute)
  (interactive "NSet timer(minute): ")
  (popup-string (format nil "~A分後にできるよ" minute)
		(point))
  (start-timer (* minute 60)
	       #'(lambda ()
		   (message-box (format nil "~D 分たったよ" minute)
				"カップ麺タイマー" '(:information)))
	       t))

(multiple-value-bind (result data)
    (dialog-box '(dialog 0 0 100 30
		  (:caption "カップ麺タイマー")
		  (:font 9 "MS UI Gothic")
		  (:control
		   (:edit minute nil #x50810086 5 10 30 13)
		   (:spin minspin "Spin1" #x500000b6 0 0 0 0)
		   (:static nil "分" #x50020000 40 13 10 10)
		   (:button IDOK "セット(&S)" #x50010001 55 10 40 13)))
		'((minspin . 3))
		'((minute :type integer :min 1 :max 30
			  :type-error "数値を入力してしださい"
			  :range-error "計れる時間は1~30分です")))
  (when result
    (make-cupmem (cdr (assoc 'minute data)))))

(defun hex (file)
  "＼(^o^)／やったーhexlできたよー"
  (interactive "fHex: ")
  (with-open-stream (fp (open file :direction :input :encoding :binary))
    (with-output-to-temp-buffer ("*Hex*")
      (let ((ch) (chstack nil) (i 0))
	;; 繰り返しをどうにかしてなくしたい (read-line) ?
	;; awhile
	(while (setq ch (read-char fp nil))
	  (format t "~2,'0x " (char-code ch))
	  (push ch chstack)
	  (when (zerop (mod (incf i) 16))
	    (dolist (c (reverse chstack))
	      (format t "~C" (if (graphic-char-p c) c #\.)))
	    (setq chstack nil)
	    (format t "~%"))
	  ))
      (ed::toggle-mode 'buffer-read-only t t)
      (goto-char (point-min)))))
(compile 'hex)			; コンパイルしてもまだ遅い (1Mで10秒くらい)

(defun hex (filename)
  (interactive "fHex: ")
  (with-output-to-temp-buffer ("*Hex*")
    (lisphex filename)
    (ed::toggle-mode 'buffer-read-only t t)
    (goto-char (point-min))))

(defun lisphex (filename)
  (with-open-file (fp filename
		      :direction :input
		      :encoding :binary)
    (let ((address 0)
	  (string (make-array 16)))
      (format t "Address:  +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +a +b +c +d +e +f  0123456789ABCDEF~%")
      (format t "--------  -----------------------------------------------  ----------------~%")
      (loop
	(if (eq (peek-char nil fp nil :eof) :eof) ; EOF?
	    (return))
	(format t "~8,'0x: " address)
	(dotimes (i 16)
	  ;; EOF以降はNILで埋める
	  (setf (svref string i) (read-char fp nil nil)))
	(format t "~A~%"
		(with-output-to-string (stream)
		  ;; hex
		  (dotimes (i 16)
		    (let ((ch (svref string i)))
		      (if ch
			  (format t "~2,'0x " (char-code ch))
			(format t "   "))))
		  (princ #\space)
		  ;; chars
		  (dotimes (i 16)
		    (let ((ch (svref string i)))
		      (princ (if ch
				 (if (graphic-char-p ch) ch #\.)
			       #\space)
			     stream)))))
	(incf address #x10)))))
(compile 'lisphex)

(with-open-file (fp "hoge"
		    :direction :output
		    :if-exists :overwrite
		    :if-does-not-exist :create
		    :element-type 'unsigned-byte)
  (dolist (v '(#xfe #xff #x26 #x23)) ; ベクタ使いたい
    #+xyzzy (write-char (code-char v) fp)
    #+clisp (write-byte v fp)
    ))
(write-char (code-char #xfe))	;  / Error: represented in the character set "CP932"

;;; Hexl on LISP を作ってみよう
(defvar-local *buffer* nil)
(defvar-local *size* 0)
(defun lhex-find-file (filename)
  (with-open-file (fp filename
			:direction :input
			#+common-lisp :element-type #+common-lisp 'unsigned-byte
			#+xyzzy :encoding #+xyzzy :binary)
    (setf *size* (file-length fp)
	  *buffer* (make-array *size*))
      (dotimes (i *size*)
	(setf (svref *buffer* i)
	      #+common-lisp (read-byte fp)
	      #+xyzzy (char-code (read-char fp))
	      ))))
(compile 'lhex-find-file)
;; (lhex-find-file "XTAGS")
(defun lhex-save-buffer (&optional filename)
  (setf filename (or filename "hoge.txt"))
  (with-open-file (fp filename :direction :output :encoding :binary)
    (dotimes (i *size*)
      (write-char (code-char (svref *buffer* i)) fp))))
;; #(35 85 83 69 32 46 46 47 13 10)
(mapcar 'code-char '(35 85 83 69 32 46 46 47 13 10))
;; (#\# #\U #\S #\E #\SPC #\. #\. #\/ #\RET #\LFD)

;; int isascii(int C);
(defun ascii-char-p (c)
  "アスキー文字か (0x00-0x7F)"
  (< (char-code c) 128))

;;; バックアップファイル一覧から最新のファイルを取り出したい (未完成)
(directory *backup-directory* :absolute t)
(file-write-time "~/.xyzzy")	; ファイルの最終更新日をユニバーサルタイム形式で
(file-newer-than-file-p FILE1 FILE2) ; ファイルの更新日を比較

(defun find-backups (file)
  (if (stringp *backup-directory*)
      (let ((wildname (format nil "~A*"
			      (merge-pathnames (if *hierarchic-backup-directory*
						   (remove #\: file)
						 (file-namestring file))
					       *backup-directory*))))
	(append (directory wildname :absolute t)
		(directory (concat file "~") :absolute t)))))

(defun open-backup (file)
  (interactive "fOpen backup: " :default0 (get-buffer-file-name))
  (let ((backups (stable-sort (find-backups file)
			      #'file-newer-than-file-p)))
    (if backups
	(let ((select (completing-read (format nil "~A file~:P found (~A): "
                                               (list-length backups)
                                               (file-namestring file))
		       (let ((choice '()))
			 (dotimes (n (length backups) (nreverse choice)) 
			   (push (format nil "~A: ~A"
					 n (format-date-string
					    "%Y-%m-%d(%a) %H:%M:%S%#Z"
					    (file-write-time (nth n backups))))
				 choice)))
		       :must-match t)))
	  (find-file (nth (parse-integer (car (split-string select #\:)))
			  backups)))
      (message "バックアップはありません: ~A" (file-namestring file)))))

(defun find-recent-backup (file)
  (let ((backups (stable-sort (find-backups file)
			      #'file-newer-than-file-p)))
    (if backups (car backups))))

(defun open-recent-backup (file)
  (interactive "fOpen backup: " :default0 (get-buffer-file-name))
  (let ((backup (find-recent-backup file)))
    (if backup
	(and (find-file backup)
	     (message (format-date-string "%Y-%m-%d(%a) %H:%M:%S%#Z"
					  (file-write-time backup))))
      (error "バックアップファイルはありません: ~A" (file-namestring file)))))

(defun runcmd (cmd)
  "外部コマンド結果だけ表示 (by 佐野さん)"
  (let ((buf (create-new-buffer "hoge"))
	proc)
    (save-window-excursion
      (with-set-buffer
	(set-buffer buf)
	(setq proc (make-process cmd))
	;; ループにすると遅くなるんじゃないかな?
	(while (eql :run (process-status proc))
	  (do-events))
	(prog1
	    (buffer-substring (point-min) (point-max))
	  (delete-buffer buf))))))
(runcmd "cmd /c dir c:")

(setq *filer-guide-text*
      (concat
       "A:属性		B:ﾊﾞｲﾄｺﾝﾊﾟｲﾙ	C:ｺﾋﾟｰ		D:削除		E:解凍\n"
       "F:検索		G:ﾌｧｲﾙ名検索	J:DIR移動	K:mkdir		L:ﾄﾞﾗｲﾌﾞ\n"
       "M:移動		N:ﾌｧｲﾙ名	O:圧縮		P:DIR??		Q:終了\n"
       "R:名前変更	S:DIR??		T:ｼｮｰﾄｶｯﾄ	U:DIRｻｲｽﾞ	V:ﾘｽﾄ\n"
       "W:閲覧		X:実行		Y:ｼｮｰﾄｶｯﾄ	Z:ﾌﾟﾛﾊﾟﾃｨ\n"
       "\n"
       "*:load		.:ﾏｽｸ		/:ﾏｰｸ		<:先頭		>:末尾\n"
       "@:別名ｺﾋﾟｰ	\:ﾙｰﾄ		=:比較		^:ｲｼﾞｪｸﾄ	]:送る\n"
       "\n"
       "C-h:上ﾃﾞｨﾚｸﾄﾘ	C-r:後isearch	C-s:前isearch	C-u:ﾃﾞｨﾚｸﾄﾘｻｲｽﾞ\n"
       "C-1:ﾌｧｲﾙ広	C-2:ｻｲｽﾞ広	C-3:日時広	C-4:属性広\n"
       "C-M-1:ﾌｧｲﾙ狭	C-M-2:ｻｲｽﾞ狭	C-M-3:日時狭	C-M-4:属性狭\n"
       "\n"
       "M-g:grep	M-r:gresreg	M-v:ﾘｰﾄﾞｵﾝﾘｰ\n"
       "\n"
       "F3:実行		F5:ﾏｰｸﾄｸﾞﾙ	F6:ｿｰﾄ		S-F10:ﾎﾟｯﾌﾟｱｯﾌﾟﾒﾆｭｰ\n"
       "\n"
       "TAB:移動	SPC:ﾏｰｸ\n"
       "Home:ﾄｸﾞﾙ(ﾌｧｲﾙ)	S-Home:ｸﾘｱ	C-Home:ﾄｸﾞﾙ(含Dir)	S-C-Home:全ﾌｧｲﾙﾏｰｸ\n"
       "End:ﾘﾛｰﾄﾞ\n"
       "\n"
       ))
(msgbox *filer-guide-text*)

(defun goto-point (p)
  (interactive "NGoto point: ")
  (goto-char p))

;; "*.l" から "*" を取り出す
(progn
  (string-looking-at "\\(.+\\).l" "wip/ftp.l")
  (match-string 1))		; "wip/ftp"
(pathname-name "wip/ftp.l")	; "ftp"

;; #'toggle-newline とかは別の話なのか (buffer-local とか) ?
(defun toggle-visible-flag (arg)
  "見えないものが見えるようになる"
  (interactive "P")
  (set-local-window-flags (selected-buffer)
			  (+ *window-flag-tab*
			     *window-flag-newline*
			     *window-flag-half-width-space*
			     *window-flag-full-width-space*)
			  arg))

;; 指定時間よりも古いバックアップは削除
;; time-before は misc.l にある
(labels ((get-time (info)
	   (third info)))
  (let ((before (time-before (get-universal-time) 0 0 0 0 2 0))) ; 2ヶ月前
    (dolist (backup (directory *backup-directory*
			      :file-only t :absolute t :file-info t :recursive t))
      ;; 比較おかしい?
      (if (plusp (- before (get-time backup)))
	  ;(delete-file (get-path files))
	  (format t "~A ~A~%"
		  backup
		  (format-date-string "%y/%m/%d %H:%M:%S" (get-time backup)))
	))))

;;; defadvice みたいなことができそう
(command-execute 'next-line
		 #'(lambda (x y) (msgbox "~w\n~w" x y)))

;; こっちの方が kill-whole-line の名前らしいかも (行削除)
(define-key ctl-x-map #\d
	    (lambda ()
	      (interactive)
	      (kill-region (progn (goto-bol) (point))
			   (progn (forward-line 1) (goto-bol) (point)))))
;;; xyzzy分からぬやし11 >>816
(defun kill-whole-line (&optional lines)
  (interactive "*p")
  (kill-line (or lines (if (bolp) 1))))

;; カーソル位置から行頭までkill-line
(kill-line 0)

;; バッファ末尾ならついでに行末へ
(unless (next-virtual-line)
  (goto-eol))

;;; エラーの投げ方
(error 'type-error :datum #(nil foo hoge) :expected-type 'sequence)
;;=> 不正なデータ型です: #(nil foo hoge): sequence

;; 文字列はformat形式で渡す
;; 定義されているコンディション
;; lisp/condition.l を見るとまだいっぱいある…
(error 'too-many-arguments)     ; 引数が多すぎます: nil
(error 'too-few-arguments)      ; 引数が少なすぎます: nil
(error 'range-error :datum most-positive-fixnum) ; 範囲外の値です: 2147483647
(error 'plain-error)
(error 'simple-warning)         ; nil
(error 'file-not-found
       :datum "ファイルが見つかりません"
       :pathname (get-windows-directory)) ; C:/WINDOWS/\nファイルが見つかりません
(error 'reader-error )           ; lisp/ole.l:27:
(error 'type-error
       :datum #C(1 1)
       :expected-type '(or string symbol)) ; 不正なデータ型です: #C(1 1): (or string symbol)
(error 'bad-type-specifier :datum 'character) ; 型指定子が不正です: character

;; どう使い分けるんだ?
(file-exist-p "~/")		; t
(check-valid-pathname "~/")	; t
(file-exist-p"C:/tmp/Samples/C++/XInput/") ; nil
(check-valid-pathname "C:/tmp/Samples/C++/XInput/") ; 指定されたパスが見つかりません。 

;; filer-directory-history-update
(dolist (dir #1=ed::*filer-directory-history* #1#)
  (unless (file-exist-p dir)
    (setf ed::*filer-directory-history*
          (delete dir ed::*filer-directory-history* :test #'equalp))))
(length ed::*filer-directory-history*)

(defun compile-and-delete-dump-file ()
  "siteinit.l のバイトコンパイル & ダンプファイル削除を一発でやる."
  (interactive)
  (let ((file (find-load-path "siteinit")))
    (when (and file (string-match "\\.lc$" file))
      (setq file (substring file 0 -1)) ; siteinit.lc -> siteinit.l
      (and (file-exist-p file)
           (compile-file file)))
    (delete-file (si:dump-image-path) :if-does-not-exist :skip)))

(defun directory-tree (dir)
  "簡単なディレクトリツリー"
  (labels ((string-last (str &optional (n 1))
	     (substring str (- (length str) n))))
    (dolist (path (directory dir :show-dots t :absolute t))
      (if (and (file-directory-p path)
	       (string/= (string-last path 2) "./")
	       (string/= (string-last path 3) "../"))
	  (directory-tree path)
	(format t "~S~%" path)))))
(directory-tree "~/usr/")

(dolist (path (directory "~/usr/" :absolute t :show-dots t :recursive t))
  (format t "~S~%" path))

;;; かてふモード
;;; comment.l が共存できないようなので注意
(push (merge-pathnames "site-lisp/katex" (si:system-root)) *load-path*)
(push (merge-pathnames "site-lisp/katex" (si:system-root)) *default-load-path*)
(require "elisp")
(push '("\\.tex$" . elisp::katex-mode) *auto-mode-alist*)
(autoload 'elisp::katex-mode "katex" t)
(setq elisp::tex-command "platex")

(defun exec (str-process)
  "newLISP function `exec'"
  (let ((outfile (make-temp-file-name))
	(buffer (create-new-buffer " *exec*")))
    (unwind-protect
	(save-excursion
	  (call-process str-process :output outfile :show :minimize :wait t)
	  (set-buffer buffer)
	  (insert-file-contents outfile)
	  ;; ここらへんあやしい
	  (split-string (buffer-substring (point-min) (point-max)) #\LFD))
      (and buffer (delete-buffer buffer))
      (and outfile (delete-file outfile :if-does-not-exist :skip)))))
(exec "ls -1 *.exe")		; ("xyzzy.exe" "xyzzycli.exe" "xyzzyenv.exe")

;; si:closure-frame ってなんだ?
(defun foo (x)
  (flet ((bar (y) #'(lambda (z) (+ x y z))))
    #'bar))
(si:closure-frame (funcall (foo 1) 2)) ; ((block bar nil) (block foo nil))
(let ((f (block foo (lambda () ()))))
  (si:closure-frame f))		; ((block foo nil))

;;; アクティブに反応 (特に意味なし)
(add-hook '*activate-hook*
	  (defun xyzzy-msg ()
	    (message-box "xyzzy activate")))

;;; 括弧のぐーたら補完
(add-hook '*post-command-hook* 'add-closed-paren)
(defun add-closed-paren ()
  (when (eq *this-command* 'self-insert-command)
    (cond ((looking-back "(") (insert ")") (backward-char))
	  ((looking-back "{") (insert "}") (backward-char))
	  ((looking-back "[") (insert "]") (backward-char)))))

(defun read-exist-mode (prompt)
  "モード読み込み"
  (let (modelist)
    (do-symbols (sym *package*)
      (if (and (string-match ".*-mode$" (string sym))
	       (fboundp sym)
	       (and (si:*closurep (symbol-function sym))
		    (some #'(lambda (x) (and (sequencep x) (find 'buffer-mode x)))
			  (fourth (si:closure-body (symbol-function sym))))))
	  (push sym modelist)))
    ;; コレだけのほうが早いのだが...
    (dolist (mode (mapcar #'cdr *auto-mode-alist*))
      (pushnew mode modelist :test #'equal))
    (completing-read prompt modelist :must-match t)))
(defun narrow-to-region-with-toggle-ode (mode from to)
  "選択範囲のみに MODE を適用"
  (interactive (list (read-exist-mode "Mode: ")
		     (mark) (point)))
  (narrow-to-region from to)
  (funcall (find-symbol mode)))
(defun widen-with-previous-mode ()
  "widen して以前のモード再開"
  (interactive)
  (widen)
  (revert-mode))

(defun revert-mode ()
  (interactive)
  (let ((param (assoc "mode" (ed::find-file-scan-params) :test #'equalp)))
    (if param
	(ed::find-file-auto-mode (cdr param))
      (funcall (cond ((file-visited-p)
		      (let ((filename (get-buffer-file-name)))
			(or (some #'(lambda (x)
				      (and (string-matchp (car x) filename)
					   (cdr x)))
				  *auto-mode-alist*)
			    *default-buffer-mode*)))
		     ((equal (buffer-name (selected-buffer)) "*scratch*")
		      *initial-buffer-mode*)
		     (t
		      *default-buffer-mode*))))))

;; :external ならそのパッケージから export されている
;; :inherited ならパッケージは違うが参照できる (inherit:継承する)
(multiple-value-list
 (find-symbol "filer-set-directory" "editor")) ; (filer-set-directory :external)
(multiple-value-list
 (find-symbol "filer-set-directory" "user")) ; (filer-set-directory :inherited)

;; うちの環境だと [R-ALT] の右隣が #\Apps
(global-set-key #\Apps 'apps-popup) ; mouse.l
(global-set-key #\M-Apps 'about-dialog)	; なんとなく

;; Left-ctrl-break でも #\C-g

;; [考察]
;; マウス操作(他メニュー選択など)はトップレベルでしか受け付けないんだと思う.
;; トップレベル(でいいのか)ってのはつまり関数処理とかしてないヒマな状態の事.
;; だから isearch で検索している間は関数実行中に当たるのでマウスが使えなくなる.
;; キーボード入力は別で常時受け付けていると思われる(C-gが使えるとか).
;; (read-char) も関数内部で入力を待ってるからマウスが使えないのかな.
;; ファイラも関数なのか? モードレスにすると編集作業に戻れるが.

;;; prolog-mode :キーワード(~/etc/prolog)を追加しよう
(load-library "prolog")
(pushnew '("\\.pl$" . prolog-mode) *auto-mode-alist* :test #'equal)

;; ヘルプでもキーワードの色付けがほしい
;; こいつがあると起動時に無限ループする?
'(setq *default-buffer-mode* 'lisp-mode)

;;; *scratch* バッファにて (goto-matched-parenthesis) が対応する括弧を
;;; 見つけられないとやたら処理落ちするようになった [2008-07-31]
;;; バッファ消したら直った. 気のせい?

;;; loop マクロを使いこなしてみたい
;;; http://smpl.seesaa.net/article/29800843.html
;;; http://www.unixuser.org/~euske/doc/cl/loop.html
(modulep 'cmu_loop)
(require "cmu_loop")
(require "loop/loop")
(loop :for i :from 0 :to 10 :collect i)	; (0 1 2 3 4 5 6 7 8 9 10)
;; たぶん移植元
;; http://www.cs.cmu.edu/afs/cs/project/ai-repository/ai///lang/lisp/code/iter/loop/cmu/cmu_loop.cl

;; 違うかもしれない
(defun count-modified-buffers ()
  (loop :for buffer :in (buffer-list) :count (buffer-modified-p buffer)))

;;; misc.l (init-misc-objects)
;; *default-load-path* はxyzzy起動時に *load-path* にマージされる
(mapc #'(lambda (x)
	  (pushnew x *load-path* :test #'equalp))
      *default-load-path*)

;;; wiki/tips/ファイルを開く時にセッションファイルならば展開する
(add-hook '*before-find-file-hook*
          #'(lambda (x)
              (when (and (string-matchp "\\.ssn$" x)
			 (y-or-n-p "セッションファイルだよ、ロードする?: ~A" x))
                (load-session x t)
                (selected-buffer))))

;;; which-function-mode [xyzzy:04087]
;; めっさてけとーなのでよければこんな感じでできます。これ
;; だとモードの解除もできないし、関数名の探し方もいいかげ
;; んなので、実用にはならないと思いますが。誰か気合のある
;; 人がちゃんとしたのを書いてくれるかも…。
(defun which-function-mode (&optional (arg nil sv))
  (interactive "p")
  (ed::toggle-mode 'which-function-mode arg sv)
  (if which-function-mode
      (progn
	(make-local-variable 'which-function-mode-name)
	;(setq which-function-mode-name "")
	(make-local-variable 'which-function-mode-last-point)
	;(setq which-function-mode-last-point (point))
	(add-hook '*post-command-hook* 'which-function-find-defun))
    (delete-hook '*post-command-hook* 'which-function-find-defun))
  (update-mode-line))
(defvar-local which-function-mode nil)
(pushnew '(which-function-mode . which-function-mode-name)
	 *minor-mode-alist* :key #'car)
(defun which-function-find-defun ()
  (when (and which-function-mode
	     (boundp 'ed::build-summary-function))
    (let ((summary (funcall ed::build-summary-function)))
      (save-excursion
	(forward-line)
	(beginning-of-defun)
	(unless (eql which-function-mode-last-point (point))
	  (setq which-function-mode-last-point (point))
	  (setq which-function-mode-name
		(format nil "<~A>"
			(cadar (last (remove-if #'(lambda (x)
						    (> x (current-line-number)))
						summary
						:key #'car)))))
	  (update-mode-line))))))

;;; 某ブラウザ見たいなタブ切り替え
(set-extended-key-translate-table exkey-C-tab #\F13)
(set-extended-key-translate-table exkey-S-C-tab #\F14)
(global-set-key #\F13 'next-buffer)
(global-set-key #\F14 'previous-buffer)

;;; clickable-uri.l参照
;;; case-fold は? (compiled-regexp-case-fold-p, equalp)
;;; コンパイルされた正規表現のみ
(defun regexp-equal (regexp regexp2)
  "正規表現が等しいか"
  (string= (compiled-regexp-source regexp1)
	   (compiled-regexp-source regexp2)))

;;; [xyzzy:04494]
;;; ローカルの割り当てで上書きされる
(global-set-key #\C-h 'backward-delete-char)
;;; 置き換えも無理？
(substitute-key-definition 'backward-delete-char-untabify-or-selection
			   'delete-backward-char)
;;; なので関数の再定義 (なんか恐い)
(setf (symbol-function 'backward-delete-char-untabify-or-selection)
      #'delete-backward-char)

(command-execute-in-keymap "key function: "
                           (eval (first
                                  (find-all-symbols
                                   (completing-read "Keymap: " (keymaplist) :must-match t)))))

(key-to-string #\C-a)		; "C-a"

;;; ベクタのほうがアクセスが早いんだろうね >keymap
(type-of ctl-x-map)		; simple-vector (make-keymap)
(type-of ctl-x-4-map)		; cons (make-sparse-keymap)

(svref ctl-x-map (char-code #\C-s)) ; save-buffer (C-x C-s)
(assoc #\C-k spec-map)		; (#\C-k . kill-subprocess)

;;; ~/src/src/keymap.cc
(defconstant keymap-length (+ 128 (* 4 (+ (- #xff3e #xff00) 1)))) ; 380
(defun keymap? (object)
  "だいたい keymapp と同じ."
  (cond ((null object)
	 nil)
	((symbolp object)
	 (keymap? (symbol-function object)))
	((or (and (simple-vector-p object)
		  (eql (length object) keymap-length))
	     (and (consp object)
		  (eq (car object) 'keymap)))
	 object)))

;; lookup-keymap 途中
(defun lookup-keymap (keymap key &optional ignore-case symbol-only)
  (cond ((not (keymapp keymap))
         (error 'type-error :datum keymap :expected-type 'keymap))
        ((not (typep key #1='(or character cons)))
         (error 'type-error :datum key :expected-type #1#))
        ((consp keymap)
         (assoc key keymap))
        ((simple-vector-p keymap)
         (svref keymap (char-code key)))
        ))

;;; xyzzy, emacs の正規表現はリテラルでなく文字列で表現しているのでややこしい
;;; EmacsLisp/正規表現(山本和彦) http://www.mew.org/~kazu/doc/elisp/regexp.html
;;; それなら正規表現をシンボルに登録すればいい気がする
(compile-regexp (string 'a+b*))	; #<compiled regular expression: a+b*>

;; シンボルを|hoge|で括ってもだめだな...
(symbol-name '|(a\\\|b\\.*)|)   ; "(a\\|b\\.*)"
(symbol-name '|\\(\\)|)
(symbol-name '|[ \t]+$|)        ; "[ t]+$"
(symbol-name '|[ \\t]+$|)       ; "[ \\t]+$"
(symbol-name '|^[^:]+:\\w+:|)   ; "^[^:]+:\\w+:"
(symbol-name '|^\\*\\{3\\}|)    ; "^\\*\\{3\\}"
(symbol-name '|\\.lc$|)         ; "\\.lc$"

;;; 名前空間がかぶるならハッシュとか?

;;; システムパッケージからは何でも参照できる仕様なのかも >xyzzy
;;; システムパッケージがLispパッケージを利用しているからか?
(package-use-list (find-package :system)) ; (#<package: lisp>)
(system::sequencep "xyzzy")		; t
(system::append '(a b c d) '(1 (2 (3 4))) 8) ; (a b c d 1 (2 (3 4)) . 8)
(symbol-package 'si::reverse)	; #<package: lisp>
(system::reverse '(a b c d))	; (d c b a)
(read-from-string "(system::sequencep \"xyzzy\")") ; (sequencep "xyzzy") ;27

(add-hook '*kill-xyzzy-hook*
	  (defun kill-xyzzy-message ()
	    (message "bye.")))

(defun pathname-file (pathname)
  "file-namestring と同等"
  (substring pathname (1+ (position #\/ pathname :from-end t))))
(pathname-file "C:/home/xyzzy/site-lisp/siteinit.l") ; "siteinit.l"

(format nil "~A.~A"
        (pathname-name #1="C:/home/xyzzy/site-lisp/siteinit.l")
        (pathname-type #1#))    ; "siteinit.l"

;;; 関数とその行
(mapcar #'(lambda (x)
	    (format nil "~A: ~A" (car x) (cadr x)))
	(funcall ed::build-summary-function))

;;; なぜかシンボルも文字に変換される
(split-string '#:Kobayashi+Shigeru #\+) ; ("Kobayashi" "Shigeru")

(defun mark-this-sexp ()
  (interactive)
  (if (eq (parse-point-syntax) :string)
      (while (eq (parse-point-syntax) :string)
	(backward-char))
    (up-list -1))
  (set-mark)
  (forward-sexp))

;; Winamp を操作
(require 'winamp)
;; (delete-command-bar 'winamp-tool-bar)

;; 似非 xyzzy :Webでモードラインつき文書編集
;; http://lowreal.net/2005/eta

;;; #\Space を読んだら #\SPC に脳内変換してくれたらうれしいんだが
;;; やはりシステム依存かなぁ

;;; タイムスタンプ
;;; ファイルの更新日時だけなら "ls -l" でも分かるよなぁ
;;; でもファイル自体の日付はバックアップなんかで更新されるから困る
(require "auto-time-stamp")
(setq ed::*time-stamp-start* "Time-Stamp:[ \t]+[<\"]")
(setq ed::*time-stamp-end* "[>\"]")
(setq ed::*time-stamp-format* "%Y-%m-%d(%a) %H:%M:%S %Z")
(defun with-time-stamp-hook ()
  "ファイルの保存時にタイムスタンプを挿入します。"
  (interactive)
  (and *time-stamp-active*
       (ed::time-stamp))
  nil)
(add-hook '*before-save-buffer-hook* 'with-time-stamp-hook)
(defun insert-time-stamp-template ()
  "タイムスタンプのテンプレートを挿入."
  (interactive "*")
  (insert "Time-Stamp: <>"))

;;; filer
(list-archive "C:/home/lxuser/cygwin-ja/lessjw02.zip")
;; (("usr/" "---W-" 0 (2001 1 26 1 23 30))
;;  ("usr/local/" "---W-" 0 (2001 1 23 0 55 16))
;;  ("usr/local/bin/" "---W-" 0 (2001 1 23 0 57 58))
;;  ("usr/local/bin/lesskey.exe" "---W-" 48640 (2001 1 23 22 57 54))
;;  ("usr/local/bin/less.exe" "---W-" 181248 (2001 1 23 22 57 54))
;;  ...
;;  ("usr/local/man/" "---W-" 0 (2001 1 23 0 55 0)))

;;; デバッグに使えるかも
;; (let ((*features* (append *features* '(:debug))))
;;   ...)

;; (if nil #\; #\:)
;;             ^
;; ここで RET (lisp-newline-and-indent) を実行すると無限ループ
;; 原因: lispmode.l 212行目のwhile?

;;; 気が向いたらxyzzyをアクティブになって…いる？
(start-timer 5 #'si:*show-window-foreground t)
;; xyzzyを他のウィンドウの最前面に表示します。
(start-timer 5 #'si:*activate-toplevel t)

(= (count-buffers t) (list-length (buffer-list))) ; t
(defun enum-buffers (fn)
  "関数がnil以外を返すまでバッファを列挙し続けます。"
  (some fn (buffer-list)))

;;; [xyzzy:06348] Re: Xyzzycli を外部エディタとして使いたい
;;; http://hie.s64.xrea.com/xyzzy/ml/msg06347.html

;;; BUG?
;; http://cadr.g.hatena.ne.jp/g000001/20080427/1209306506
;; xyzzyで、defpackageでexportを指定しても、exportしてくれないのはどういう理由?
;; →バグな様子。

#|
C++->CL変換すれば分かるんじゃね
../src/src/pathname.cc:522:Fpathname_directory (lisp pathname)
|#
(pathname-directory "C:/home/xyzzy/") ; ("home") / (:ABSOLUTE "home" "xyzzy")
(pathname-directory "C:/home/")	; nil / (:ABSOLUTE "home")

(length (format nil "~10,4,1,'*@A" ""))	; 12 / 13

(defun define-keys (keymap keys)
  "まとめてdefine-key"
  (mapc (lambda (key)
	  (define-key keymap (car key) (cdr key)))
	keys)
  t)
(define-keys *global-keymap*
	     '(((#\C-x #\t #\z) . toggle-zenkaku-space)
	       ((#\C-x #\t #\n) . toggle-newline)
	       ((#\C-x #\t #\t) . toggle-tab)
	       ((#\C-x #\t #\e) . toggle-trace-on-error)))

(funcall
 (compile (defun lnk2html (pathname)
            (with-open-file (fpin pathname
                                  :direction :input
                                  :encoding :binary) ; 文字コード無視
              (with-open-file (fpout (substitute-string pathname "\\..+$" "\\.html") ; *.* -> *.html
                                     :direction :output
                                     :encoding :binary
                                     :if-exists :overwrite
                                     :if-does-not-exist :create)
                (format fpout "<html>~%<head><title>Link</title></head>~%<body>~%")
                ;; 目次もほしいな
                (let (lnkname)
                  (loop
                    (let ((line (read-line fpin nil :eof)))
                      (cond ((eq line :eof)
                             (return))
                            ;; or (search "http" line)
                            ((string-match ed::*clickable-uri-regexp* line)
                             (format fpout "~A<a href=\"~A\">~A</a><br>~%"
                                     (if (eq (char lnkname 0) #\:) "`--" "")
                                     (string-right-trim "" line)
                                     (string-right-trim "" lnkname)))
                            (t
                             (and (string/= line "")
                                  (case (char line 0)
                                    ;; TITLE_TAG
                                    (#\- (format fpout "<h2>~A</h2>~%" (substring line 50)))
                                    ;; COMMENT_TAG
                                    (#\# (format fpout "~A<br>~%" line))
                                    ;; リンク名
                                    (t   (setf lnkname line))
                                    )))))))
                (format fpout "</body>~%</html>~%")))))
 "G:/bookmark/lnk_main.txt")

;;; #'typepの引数が無駄に便利
(typep (selected-buffer) '(satisfies buffer-process))
;; == (buffer-process (selected-buffer))
(typep 5 '(integer 1 10))	; == (and (integerp n) (<= 1 n 10)))

;; 複数行コメントの中での括弧をインデントされるのはイヤだなあ

;; 右隣のバッファ (next-buffer)
(get-next-buffer (selected-buffer) nil *next-buffer-in-tab-order*)
;; 左のバッファ
(get-next-buffer (selected-buffer) t *next-buffer-in-tab-order*)

;; C:/Program Files/GCL-2.6.7-CLtL1/bin/gcl.bat
(call-process (format nil "~A -eval ~S"
		      "C:/PROGRA~1/GCL-2.6.7-CLtL1/lib/gcl-2.6.7/unixport/saved_gcl.exe"
		      "(setq si::*allow-gzipped-file* t)")
	      :environ `(("PATH" . ,(concat "C:/PROGRA~1/GCL-2.6.7-CLtL1/mingw/bin;"
					    "C:/PROGRA~1/GCL-2.6.7-CLtL1/libgcl-2.6.7/unixport;"
					    (si:getenv "PATH"))))
	      :exec-directory "C:/PROGRA~1/GCL-2.6.7-CLtL1/lib/gcl-2.6.7/unixport/"
	      :no-std-handles t
	      :show t
	      :wait nil)

;; inferior-gcl 作れそう
;; バッファからGCL
(let ((*eshell* (get-short-path-name
                  (merge-pathnames "GCL-2.6.7-CLtL1/lib/gcl-2.6.7/unixport/saved_gcl.exe"
                                   (si:getenv "ProgramFiles")))))
  (shell))

;;; http://127.0.0.1:8823/thread/http://pc11.2ch.net/test/read.cgi/win/1209098133/
;;; xyzzy Part16 >>97
;;; listen の挙動がわからない
(macrolet ((while (test &body body)
	     `(do ()
		  ((not ,test))
		,@body)))
  (with-input-from-string (s "abc")
    (while (listen s)
      (print (read-char s)))))	; Error / #\a #\b #\c NIL
;; とりあえずは次のでOK
;; s/(listen s)/(peek-char nil s nil nil)

;; カンで実装
(defun listen (&optional input-stream)
  (let ((ch (read-char-no-hang input-stream nil nil)))
    (prog1
	(and ch t)
      (and ch (unread-char ch input-stream)))))


#|
CLHS: Function READ-CHAR-NO-HANG
* If a character is available on the input stream, return the character.
Otherwise, return NIL.
= ストリームに何か文字があればそれを返す。そうでなければNILを返す。
Notes:
* read-char-no-hang is exactly like read-char, except that if it would be 
necessary to wait in order to get a character (as from a keyboard), nil is 
immediately returned without waiting.
= read-char-no-hangは入力を待つ必要がない点を除いてはread-charと同じだ。
待つような入力がなければnilを返す。
|#

#|
http://www.lispworks.com/documentation/HyperSpec/Body/26_glo_e.htm#end_of_file
CLHS: Function LISTEN
Description:
Return true if there is a character immediately available from input-stream 
; otherwithe, returns false. On a non-interactive input-stream, listen 
returns true except when at end of file[1]. If an end of file is 
encountered, listen returns false. listen is intended to be used when 
input-stream obtains characters from an interactive device such as a keyboard.
= 入力ストリームになにか文字があればtrueを、そうでなければfalseを返す。
非対話的な入力ストリームの場合、EOFを除いてtrueを返す。EOFの時はfalseを返す。
listenはキーボードのような対話的なデバイスから文字を得るために使われる。

http://www.lispworks.com/documentation/HyperSpec/Body/26_glo_e.htm#end_of_file
* end of file n.
1. the point in an input stream beyond which there is no further data.
Whether or not there is such a point on an interactive stream is
implementation-defined.
2. a situation that occurs upon an attempt to obtain data from input stream 
that is at the end of file[1].
= EOF
1. 入力ストリーム上の、これ以上データがないポイント。(?)
何れにせよ実装定義されたような対話的なストリーム上のポイント。
2. EOFに達した入力ストリームから入力を得ようとしている状態。(?)
|#

;;; Elisp Function: split-string
;;; http://www.fan.gr.jp/~ring/doc/elisp_20/elisp_5.html
;;; http://raido.sakura.ne.jp/southly/rn/index.rb?1142181148.txt
;;; NANRIさんのを参考に繰り返しで split-string
;;; 文字列セパレータにもへなちょこに対応
;;; 汚い
(defun split (string &optional (separator #\space) omit-nulls)
  (labels ((pos (str sep)
	     (position sep str :test #'(lambda (x y) (find y x :test #'char=)))))
    (let ((sep (string separator))
	  (acc '()))
      (do* ((str string (subseq str (1+ n)))
	    (n (pos str sep) (pos str sep)))
	  ((null n)
	   (nreverse (if omit-nulls
			 `(,str ,@acc)
		       (remove "" `(,str ,@acc) :test #'string=))))
	(push (subseq str 0 n) acc)))))
(split "C:/home/xyzzy/lisp/cmds.l" "/")	; ("C:" "home" "xyzzy" "lisp" "cmds.l")
(split "C:/home/xyzzy/lisp/cmds.l" #\/)	; ("C:" "home" "xyzzy" "lisp" "cmds.l")
(split "system::typespec-alist" #\:) ; ("system" "typespec-alist")
(split "system::typespec-alist" #\: t) ; ("system" "" "typespec-alist")
(split "system::typespec-alist" "::") ; ("system" "typespec-alist") ; search関数使えばできるが…
(split "shigeru kobayashi" ":") ; ("shigeru kobayashi")
(split "shigeru kobayashi" "") ; "shigeru kobayashi"

;; http://howm.sourceforge.jp/README-test-j.html
;; $Maxima/smart-complete.el
(defun split (s bag)
  (cond ((zerop (length s))
	 '(""))
	((string-match bag s)
	 (if (zerop (match-beginning  0))
	     (cons "" (split-string (substring s (match-end 0)) bag))
	   (cons (substring s 0 (match-beginning 0))
		 (split-string (substring s (match-end 0)) bag))))
	(t
	 (cons s nil))))

;;; declare と doc-string の共存がおかしい件
;;; 順番決まっているのかな？
(defun hoge (x)
  "hoge"
  (declare (ignore x)))
(hoge 10)			; Error / NIL
(documentation 'hoge 'function)	; "hoge" / "hoge"

(defun hoge (x)
  (declare (ignore x))
  "hoge")
(hoge 10)			; "hoge" / "hoge"
(documentation 'hoge 'function) ; "hoge" / NIL

(defun hoge (x)
  (declare (ignore x))
  "Comment"
  (* x x))
(hoge 10)                       ; 100
(documentation 'hoge 'function) ; "Comment"

;; 恐らく declare は lambda/let* の直後のみ使える
;; interactive との併用で余計ややこしくなる
(defun hoge (x)
  "Comment"
  (interactive "P")
  ;; (declare (special x))
  (message "~S" x))

(defun nth-line (n str)
  "文字列 STR の N+1 行目を取り出す."
  (nth n (split-string str #\LFD)))

;;; #'arglist
;;; NANRIさんからのコメントより
(defun builtin-function-name (f)
  (when (string-match "#<function: \\(.+\\)>" (princ-to-string f))
    (match-string 1)))
(builtin-function-name #'car)	; "car"

(defun function-name (fn)
  #+xyzzy
  (let ((x (princ-to-string fn)))
    (if (or (string-match "#<function: \\(.+\\)>" x)
            (and (string-not-equal "#<lexical-closure: (anonymous)>" x)
                 (string-match "#<lexical-closure: \\(.+\\)>" x)))
        (some #'(lambda (x) (and (fboundp x) x))
              (find-all-symbols (match-string 1)))))
  #+clisp nil
  #+gcl nil)
(function-name #'reduce)	; reduce
(function-name #'si:system-root) ; system:system-root
(function-name #'hyperspec:hyperspec) ; hyperspec:hyperspec

(defun closure-name (obj)
  (and (si:*closurep obj)
       (string-match "#<lexical-closure: \\(.+\\)>"
		     (princ-to-string obj))
       (match-string 1)))

;;; なんとなく引数リストを置き換えてみる
(setf (get 'apply 'si::builtin-function-argument) '(fn &rest args+))
(arglist 'apply)		; (fn &rest args+)
;; クロージャの中身を替えると変数束縛ができないのでだめよ
(setf (cadr (si:closure-body #'arglist)) '(fn-or-sym)) ; (fn-or-sym)
(arglist 'if)			; 変数が定義されていません: x

;;; arglistてすと 2008-10-01T03:51:37+09:00
;;; 関数オブジェクト (組み込み、普通の、ラムダ)
(arglist #'car)			; (list)
(arglist #'arglist)		; (x)
(arglist #'(lambda (n) (1+ n)))	; (n)
;;; シンボル (組み込み、普通の、マクロの)
(arglist 'car)			; (list)
(arglist 'arglist)		; (x)
(arglist 'when)			; (lisp::test &body lisp::body)
;;; コンスセル (ラムダリスト、マクロ)
(arglist '(lambda (n) (1+ n)))	; (n)
(arglist #'when)		; (lisp::test &body lisp::body)

(arglist 'tree-equal)		; (x y &key test test-not)

(defun upward-directory (pathname)
  "一階層上のディレクトリを返す."
  (let* ((dir (remove-trail-slash (namestring pathname)))
	 (end (position #\/ dir :from-end t)))
    (if end
	(values (subseq dir 0 (1+ end)) t)
      (values pathname nil))))

;; or adjoin revappend,nreconc
;; 動的スコープ使ってやっとできた...のか
;; マクロも考えどころ :mapae.l
(labels ((add-to-list (list-var element &optional append
				(compare-fn #'equal))
	   (declare (ignore append))
	   (pushnew element (symbol-value list-var) :test compare-fn)))
  (let ((lst '(a b c)))
    (declare (special lst))
    (add-to-list 'lst 'xyzzy)
    (list lst (symbol-value 'lst)) ; (#1=(xyzzy a b c) #1#) / ((XYZZY A B C) (XYZZY A B C))
    (add-to-list '*features* :xyzzy)
    *features*))		; 元の*features*と同じ / (:XYZZY ~)

;; mapae.l より
;; http://chez-sugi.net/xyzzy/mapae.l
(defmacro add-to-list (list-var element &optional append)
  (if append
      `(setq ,(eval list-var) (append ,(eval list-var) (list ,element)))
    `(setq ,(eval list-var) (append (list ,element) ,(eval list-var)))))

;; (symbol-value ,list) の方が良さそうな気がする。

;; (message "自動セーブ終わり") のおかげで前のメッセージが消されて正直邪魔
;; Emacsだと前のメッセージが残ってくれる...

;;; 空白文字: #\SPC #\TAB #\RET
(si:*fset 'whitep #'syntax-whitespace-p)

#|
kill-xyzzyの流れ
Buffer.cc:1255:Fkill_xyzzy ()
  Buffer.cc:1244:Buffer::kill_xyzzy (int query)
    Buffer.cc:1207:Buffer::query_kill_xyzzy ()
      kbd.h:173:kbd_queue::disablep () const
      (run-hook-with-args-until-success '*before-delete-buffer-hook* (selected-buffer))
      process.cc:1175:query_kill_subprocesses ()
        "サブプロセスが走っています。こいつらを死なして終了しますか?"
      (run-hook-with-args-while-success '*delete-buffer-hook* (selected-buffer))
      (#if 0 (count-modified-buffers))
      (run-hook-with-args-while-success '*query-kill-xyzzy-hook*)
      (yes-or-no-p "%d個のバッファが変更されています。セーブしないで終了しますか?")
  *kill-xyzzy-hook*

*delete-buffer-hook*を使うかわりに
|#

(defun kill-all-subprocess ()
  "バッファプロセスをすべて殺す."
  (every #'kill-process (process-list))) ; signal-process は多分ダメ

;;; メニューにバッファリスト
;;; バッファタブの表示されている順番
(remove-if-not #'(lambda (buffer)
		   (or (file-visited-p buffer)
		       (char/= (elt (buffer-name buffer) 0) #\SPC)))
	       (buffer-list :buffer-bar-order t))


;; (define-key *text-mode-map* #\C-w 'backward-kill-word) ; like `Bash'
(defun copy-line ()
  (interactive)
  (labels ((point-at-bol () (save-excursion (goto-bol) (point)))
	   (point-at-eol () (save-excursion (goto-eol) (point))))
    (copy-region-as-kill (point-at-bol) (point-at-eol))
    (when (and (interactive-p)
	     (null *executing-macro*))
      (message "Line copied"))))
(define-key esc-map #\k 'copy-line)

(defun setup-memo-buffer (&optional (buffer (selected-buffer)))
  (interactive)
  (if (file-visited-p buffer)
      (error "ファイル名を持つバッファは指定できません")
    (with-set-buffer
      (set-buffer buffer)
      (text-mode)
      (setq need-not-save t)
      (message "Setup buffer"))))
;; (add-hook '*create-buffer-hook* 'setup-memo-buffer)

;; (si:make-chunk 'string 300) とか使えないか?
;; [xyzzy:01442]
;; http://hie.s64.xrea.com/xyzzy/ml/msg01441.html
(defun command-substitution (command)
  "DOSのコマンドをキックして、結果を文字列として取り出す"
  (let ((buffer (create-new-buffer " *cmd*"))
	(outfile (make-temp-file-name)))
    (unwind-protect
	(save-excursion
	  (call-process command :output outfile :show :hide :wait t)
	  (set-buffer buffer)
	  (insert-file-contents outfile)
	  (goto-char (1- (point-max))) ; 末尾の改行を取り除く
	  (when (looking-for "\n")
	    (delete-char 1))
	  ;;(goto-char (point-min))
          ;;(replace-buffer "\n+" " " :regexp t) ; 一行にまとめる
	  (buffer-substring (point-min) (point-max)))
      (and buffer (delete-buffer buffer))
      (and outfile (delete-file outfile :if-does-not-exist :skip)))))

;; 2バイト文字があるので buffer-size の返す値とファイルサイズは一致しません。
(list (buffer-size)
      (point-max)
      (file-length "memo.l"))
;;=> (89006 89006 96875)

;;; buffer-read-only なバッファでもインデント先に飛びたい
;;; xyzzyとEmacsの挙動が違う件
(define-key esc-map #\m 'back-to-indentation) ; cmds.l

;; アセンブラすげえｗｗｗ
;; interactiveな関数は苦手みたいですが
;; -> commandpが足りないのでは？
(require "disassemble")

;;; ページ数
(save-excursion
  (goto-char (point-min))
  (do ((i 0 (1+ i)))
      ((not (scan-buffer page-delimiter :regexp t :no-dup t))
       (1+ i))))

(defun nonzerop (number) (null (zerop number)))

(defun comment-region (from to)
  "簡易コメントアウト"
  (interactive "*r")
  (labels ((single-comment-p ()
	     (and (boundp 'comment-start)
                  ;; (not (equal comment-start ""))
                  (or (syntax-end-comment-p #\LFD)
                      (syntax-end-c++-comment-p #\LFD)))))
    (let ((*quotation-prefix* (if (single-comment-p)
                                  comment-start
                                *quotation-prefix*)))
      (quote-region from to)
      '(save-restriction (narrow-to-region from to)
        (replace-regexp "^" comment-start))
      )))

;; google-quote
;; google の検索文字列をクオートしたい
(quote-string)

;; ##newLISP
(begin
 (import "user32" "MessageBoxA")
 (MessageBoxA 0 "This is the body" "Caption" 1))
(newlisp-eval "((lambda (x) x) 10)")

(let ((proc (buffer-process (find-buffer "*newLISP*"))))
  (labels ((sendln (str)
             (process-send-string proc (concat str *shell-ret*))))
    (sendln "[cmd]")
    (sendln "(symbols)")
    (sendln "[/cmd]")))
(defvar *newlisp-function-begin-regexp*
  "(\\(defun\\|define-macro\\|lambda\\|lambda-macro\\|fn\\)")
"0x[0-9a-fA-F]+"                ; newLISP hex keyword

(shell-execute "http://www.newlisp.org/downloads/newlisp_manual.html#linking" t)

(defun newlisp-create-exe (source &optional exename)
  (unless exename
    (setq exename (merge-pathnames (concat (pathname-name source) ".exe")
                                   (directory-namestring source))))
  (let* ((newlisp (get-short-path-name nl:*newlisp-exe*))
         (link (get-short-path-name (merge-pathnames "util/link.lsp"
                                                     (nl:newlisp-directory)))))
    (str-sexp (prin1-to-string `(link ,newlisp ,exename ,source)))
    (command-substitution (format nil "~A ~A -e ~S" newlisp link str-sexp))))
(newlisp-create-exe "C:/home/lxuser/newlisp/test/opengl-demo.lsp") ; "true"

;; REPLに文字列 ウィンドウが動いてほしいなあ
(let* ((newbuf (find-buffer "*newLISP*")))
  (process-send-string (buffer-process newbuf)
                       "\n[cmd]\n(dolist (s (symbols)) (println s))\n[/cmd]\n")
  (pop-to-buffer newbuf t)
  (sleep 1)                     ; 
  (goto-char (point-max))
  (other-window))

#|
HTML記述をLHTML(Lisp HTML)記述に変換します。
http://cl-www.msi.co.jp/solutions/knowledge/lisp-world/phtml/

<html>
  <head>
    <title>Lisp Web</title>
  </head>
  <body>
    <h1>Lisp Web Page</h1>
    <table>
      <tr><td>1</td><td>Lisp1.5</td></tr>
      <tr><td>2</td><td>Scheme</td></tr>
      <tr><td>3</td><td>Common Lisp</td></tr>
    </table>
  </body>
</html>

(html
 (head (title "Lisp Web"))
 (body (h1 "Lisp Web Page")
       (table (tr (td 1) (td "Lisp1.5"))
              (tr (td 2) (td "Scheme"))
              (tr (td 3) (td "Common Lisp")))))

|#

#|
$ man clisp
       -x expressions
           Executes a series of arbitrary expressions instead of a
           read-eval-print loop[2]. The values of the expressions will be
           output to *STANDARD-OUTPUT*[35]. Due to the argument processing
           done by the shell, the expressions must be enclosed in double
           quotes, and double quotes and backslashes must be escaped with
           backslashes.
|#
;; => " と \ だけ \ をつければ良さそう
;; でも $ clisp -q -x "#\a" => #\a

;; 引数付きでインタラクティブ関数呼び出し
;; できたらいいかもね

;; (man-lsic86 "printf") はできるが (man-lsic86 "sprintf") はできない
;;    printf, fprintf, sprintf - 書式つき出力変換
(defun man-lsic86 (str)
  (interactive "sMan (lsic86): ")
  (find-file "C:/home/xyzzy/man/LSIC86.MAN" nil t)
  (goto-char (point-min))
  (scan-buffer (format nil "【名前】~2%    ~A" str)))

;; C:/home/lxuser/lsic330c/MAN/LSIC86.MAN のタグファイルからジャンプしたい
;; [F10] first-error, [F11] next-error
;; 微調整必要？
(push (list (compile-regexp "^\\(.+\\)(\\(.+\\)):") 1 2)
      *error-regexp-list*)

;; うまくいかない
(let* ((buf (get-buffer-create " *lisp*"))
       (olio "C:/usr/local/clisp-2.47-full/bin/clisp.exe --silent")
       (proc (make-process olio :output buf)))
  (set-process-filter proc #'(lambda (prc str)
                               (message-box str)
                               (kill-process prc)))
  (set-process-sentinel proc #'(lambda (prc)
                                 (delete-buffer buf)))
  (process-send-string proc "(1- 10)\n")
  )

;; 暗号もどき
;; 逆は？
(equal (si:md5 (map-internal-to-utf-8 "開けごま"))
       "8a79eb41fe1787098dacb4ad1d8dbe94") ; t

(defun following-char () (char-after (point)))
(defun preceding-char () (char-before (point)))

;; コンパイルするとすげー早い
(compile (defun next-kanji ()
           "次の漢字(マルチバイト文字？)を探す."
           (interactive)
           (let ((opoint (point)))
             (if (kanji-char-p (following-char))
                 (forward-char))
             (do ()
                 ((eobp) (progn
                           (goto-char opoint)
                           (message "ねえっす")
                           nil))
               (when (kanji-char-p (following-char))
                 (return t))
               (forward-char)
               (do-events)))))

;; 何か処理をして nil/t を返す
(defmacro prognil (&body body) `(progn ,@body nil))
(defmacro progt (&body body) `(progn ,@body t))

(process-command proc)          ; 起動時のコマンド引数を取得

;; 自分自身のプロセスを取得する方法が分からない
(defun main-args ()
  (cons (process-command proc) si:*command-line-args*))

;; dialog.l とか参照
(activate-xyzzy-window (si:*instance-number))

(defun map-sparse-keymap (fn keymap)
  (labels ((keymap-walker (x)
             (cond ((keymapp (cdr x))
                    (mapcar #'keymap-walker (cddr x)))
                   (t
                    (funcall fn (car x) (cdr x))))))
    (mapcar #'keymap-walker (cdr keymap))))
(map-sparse-keymap #'(lambda (c s) (symbol-package s))
                   *shell-mode-map*)

(list (string-match "B+" "AAAABBBAAAA")
      (match-string 0)
      (match-data))
;; (4 "BBB" #(4 7 nil nil nil nil nil nil nil nil nil nil nil nil nil nil nil nil nil nil "AAAABBBAAAA"))

;; http://d.hatena.ne.jp/tanda/20081123/1227467469
;; Meta keyは最上位のビットを立てる効果がある。
(format nil "~16,'0B" (char-code #\g))   ; "0000000001100111"
(format nil "~16,'0B" (char-code #\M-g)) ; "1000000001100111"
(format nil "~16,'0B" (char-code #\C-g)) ; "0000000000000111"

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

;; md5 ハッシュ値
(with-open-file (s "~/xyzzy.exe" :encoding :binary)
  (si:md5 s))
;=> "383856b0757b0285240408b2800e1600"


;; 精度の違いなのか
(list (si:performance-counter)
      (get-internal-real-time)) ; (10388137848 2903890)

(setq backup-by-copying :remote)

(defvar load-path '("C:/home/emacs/22.1/lisp/"
                    "C:/home/emacs/22.1/site-lisp/"
                    "C:/home/emacs/22.1/leim/"
                    "C:/home/lxuser/lib/emacs/"
                    "C:/usr/local/clisp-2.47-full/lib/slime/")
  "Emacs load-path")
(completing-read "Elisp: "
                 (mapcan #'(lambda (dir)
                             (directory dir :recursive t :wild "*.el"))
                         load-path))

(handler-case (/ pi 0)
  (condition (c)
    (si:*structure-definition-name (si:*structure-definition c))))
; division-by-zero

(si:canonicalize-type '(mod 5)) ; (integer 0 4)

;; 二画面ファイラからdiff
;; http://www1.odn.ne.jp/ymtz/tips.html#diff

;; #'si:www-url-decodeを文字列からではなく、ストリームから逐次変換したい
;; もう少し一般的に...
;; シーケンスに適応する関数をストリームでも使いたい

;; プレイリストを作る
;; xyzzyのネットワークストリームの使い方が分からないので外部プログラムに依存
;; URLのエンコード/デコードの必要はない
;; $ curl --silent --output tmp.html http://www.openmusicarchive.org/audio/
(with-open-file (outfile "openmusicarchive.org.m3u"
                         :direction :output
                         :if-exists :overwrite
                         :if-does-not-exist :create)
  (with-open-file (infile "tmp.html" :direction :input)
    (do ((line #1=(read-line infile nil) #1#))
        ((null line))
      (if (string-match "<a href=\"\\(.+\\.\\(mp3\\|ogg\||wav\\)\\)\">"  line)
          (format outfile "~A~%" (concat "http://www.openmusicarchive.org/audio/"
                                         (match-string 1)))))))

;; with-open-stream + connect は単一スレッド (ストリーム)
;; open-network-stream は複数スレッド (プロセス)
;; ...であってる？

;; 同期
(with-open-stream (stream (connect "www.asahi-net.or.jp" 80))
  (princ "GET /~pw9s-szk/ HTTP/1.0\n\n" stream)
  (do ((line #1=(read-line stream nil nil) #1#))
      ((equal line ""))         ; ""ならヘッダのみ、nilなら全部
    (insert line #\LFD)))

;; 非同期
(let ((proc (open-network-stream nil "www.openmusicarchive.org" 80)))
  (set-process-filter proc #'(lambda (proc str)
                               (insert str #\LFD)))
  (process-send-string proc "GET /audio/ HTTP/1.0\n\n"))

;; URLの文字化け対策
(list #1=(si:www-url-encode (map-internal-to-utf-8 "二十三号の見た世界.mp3"))
      (map-utf-8-to-internal (si:www-url-decode #1#)))
("%E4%BA%8C%E5%8D%81%E4%B8%89%E5%8F%B7%E3%81%AE%E8%A6%8B%E3%81%9F%E4%B8%96%E7%95%8C.mp3"
 "二十三号の見た世界.mp3")
(map-utf-8-to-internal "\xe5\x88\x9d\xe9\x9fｳ\xe3\x83\x9f\xe3\x82ｯ")
"初音ミク"

(mapcar #'(lambda (ch)
            (format nil "~B" (char-unicode ch)))
        (map 'list #'identity (map-internal-to-utf-8 "≠")))
("111101011010101" "1111100011110000")

(defun what-date (&optional (universal-time (get-universal-time)))
  (format-date-string "%Y-%m-%dT%H:%M:%S%#Z" universal-time))

(defun find-autoload-file (def)
  "指定された関数DEFがautoloadされているならば、そのモジュール名を返す."
  (when (symbolp def)
    (setq def (symbol-function def)))
  (when (si:*closurep def)
    (setq def (si:closure-body def)))
  (when (cond ((eq (safe-car def) 'lambda)
	       (setq def (safe-cddr def))
	       (when (eq (safe-caar def) 'ed::interactive)
		 (setq def (cdr def)))
	       def)
	      ((eq (safe-car def) 'macro)
	       (setq def (safe-cddr def)))
	      (t nil))
    (setq def (safe-car def))
    (and (eq (safe-car def) 'block)
	 (let ((fn (safe-caar (safe-cddr def))))
	   (or (eq fn 'lisp::load-and-go)
	       (eq fn 'lisp::mc-load-and-go)))
         (safe-caddr (safe-caddr def)))))

(defun autoload-modules ()
  "autoloadされたモジュールのリストを表示する."
  (let ((files nil))
    (do-all-symbols (sym)
      (and (fboundp sym)
           (autoload-function-p sym)
           (pushnew (find-autoload-file sym) files :test #'equal)))
    (nreverse files)))
(compile 'autoload-modules)

#|
Example:
(find-autoload-file 'java-mode) => "java"
(find-autoload-file 'shell)     => nil (読み込み済)
(autoload-modules)
=> ("dialogs" "cfns" "javafns" "lispfns" "basic-mode" "perl" "dexplorer"
    "hh-call" "niftylog" "gresreg" "pascal" "idl-mode" "life" "calendar"
    "c#-mode" "ccurve" "listfn" "gresregd" "hanoi" "LaTeX" "viewmode"
    "tail-f" "gomoku" "calc" "maketags" "comparew" "sql-mode" "css-mode"
    "verup" "java" "htmlmode" "hideif" "re-builder" "aitan" "comment" "hexl"
    "struct")
|#

(mapcar #'(lambda (fn) (funcall fn #\春))
        (list #'iso-char-code 
              #'char-code
              #'char-unicode))  ; (15701 36724 26149)

;; http://ironsand.net/2channel/1143621919.html#702
;; 超絶列カーソル。2バイト文字を使う奴はすべからく死ぬべきだ。
(setq fsadf-highlight-args '(:background 1 :foreground 0))
(defun fsadf-highlight ()
  (interactive)
  (fsadf-delete-hightlight)
  (save-excursion
    (let ((column (current-virtual-column)))
      (goto-virtual-line (get-window-start-line))
      (dotimes (i (1+ (window-lines)))
        (when (or (= column (goto-virtual-column column))
                  (= (1+ column) (goto-virtual-column (1+ column))))
          (unless (eq (following-char) #\TAB)
            (apply #'set-text-attribute
                   (point)
                   (1+ (point))
                   :fsadf
                   fsadf-highlight-args)))
        (unless (next-virtual-line)
          (return)))
      )))
(defun fsadf-delete-hightlight ()
  (delete-text-attributes :fsadf))
(add-hook '*post-command-hook* 'fsadf-highlight)
;; (delete-hook '*post-command-hook* 'fsadf-highlight)

;; [color-line.l]秀○のようなカーソル行の色付け[ver.1.2]
;; http://web.archive.org/web/20040408232830/http://www.haide.net/~tsukushi/xyzzy/#color-line

;; hl-line
;; xyzzyの使い方が分からぬやし 励ましあえ その6 >>571
;; http://www.bookshelf.jp/2ch/software/1103791938.html#571
(defun line-cursor-background ()
  "やたー行カーソルもどき できたよー！
このコードだとほかの色付けが消えてしまう場合があるけど、
そういう細かいことはとりあえず気にしないということで。 "
  (interactive)
  (delete-text-attributes 'line-background-color)
  (save-excursion
    (set-text-attribute (progn (goto-virtual-bol) (point))
			(progn (next-virtual-line) (point))
			'line-background-color
			:background 10
			:extend t)))
(funcall (defun turn-on-line-cursor ()
           (add-hook '*post-command-hook* 'line-cursor-background)))
(funcall (defun turn-off-line-cursor ()
           (delete-hook '*post-command-hook* 'line-cursor-background)
           (delete-text-attributes 'line-background-color)))

;; Yamamoto Shinjiさん移植のHexl
;; ずいぶん古いコードなのでバグがあるみたい
;; 参考コード↓
;; http://iep.water.ca.gov/d/bin/sbin/site/lib/xemacs-19.15/lisp/packages/hexl.el
;; http://www.nd.edu/~hpcc/solaris_opt/SUNWspro/contrib/contrib6/XEmacs20.4/lib/xemacs-20.4/lisp/packages/hexl.el
(setq hexl-exec-directory "C:/home/xyzzy/etc/")
(load-file "C:/tmp/hexl/hexl.lc")

(find-load-path)
(defun get-load-path (filename)
  (some #'(lambda (dirname)
            (or (probe-file (merge-pathnames (concat filename ".lc") dirname))
                (probe-file (merge-pathnames (concat filename ".l") dirname))
                (probe-file (merge-pathnames filename dirname))))
        *load-path*))

;; 引数必要なはずなのに
(arglist 'buffer-process)       ; (buffer)
(buffer-process)                ; nil

;; Hexl-modeにて、元のファイルの改行コードがCR(Mac風)だと
;; (hexl-mode-exit)の後の表示がおかしくなる(EOFまで届かない)

(load-library "niconico")
(hiroba-position)
"119.110.94.207:2527"
"119.110.94.207:2532"
"125.63.42.11:2531"
"125.63.42.10:2525"             ; 住人によると１番広場らしい(2009-07-19)
;;=> (("119.110.94.203" "2528") . 44)

;;; dbind.l途中放棄
(load-library "dbind")
(macroexpand '(destructuring-bind (x (y1 &optional y2) z) '(1 (2) 3)
	       (list x y1 y2 z)))
(destructuring-bind (x (y1 &optional y2) z) '(1 (2) 3)
  (list x y1 y2 z))             ;=> (1 2 nil 3)

(with-temp-buffer
  (insert "いろはにほへと")
  (buffer-string))              ; "いろはにほへと"

(current-kbd-layout)            ; (-534772719 . "Microsoft IME Standard 2003")

*pop-up-windows*                ; t

(progv '(*x*) '(2) *x*)
(in-package :lisp)

(defun fit-window ()
  (when (and (/= (count-windows) 1)
             (pos-visible-in-window-p (point-max)))
    (enlarge-window (1+ (- (buffer-lines)
                           (window-height)
                           (get-window-start-line))))))

;; @@window
(list (screen-height)                ; ウィンドウ全体の高さ
      (buffer-lines)                 ; バッファの物理行数 (バッファ末尾の行番号)
      (window-lines)                 ; ウィンドウの表示可能行数 (window-height)
      (current-line-number)          ; 現在の物理行の行番号
      (get-window-start-line)        ; ウィンドウの先頭行
      )                              ; (26 2597 22 2545 2533)

;; (左x 左y 右x 右y)
(window-coordinate (minibuffer-window)) ; (0 440 760 462)

(defun goto-window-bol ()
  (goto-line (get-window-start-line))
  (goto-bol))

(defun get-window-line ()
  "ウィンドウの先頭行からの相対的な行番号"
  (- (current-line-number) (get-window-start-line)))

(defun buffer-lines ()
  (save-excursion
    (goto-char (point-max))
    (current-line-number)))

(setf (get 'set-dispatch-macro-character 'ed:lisp-indent-hook) 2)

(prettyexpand '(do ((acc nil)
                    (n 0 (1+ n)))
                   ((> n 10) (nreverse acc))
                 (push n acc)))
(block nil (let ((acc nil)
                 (n 0))
             (lisp::*loop (if (> n 10)
                              (return (progn (nreverse acc))))
                          (tagbody (push n acc))
                          (psetq n (1+ n)))))
t

;;; インデントどのくらい？
(let ((acc nil))
  (do-all-symbols (v)
    (if (integerp #1=(get v 'ed:lisp-indent-hook))
        (pushnew (cons v #1#) acc)))
  (nreverse acc))
((editor::*loop . 0) (editor::protect-match-data . 0) (with-input-from-buffer . 1) (long-operation . 0) (with-input-from-selected-buffer . 0) (interactive . 1) (selection-start-end . 1) (save-restriction . 0) (with-output-to-temp-buffer . 1) (with-output-to-buffer . 1) (ole-for-each . 1) (with-output-to-selected-buffer . 0) (with-interval-message . 1) (save-excursion . 0) (save-window-excursion . 0) (with-set-buffer . 0) (with-selected-window . 0) (trap-errors . 0) (with-set-directory . 1) (xmlpm-interval-message . 1) (with-temp-file . 1) (for . 1) (until . 1) (with-syntax-table . 1) (lisp::with-sequence-start-end . 3) (macrolet . 1) (prog1 . 1) (prog2 . 2) (loop . 0) (with-hash-table-iterator . 1) (handler-bind . 1) (do-all-symbols . 1) (handler-case . 1) (dotimes . 1) (do . 2) (return-from . 1) (progn . 0) (with-package-iterator . 1) (progv . 2) (when . 1) (dolist . 1) (let* . 1) (defpackage . 1) (labels . 1) (if . 3) (with-open-stream . 1) (with-open-file . 1) (with-input-from-string . 1) (unless . 1) (multiple-value-call . 1) (unwind-protect . 1) (multiple-value-setq . 1) (destructuring-bind . 2) (catch . 1) (do-external-symbols . 1) (tagbody . 0) (defsetf . 3) (eval-when . 1) (let . 1) (multiple-value-bind . 2) (with-output-to-string . 1) (prog . 1) (block . 1) (do* . 2) (define-setf-method . 2) (case . 1) (flet . 1) (while . 1) (prog* . 1) (do-symbols . 1) (with-xhr-post-async . 1) (with-xhr-request-async . 1) (with-xhr-get-async . 1) (with-xhr-head-async . 1))

;;; xyzzyにないCL関数群を探す
(let ((acc nil))
  (mapc #'(lambda (s)
            (unless (find-symbol #1=(car s) :lisp)
              (push #1# acc)))
        hyperspec::*hyperspec-symbols*)
  (nreverse acc))

;; EmacsのバッファとCommonLispのストリームをくっつけたのが
;; make-buffer-streamなんじゃないかと思うんだ

;;; OnLisp ユーティリティ
(require 'onlisp)

;; (popup-string) で表示されたポップアップがすぐに消えてしまうのは
;; ポップアップが表示されるであろう位置にマウスポインタがあるから。
;; (ML [xyzzy:06433] KAMEI Tetsuya)

(defun check-buffer-process-status (&optional (buffer (selected-buffer))
                                              (status :run))
  (let ((proc (buffer-process buffer)))
    (and proc
         (eq (process-status proc) status))))

(defconstant *MyDocuments*
  (read-registry "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders"
                 "Personal" :current-user)
  "マイドキュメント")

;; ショートパスだとバッファを認識してくれない
(get-file-buffer
 (get-short-path-name "C:/Program Files/newlisp/util/link.lsp")) ; nil

;; lispパッケージの中じゃないんだ
(symbol-package 'char-name)     ; #<package: editor>
(fboundp 'lisp::char-name)      ; nil
(fboundp 'editor::char-name)    ; t

(defun in-comment-p ()
  "カーソル位置がコメントの内部か"
  (eq (parse-point-syntax (point)) :comment))

(defun auto-fill-comment-only ()
  "コメント中のみauto-fill"
  (auto-fill-mode (in-comment-p)))
(defun toggle-auto-fill-comment-only ()
  (interactive)
  (if (find 'auto-fill-comment-only *post-command-hook*)
      (delete-hook '*post-command-hook* 'auto-fill-comment-only)
    (add-hook '*post-command-hook* 'auto-fill-comment-only)))

(defun region-beginning () (min (point) (mark)))
(defun region-end () (max (point) (mark)))

;;; encap.l (encap+.l も試してみたい)
(require "encap")

;; inf-lisp
(require "inferior-lisp-mode")
(add-hook 'ed::*inferior-lisp-mode-hook* 'ed::use-lisp-keyword)
(define-key ed::*inferior-lisp-mode-map* #\C-. 'lisp-complete-symbol)
(define-key ed::*inferior-lisp-mode-map* '(#\C-x #\C-e) 'eval-last-sexp)
(define-key ed::*inferior-lisp-mode-map* '(#\C-c #\C-x) 'send-last-sexp-to-subprocess)
(defun lisp-send-q ()
  (interactive)
  (ed::send-to-lisp-subprocess ":q"))
(define-key ed::*inferior-lisp-mode-map* '(#\C-c #\q) 'lisp-send-q)
(defun lisp-eval-region (from to)
  (interactive "r")
  (ed::send-to-lisp-subprocess (buffer-substring from to)))

;; emacs-write-file, rename はこんな動作をしてほしいな
(defun rename-and-revert-file (new-name)
  (interactive "Frename: ")
  (unless (file-visited-p)
    (error "ファイル名がありません。"))
  (let ((home (point)))
    (rename-file (get-buffer-file-name) new-name
                 :if-exists :error
                 :if-access-denied :error)
    (delete-buffer (selected-buffer))
    (find-file new-name)
    (goto-char home)))

(defun visible-buffer-list ()
  (remove-if #'(lambda(buffer)
                 (find (aref (buffer-name buffer) 0) " *"))
             (buffer-list)))

(defun keyword-match-p (str)
  (and (boundp 'keyword-hash-table)
       (gethash str keyword-hash-table)))

;; make-package は重複するとエラーになる
;; defpackage はエラーにならない (defvarみたいなものか)

(defmacro with-find-file (file &body body)
  `(let ((#1=#:file-buffer (get-file-buffer ,file)))
     (unwind-protect
         (progn (find-file ,file *encoding-auto* t) ,@body)
       (unless #1# (delete-buffer #1#)))))
(setf (get 'with-find-file 'ed:lisp-indent-hook) 1)
(with-find-file "C:/home/xyzzy/scratch.l"
  (msgbox "~A" (buffer-substring (point-min) (point-max))))

;; C-x n p
;; (narrow-to-page)

;;; newlisp
(defun string-trim-html-tag (string)
  (nth-value 0 (substitute-string string
                                  "<[^>]*>" ; "<.+?>"
                                  "")))
(string-trim-html-tag "<b>syntax: (cond (<em>exp-condition-1</em> <em>body-1</em>) [(<em>exp-condition-2</em> <em>body-2</em>) ... ]</b>")
"syntax: (cond (exp-condition-1 body-1) [(exp-condition-2 body-2) ... ]"
"syntax: (cond (exp-condition-1 body-1) [(exp-condition-2 body-2) ... ]"

;; base64エンコードでファイルを文字列として扱う
;; これは単なるファイルのコピー
(with-open-file (out "hoge.wav" :direction :output)
  (with-open-file (file "C:/home/lxuser/newlisp/plop.wav" :direction :input)
    (si:base64-decode (si:base64-encode file) out)))

;; http://miyamuko.s56.xrea.com/xyzzy/xml-http-request.html
(require "xml-http-request")
(use-package :xml-http-request)

(require "imagehdr")
(multiple-value-list
 (read-png-header "C:/home/lxuser/newlisp/worm16.png")) ; (16 16 :png)

;; OLE依存だけどMS-WORDのファイルをテキストにして開ける
;; http://xyzzy.s53.xrea.com/wiki/index.php?tips%2FWord%20%A5%D5%A5%A1%A5%A4%A5%EB%A4%F2%B3%AB%A4%B1%A4%EB%A4%E8%A4%A6%A4%CB%A4%B9%A4%EB

;; 最小化すると元のサイズに戻せない
;; http://homepage2.nifty.com/winfaq/c/trouble.html#156
;; C:/home/xyzzy/usr/xyzzy.ini 表示がおかしくなったら見てみよう
;; アプリケーションを起動しても表示されません。最大化すると表示されます
;; http://homepage2.nifty.com/winfaq/c/trouble.html#156

;; /tipsキーボードマクロを便利に
;; http://xyzzy.s53.xrea.com/wiki/index.php?tips%2F%A5%AD%A1%BC%A5%DC%A1%BC%A5%C9%A5%DE%A5%AF%A5%ED%A4%F2%CA%D8%CD%F8%A4%CB

;; エンコードが混じるとめんどそう
(defun url-namestring (pathname &optional encode)
  (concat "file:///" pathname))

;; シンボル変数しか参照しない関数にはprogvが役に立つ
'(symbol-value run-hooks)
(progv '(*hoge*) (list (list (lambda ()
                               (format t "nilを返すよ~%") nil)
                             (lambda ()
                               (format t "tを返すよ~%") t)))
  (format t "~%*** with-args~%")
  (run-hooks '*hoge*)
  (format t "~%*** with-args-while-success~%")
  (run-hook-with-args-while-success '*hoge*)
  (format t "~%*** with-args-until-success~%")
  (run-hook-with-args-until-success '*hoge*))

*** with-args
nilを返すよ
tを返すよ

*** with-args-while-success
nilを返すよ

*** with-args-until-success
nilを返すよ
tを返すよ
=> t

(progv '(*hook*) `((,(lambda () t)))
  (run-hook-with-args-while-success '*hook*)) ; t
(progv '(*hook*) `((,(lambda () nil)))
  (run-hook-with-args-while-success '*hook*)) ; nil

;; とりあえず残しておく 2009-03-13T23:10:21+09:00
(defun xyzzy-macroexpand-1 (&optional repeatedly)
  (interactive "P")
  (let* ((*print-circle* t)
         (from (save-excursion
                 (unless (syntax-open-p (following-char))
                   (up-list -1 t))
                 (point)))
         (to (save-excursion
               (goto-char from)
               (forward-sexp)
               (point)))
         (expand-sexp (funcall (if repeatedly
                                   #'macroexpand
                                   #'macroexpand-1)
                               (read-from-string (buffer-substring from to) nil))))
    (with-output-to-temp-buffer (" *XYZZY macroexpansion*")
      (format t "~S" expand-sexp)
      (progn
        (lisp-interaction-mode)
        (indent-line-sexp)
        (goto-char (point-max))
        ;; (toggle-read-only t)
        ))))

;;; 文字エンコーディングの判定
;;; あれ？
(detect-char-encoding "こばやし") ; #.(make-sjis-encoding "sjis" "日本語(Shift_JIS)")
(detect-char-encoding (sjis->utf8 "こばやし")) ; #.(make-sjis-encoding "sjis" "日本語(Shift_JIS)")

;;; バイナリストリームてめんどくさい
;;; xyzzyは文字列の中身も正規化されるらしい ("\343" -> "\xe3")
;;; Emacsだとnil
(equal "\343\201\223\343\201\260\343\202\204\343\201\227"
       "\xe3\x81\x93\xe3\x81ｰ\xe3\x82\x84\xe3\x81\x97") ; t
;; wip/ftp
(arglist 'set-stream-encoding)  ; (stream encoding)
;; 文字列に使えないのかしら
(with-input-from-string (input "こばやし")
  (set-stream-encoding input :binary)
  (read-char input))            ; #\こ

(merge-pathnames "Local Settings/Temp"(si:getenv "USERPROFILE"))

;; 始まり
(format-date-string "%a %b %d %H:%M:%S %Y" 0) ; "Mon Jan 01 09:00:00 1900"

;; *.lsp もタグジャンプのお仲間に
(pushnew "*.lsp" (cdr (assoc 'ed::lisp-maketags *maketags-list*)) :test #'equal)

;;; 使い方: (range 3 12) => (3 4 5 6 7 8 9 10 11 12)
;; (defun range (from to &optional (step 1))
;;   (mapa-b #'identity from to step))
(defun range (from to &optional (step 1))
  "make list `(from ... to)'"
  (do ((i from (+ i step))
       (acc '()))
      ((> i to) (nreverse acc))
    (push i acc)))

;; http://homepage3.nifty.com/~ko-ji/junk.html#time
(defmacro time (&rest body)
  "処理時間を計る"
  (let ((begin (gensym)))
    `(let ((,begin (get-internal-real-time)))
       ,@body
       (/ (- (get-internal-real-time) ,begin) 1000.0))))

;;; 適当だよ！
(defun url-encode (url)
  (with-output-to-string (out)
    (map nil (lambda (c)
               (funcall #'princ
                        (cond ((char= c #\space) "+")
                              ((or (alphanumericp c)
                                   (find c "-._~")
                                   (find c ":/?#[]@")
                                   (find c "!$&'()*+,;="))
                               (string c))
                              (t
                               (string-upcase (format nil "%~02X" (char-code c)))))
                        out))
         (convert-encoding-to-internal *encoding-binary* url))))

(si:www-url-encode "亀井さん")  ; "%8BT%88%E4%82%B3%82%F1"
(url-encode "亀井さん")         ; "%8BT%88%E4%82%B3%82%F1"

(url-encode "http://www.example.com/?param=foo")
;; "http://www.example.com/?param%3Dfoo"

;;; ディレクトリのリストからサブディレクトリを取り除いてみたい
;;; 組み合わせ問題みたいなアルゴリズム？
(setq load-path '("c:/usr/local/clisp-2.47-full/lib/slime/contrib" "c:/usr/local/clisp-2.47-full/lib/slime/" "c:/home/lxuser/lib/emacs" "c:/home/emacs/22.1/site-lisp" "c:/home/emacs/22.1/site-lisp/fixed-width-fontset" "c:/home/emacs/22.1/site-lisp/miscs" "c:/home/emacs/22.1/site-lisp/fixed-width-fontset/doc" "C:/home/emacs/22.1/../site-lisp" "C:/home/emacs/22.1/lisp" "c:/home/emacs/22.1/lisp/url" "c:/home/emacs/22.1/lisp/textmodes" "c:/home/emacs/22.1/lisp/progmodes" "c:/home/emacs/22.1/lisp/play" "c:/home/emacs/22.1/lisp/obsolete" "c:/home/emacs/22.1/lisp/net" "c:/home/emacs/22.1/lisp/mh-e" "c:/home/emacs/22.1/lisp/mail" "c:/home/emacs/22.1/lisp/language" "c:/home/emacs/22.1/lisp/international" "c:/home/emacs/22.1/lisp/gnus" "c:/home/emacs/22.1/lisp/eshell" "c:/home/emacs/22.1/lisp/erc" "c:/home/emacs/22.1/lisp/emulation" "c:/home/emacs/22.1/lisp/emacs-lisp" "c:/home/emacs/22.1/lisp/calendar" "c:/home/emacs/22.1/lisp/calc" "C:/home/emacs/22.1/leim"))

;;; grep
パターン
ファイル名
ディレクトリ
---
大文字小文字を区別する
単語単位で検索する
正規表現
エスケープシーケンスを理解しろ
ついでにサブディレクトリも
非同期でgrep
ファイル名だけ出力

;; grepのオプション
;;; $ grep -nH -e xyzzy ~/../xyzzy/lisp/*.l
*** Matcher Selection
-E, --extended-regexp	正規表現検索 (-E is specified by POSIX)
-F, --fixed-strings
-i, --ignore-case	大文字小文字を区別しない
-v, --invert-match	マッチしない行を検索
*** General Output Control
-c, --count	マッチした総行数の表示
-l, --files-with-matches	指定したパターンを含むファイル名だけを表示
*** Output Line Prefix Control
-n, --line-number	行番号を表示

;; 正規表現を使うのがgrep、使わないのがfgrep

(format nil "~19,,' ,8:B" (char-code #\こ))     ; "  10000010 10110001"
(format nil "~19,,' ,8:B" (iso-char-code #\こ)) ; "    100100 00110011"

;; C++ 流儀に従ってコーディングするとこうなるよ、の例
(defun mydump (pstr)
  (format t "~A~%" pstr)
  (setq pstr (binary-string pstr)) ; 2バイト文字を1バイトごとに分割しておく
  (do ((n 1 (1+ n))
       (pstr pstr (substring pstr 1)))
      ((string= pstr ""))
    (do ((str "" (if (zerop (logand (char-code (elt pstr 0))
                                         b))
                     (concat str "0")
                     (concat str "1")))
         (b 128 (ash b -1)))    ; 右に1ビットシフト (b = b >> 1;)
        ((zerop b)
         (if (not (zerop (mod n 6)))
             (format t "~A " str)
             (format t "~A~%" str))))))
(mydump "これは漢字文字列")

(map 'list (lambda (c)
             (format nil "~B" (char-code c)))
     (binary-string "これは漢字文字列"))
("10000010" "10110001" "10000010" "11101010" "10000010" "11001101"
 "10001010" "10111111" "10001110" "10011010" "10010101" "10110110"
 "10001110" "10011010" "10010111" "11110001")

;; Windows で勝手にコピーしたファイルを消す
;; ディレクトリは空でないとエラーになるのでパス
;; (ed::filer-do-delete FILES) を参考にしたいが...
;; C:\home\xyzzy\site-lisp>rmdir dirname
;; ディレクトリが空ではありません (/S でディレクトリツリー強制削除)
(defun delete-copy-files (dir)
  (directory dir
             :absolute t :recursive t
             :file-only t
             :wild "コピー ? *"
             :callback #'delete-file))

(defun garbage-collect (&optional no-message)
  (interactive)
  (gc no-message))

;; filer-shell-execute があればいいか
(defun execute-file (file)
  "関連付けられたプログラムで開く"
  (interactive "fExecute file: " :default0 (get-buffer-file-name))
  (shell-execute file))

(defun kill-no-process-buffer (&optional (arg 1))
  "プロセスの停止したバッファを kill-buffer します。"
  (interactive "p")
  (let ((proc (buffer-process (selected-buffer))))
    (if (or (not proc)                        ; (1) プロセスがない
	    (eq (process-status proc) :exit)) ; (2) プロセスが停止している
	(kill-selected-buffer)
      ;; プロセスがある場合
      (self-insert-command arg))))
(define-key ed::*command-output-mode-map* #\q 'kill-no-process-buffer)

;; C-x C-k F           change-default-fileio-encoding
;; C-x C-k N           change-default-eol-code
;; C-x C-k c           change-clipboard-encoding
;; C-x C-k f           change-fileio-encoding
;; C-x C-k n           change-eol-code
;; "C:/home/xyzzy/site-lisp/memo.l"の文字判定が外れるのは何故？
;; (setq *default-fileio-encoding* *encoding-euc-jp*)
;; (setq *default-fileio-encoding* *encoding-utf8n*)
;; (setq *default-fileio-encoding* *encoding-sjis*)

(define-key spec-map #\w
            (defun highlight-current-word ()
              (interactive)
              (current-word t)))

;; 戻り値がS式でないのが微妙に気持ち悪い
(defun prettyexpand (form &optional env)
  (let ((exp (macroexpand-1 form env))
        (*print-circle* t))
    (save-excursion
      (format t "~S" exp))
    (indent-line-sexp)))

;; コンパイルしないと遅いので注意
;; 需要はなさそうだが、
;; *buffer-package* のシンボルのみ色付けにするとか
;; パッケージ::シンボル名 にも対応するとか
;; キーワードファイルの書き方は以下参照
;; http://xyzzy.s53.xrea.com/reference/wiki.cgi?p=%A5%AD%A1%BC%A5%EF%A1%BC%A5%C9%A5%D5%A5%A1%A5%A4%A5%EB%A4%CE%BD%F1%A4%AD%CA%FD
(defun reload-keyword-file+ ()
  "LISP限定追加の色付け."
  (interactive "p")
  (unless (and (member buffer-mode '(lisp-mode lisp-interaction-mode))
               (boundp 'keyword-hash-table)
               keyword-hash-table)
    (return-from reload-keyword-file+))
  (let (fsyms vsyms)
    (do-all-symbols (sym)
      (cond ((and (fboundp sym)
                  (null (gethash (symbol-name sym) ed::*lisp-keyword-hash-table*)))
             (push sym fsyms))
            ((and (boundp sym)
                  (null (gethash (symbol-name sym) ed::*lisp-keyword-hash-table*))
                  (null (keywordp sym))
                  (null (member sym lambda-list-keywords)))
             (push sym vsyms))))
    (copy-file (merge-pathnames "lisp" (etc-path))
               #1=(merge-pathnames "lisp++" (etc-path))
               :if-exists :overwrite)
    (with-open-file (stream #1# :direction :output :if-exists :append)
      ;; Function
      (format stream ";**b0~%")
      (format stream "~{~A~%~}" fsyms)
      ;; Variable
      (format stream ";**50~%")
      (format stream "~{~A~%~}" vsyms))
    (setq keyword-hash-table (load-keyword-file "lisp++"))
    (refresh-screen t)))

(or (compiled-function-p #'reload-keyword-file+)
    (compile 'reload-keyword-file+))

;; カーソル行を表示ウィンドウの最下にする
;; shell-ret の後に使えないかな
(recenter (window-lines))
(recenter -1)

;;; regexp-opt@emacs
(load-library "regexp-opt")

;;; 同じになった
(regexp-opt '("aa" "ab" "ba" "bb")) ; "a[ab]\\|b[ab]"
(regexp-opt '("defun" "lambda")) ; "defun\\|lambda"
(regexp-opt '("defun" "defsubst" "defmacro" "defalias" "defvar" "defconst") t)
;; "\\(def\\(?:alias\\|const\\|macro\\|subst\\|un\\|var\\)\\)"

;;; 違った
(regexp-opt '("cond" "if" "when" "unless" "while"
              "let" "let*" "progn" "prog1" "prog2"
              "save-restriction" "save-excursion" "save-window-excursion"
              "save-current-buffer" "save-match-data"
              "catch" "throw" "unwind-protect" "condition-case")
            t)
#+xyzzy   "\\(c\\(?:ond\\(?:ition-case\\)?\\|atch\\)\\|if\\|let\\(?:\\*\\|\\)\\|prog[12n]\\|save-\\(?:window-excursion\\|restriction\\|match-data\\|excursion\\|current-buffer\\)\\|throw\\|un\\(?:wind-protect\\|less\\)\\|wh\\(?:en\\|ile\\)\\)"
#+emacs   "\\(c\\(?:atch\\|ond\\(?:ition-case\\)?\\)\\|if\\|let\\*?\\|prog[12n]\\|save-\\(?:current-buffer\\|excursion\\|match-data\\|\\(?:restrict\\|window-excurs\\)ion\\)\\|throw\\|un\\(?:less\\|wind-protect\\)\\|wh\\(?:en\\|ile\\)\\)"
#+example "(\\(c\\(atch\\|ond\\(ition-case\\)?\\)\\|if\\|let\\*?\\|prog[12n]\\|save-\\(current-buffer\\|excursion\\|match-data\\|restriction\\|window-excursion\\)\\|throw\\|un\\(less\\|wind-protect\\)\\|wh\\(en\\|ile\\)\\)\\>"

(regexp-opt '("define" "lambda" "fn" "define-macro" "lambda-macro") 'words)
"\\<\\(define\\(?:-macro\\|\\)\\|fn\\|lambda\\(?:-macro\\)?\\)\\>" ; xyzzy
"\\<\\(define\\(?:-macro\\)?\\|fn\\|lambda\\(?:-macro\\)?\\)\\>"   ; emacs

;; (time (regexp-opt (hash->list keyword-hash-table)))
;; Real time: 13.593 sec.

;; mule.el 簡易版
;; バッファの変更フラグもセットする
(defun set-buffer-file-coding-system (encoding &optional nomodify)
  "Set the file coding-system of the current buffer to CODING-SYSTEM."
  (interactive "ZEncoding: \nP")
  (set-buffer-fileio-encoding encoding)
  (unless nomodify
    (set-buffer-modified-p t)))

;;; 対応する括弧に飛ぶ (paren.lのお供に)
(defun goto-matched-parenthesis-myself ()
  "Go to the matching parenthesis."
  (interactive)
  (let ((opoint (point)))
    (cond ((and (syntax-close-p (preceding-char))
		(backward-char)
		(goto-matched-parenthesis)))
	  ((and (syntax-open-p (following-char))
		(goto-matched-parenthesis)
		(forward-char)))
	  (t
	   (goto-char opoint)
	   (message "missing paren?")))))
(global-set-key #\C-] 'goto-matched-parenthesis-myself)

;; xyzzyのバグかもしれない
(defvar *x* 'special)
(let* ((*x* 'var) (y *x*)) (list *x* y)) ; (var special)

(defun get-file-infomation (file)
  "ファイルのプロパティを表示します。"
  (interactive "fFile info: " :default0 (get-buffer-file-name))
  (multiple-value-bind (attr write-time size short-path)
      (values-list (get-file-info file))
    (message "~{~A~^ ~}"	; ls -l の書式どんなだっけ?
             (list
              (file-attribute-to-string attr)            ; 属性
              size                                       ; サイズ
              (format-date-string "%Y-%m-%d" write-time) ; 更新日時
              (file-namestring file)                     ; ファイル名
              ))))

(defun file-attribute-to-string (attr)
  "attrib /? 参照"
  (concat
   (if (zerop (logand attr ed::*file-attribute-directory*))  "-" "D") ; ディレクトリ
   (if (zerop (logand attr ed::*file-attribute-readonly*))   "-" "R") ; 読み取り専用
   (if (zerop (logand attr ed::*file-attribute-archive*))    "-" "A") ; アーカイブ
   (if (zerop (logand attr ed::*file-attribute-hidden*))     "-" "H") ; 隠しファイル
   (if (zerop (logand attr ed::*file-attribute-system*))     "-" "S") ; システム
   (if (zerop (logand attr ed::*file-attribute-compressed*)) "-" "C") ; 圧縮?
   ))


;; あんまりテストしてないのでバグっている可能性あり
;; * コンパイルの際に内部関数名が残ってしまう
;; * 本来なら、変数の個数と値の個数が異なってもエラーにならない
#-xyzzy
(defmacro progv (symbols values &body body)
  "progv creates new dynamic variable bindings and executes each form
using those bindings. Each form is evaluated in order."
  (let ((var (eval symbols))
        (val (eval values)))
    `(labels ((#1=#:progv-form () ,@body))
       ((lambda (,@var)
          (declare (special ,@var))
          (funcall (function #1#)))
        ,@val))))

;; optprop.l

(launch-application "C:/cygwin/bin/wish84.exe")
(launch-application "C:/usr/local/clisp-2.46-full/lib/tclkit.exe")

;; char-codeはUNICODEを表す方が便利かもしれない(CLISPがUNICODEだから)
(unless (fboundp 'code-char-internal)
  (setf (symbol-function 'code-char-internal) #'code-char
        (symbol-function 'char-code-internal) #'char-code)
  (setf (symbol-function 'code-char) #'unicode-char
        (symbol-function 'char-code) #'char-unicode)
  )

(defun xyzzy-lisp-byte-compile ()
  "Byte compile the file containing the current buffer."
  (interactive)
  (if (file-visited-p)
      (byte-compile-file (get-buffer-file-name))
      (error "The buffer must be saved in a file first")))

;; SHA-1
;; xyzzy
(with-open-file (fp "C:/Program Files/newlisp/newlisp.exe")
  (si:sha-1 fp))
"ce3a7fd7fb67ddf2aff136dd1a16b943128b70f5"

(with-open-file (fp "C:/Program Files/newlisp/newlisp.exe" :encoding :binary)
  (si:sha-1 fp))
"561ff028b606c3671393848e279b845c5fdf60c1"

(with-open-file (fp "C:/home/lxuser/apple")
  (si:sha-1 fp))
"d0be2dc421be4fcd0172e5afceea3970e2f3d940"

;; [Emacs]
(with-temp-buffer
  (insert-file-contents "c:/Program Files/newlisp/newlisp.exe")
  (sha1 (buffer-string)))
"5fc949c2297b7d890e086ec1b0293fb3b33f627b"

(sha1 "apple")
"d0be2dc421be4fcd0172e5afceea3970e2f3d940"

(require 'sha1)
(with-temp-buffer
  (insert-file-contents "c:/home/lxuser/apple")
  (sha1 (buffer-string)))
"d0be2dc421be4fcd0172e5afceea3970e2f3d940"

;; xyzzyのシンタックステーブルの概念
;; http://www.netlaputa.ne.jp/~henmi/lisp/xyzzy/editor/980630.html
;; syntax-c++-comment-p Function: 文字CHARがC++スタイルのコメントの開始文字として規定されているかを返します。
;; syntax-close-p Function: 文字CHARが括弧などの終了文字として規定されているかを返します。
;; syntax-close-tag-p Function: 文字CHARがタグの終了文字として規定されているかを返します。
;; syntax-end-c++-comment-p Function: 文字CHARがC++スタイルのコメントの終了文字として規定されているかを返します。
;; syntax-end-comment-p Function: 文字CHARがコメント終了文字として規定されているかを返します。
;; syntax-end-multi-comment-1-p Function: 文字CHARがコメント終了の文字列の1文字目として規定されているかを返します。
;; syntax-end-multi-comment-2-p Function: 文字CHARがコメント終了の文字列の2文字目として規定されているかを返します。
;; syntax-escape-p Function: 文字CHARがエスケープ文字として規定されているかを返します。
;; syntax-junk-p Function: 文字CHARがゴミ文字として規定されているかを返します。
;; syntax-math-p Function: 文字CHARが対になった区切り文字として規定されているかを返します。
;; syntax-open-p Function: 文字CHARが括弧などの開始文字として規定されているかを返します。
;; syntax-open-tag-p Function: 文字CHARがタグの開始文字として規定されているかを返します。
;; syntax-punctuation-p Function: 文字CHARが句読点文字として規定されているかを返します。
;; syntax-quote-p Function: 文字CHARがSYNTAX-TABLEでquote(?)として規定されているか否か返します。
;; syntax-start-column-comment-p Function: set-syntax-start-column-comment で指定した文字か否かを判定します。
;; syntax-start-comment-p Function: 文字CHARがコメント開始文字として規定されているかを返します。
;; syntax-start-multi-comment-1-p Function: 文字がコメント開始の文字列の1文字目として規定されているかを返します。
;; syntax-start-multi-comment-2-p Function: 文字CHARがコメント開始の文字列の2文字目として規定されているかを返します。
;; syntax-string-p Function: 文字CHARがSYNTAX-TABLEで文字列の区切りとして規定されているか否かを返します。
;; syntax-symbol-p Function: 文字がシンボル名を構成する文字として規定されているかを返します。
;; syntax-symbol-prefix-p Function: 文字CHARがシンボルの前置子として規定されているかを返します。
;; syntax-whitespace-p Function: 文字CHARがSYNTAX-TABLEでwhitespaceとして規定されてるか否かを返します。
;; syntax-word-p Function: 文字が単語を構成する文字として規定されているかを返します。

;; set-syntax-comment-column Function: 指定された列に#\SPC以外のキャラクタがある場合にコメント行と見な
;; set-syntax-end-c++-comment Function: 文字CHARをC++スタイルのコメントの終了文字として規定します。
;; set-syntax-end-comment Function: 文字CHARをコメント終了文字として規定します。
;; set-syntax-end-multi-comment Function: 文字列STRINGをSYNTAX-TABLEに複数行のコメント終了を表す文字列として規定します。
;; set-syntax-escape Function: 文字CHARをエスケープ文字として規定します。
;; set-syntax-from-char Function: 文字のシンタックスを変更します。
;; set-syntax-junk Function: 文字CHARをゴミ文字として規定します。
;; set-syntax-match Function: 文字OPEN-CHARとCLOSE-CHARをSYNTAX-TABLEに対応付けのある文字として規定します。
;; set-syntax-math Function: 文字CHARを対になった区切り文字として規定します。
;; set-syntax-option Function: シンタックスの補助的な設定をします。
;; set-syntax-punctuation Function: 文字CHARを句読点文字として規定します。
;; set-syntax-quote Function: SYNTAX-TABLEにCHARをquoteとして規定します。
;; set-syntax-start-c++-comment Function: 文字CHARをC++スタイルのコメントの開始文字として規定します。
;; set-syntax-start-column-comment Function: set-syntax-comment-column の補助的な設定をします。
;; set-syntax-start-comment Function: 文字CHARをコメント開始文字として規定します。
;; set-syntax-start-multi-comment Function: 文字列STRINGをSYNTAX-TABLEに複数行のコメント開始を表す文字列として規定します。
;; set-syntax-string Function: SYNTAX-TABLEにCHARを文字列の区切り文字として規定します。ここで指定した文
;; set-syntax-symbol Function: 文字CHARがSYNTAX-TABLEでシンボル名を構成する文字（単語構成文字は除く）と
;; set-syntax-symbol-prefix Function: 文字をシンボルの前置子として規定します。
;; set-syntax-tag Function: シンタックステーブルにタグの開始記号と終了記号を設定します。
;; set-syntax-whitespace Function: SYNTAX-TABLEにCHARをwhitespaceとして規定します。whitespaceとして規定され
;; set-syntax-word Function: 文字を単語を構成する文字として規定します。

;; よくある文字化け
;; 完全にデコードはできていないけど、xyzzyの方が有利か？
(decode-coding-string "繝偵ｚ繧｢繝弱・繝ｬ繝・せ繝ｳ" 'utf-8) ; #("\xc2\x92\xc3\xa5\xc3\xa3..." ...)
(map-utf-8-to-internal "繝偵ｚ繧｢繝弱・繝ｬ繝・せ繝ｳ") ; "ヒ\Xd630\Xd79aアノぅレチEン"
(sjis->utf8 "ピアノ・レッスン") ; "繝斐い繝弱??繝ｬ繝??せ繝ｳ"
(utf8->sjis "\343\203\224\343\202\242\343\203\216\343\203\273\343\203\254\343\203\203\343\202\271\343\203\263")
"ピアノ・レッスン"

(defun tail-f-buffer-list ()
  (buffer-list-if #'(lambda (buffer)
                      (and (buffer-process buffer)
                           (eq (buffer-local-value buffer 'buffer-mode)
                               'ed::tail-f-mode)))))

(defun help-buffer ()
  (buffer-name (get-buffer-create "*Help*")))

;; UTF8で、ファイルの先頭に変なコードが入ります。
;; http://xyzzy.s53.xrea.com/wiki/index.php?%BC%C1%CC%E4%C8%A2%2F180
;; byte order mark ですよね？これを付けないようにするには *encoding-utf8n* を指定するとよいようです。
;; => BOM (EF BB BF)

;; http://ja.wikipedia.org/wiki/UTF-8
;; バイト順マーク "\xEF\xBB\xBF" (ByteOrderMark:BOM)
;; テキストデータの先頭にBOMを付加する
;; UTF-8	BOMあり	*その文書がUTF-8であることを明示する目的*
;; UTF-8N	BOMなし

(code-char #xFEFF)                      ; #\ZERO_WIDTH_NO-BREAK_SPACE

;; BOMがあると、"#!"で始まるシェルスクリプトが実行できない

;; quote-char が思ったより高性能
;; 詳しくは quote-char-read
C-q u                           ; unicode-char (U+FFFF)
C-q j                           ; JIS X 0208
C-q x                           ; JIX X 0212
C-q g                           ; GB 2312
C-q k                           ; KS C 5601
C-q B                           ; Big-5
C-q i                           ; ISO 8859-[0-ad]
C-q 00-FF                       ; hex

(path-equal
 (si:getenv "SystemRoot")       ; "C:\\WINDOWS"
 (get-windows-directory)        ; "C:/WINDOWS/"
 )                              ; t

;; パッケージ名ではなくシンボル名から検索している
(find-package 'lisp::editor)    ; #<package: editor>

(defun get-url (url)
  (interactive "sURL: ")
  (execute-subprocess (format nil "curl --silent ~A" url)))

;; Emacs同様タブインデントの数をファイル内で指定したい
;; -*- tab-width: 4 -*-
(defun find-tab-width (string)
  (set-local-tab-columns (parse-integer string)))
(pushnew '("tab-width" . find-tab-width) *auto-mode-parameter-alist*)

;; 前回と同じコマンドか
(eq *last-command* *this-command*)

;; FIXME: igsearch.l
shell-modeにて
isearch-backward(C-r) -> (適当に文字を打つ) -> quit(C-g) -> Error
forward/backwardはほとんど違いがないのに、なぜかbackwardのみエラー
要因: *isearch-status* の値の先頭にバッファが入っていない
そもそもbackwardはigsearch-push-statusを呼び出さずにどうやって
*isearch-status*を弄っているのか。

;; "[" 単体を入力すると正規表現エラーとなってisearchから抜けてしまう
;; -> 連続した[]が入力できない
;; 解決方法: 通常のisearch(or migemo)で入力、その後切り替え

;; デコード
(convert-encoding-from-internal
 *encoding-sjis* "\x82\xb1\x82\xf1\x82\xc9\x82\xbf\x82\xcd")
;=> "こんにちは"

;; http://geocities.yahoo.co.jp/gl/home_page22/view/20080717/1216263477
;; チャンクからの文字列読み出し時(si:unpack-string)に
;; zero-terminating-pがnilの場合は何を番兵にしているんだろうか？
;; * t なら"\000"が文字列の終端として扱われる
(map-ucs-2-to-internal
 (si:unpack-string
  (si:make-string-chunk (map-internal-to-ucs-2 "Lisp Interaction"))
  0 nil nil))
"Lisp Interaction"

;; cl-ansi-tests.l
(require "cl-ansi-tests")
;; C:/home/lxuser/code/lisp/cl-ansi-tests-20071218/
(dolist (file (directory
               "C:/home/lxuser/code/lisp/cl-ansi-tests-20071218/"
               :absolute t
               :wild "loop*.lsp"))
  (cl-run-test file))

;; 大文字のみのLISPファイルを開くのに使えそう
(let ((*readtable* (copy-readtable)))
  (setf (readtable-case *readtable*) :upcase)
  (read-from-string "(list 'a 'b)"))

(defun isearch-copy-as-kill ()
  "検索パターンをキルリングにコピーし終了"
  (ed::kill-new ed::*isearch-current-string*)
  (message "Current string copied <~A>" ed::*isearch-current-string*)
  (ed::isearch-exit))
(define-key ed::*isearch-map* #\C-c 'isearch-copy-as-kill)

;; オペレーティングシステム(OS)に処理を渡す関数なんだっけ？
;; それよりなんで下のS式、body変数が定義されていないのにループするんだろう？
(long-operation
  (while t
    (do-events)
    body))

;; よく分からない
(defconstant text-color-list
  '(none red green yellow blue purple cyan white black brown olive
    ocher azure violet 浅葱色？ gray)
  "set-text-attribute などで使える色の順番.")

;; 対括弧入力派にはあまり必要がないけど
(defun close-all-parens-in-sexp ()
  (interactive "*")
  (while (save-excursion (backward-up-list 1 'noerror))
    (insert ")")))
;; (global-set-key '(#\C-c #\C-]) 'close-all-parens-in-sexp)

(defun selection-char-count ()
  "選択領域にある改行を除く文字数を表示する."
  (interactive)
  (selection-start-end (start end)
    (prog1
        (save-excursion
          (save-restriction
            (narrow-to-region start end)
            (goto-char (point-min))
            (count-matches ".")))
      (start-selection 2 t end))))

(global-set-key #\LBtnUp 'selection-char-count)
;(global-set-key #\C-LBtnUp 'selection-char-count)
;(global-set-key #\LBtnUp 'mouse-nop)
; 文字のカウントを正規表現でやると重くなりませんか?
; 矩形に対応していない


;;; view-lossage を見やすく
(defun view-lossage-detail ()
  "最近入力したキーの表示"
  (interactive)
  (flet ((get-recent-keys-by-list ()
	   (let ((keys (get-recent-keys)) res)
	     (dotimes (x (length keys) res)
	       (let ((key (svref keys x)))
		 (push (list key (lookup-key-command key)) res))))))
    (let ((keys (get-recent-keys-by-list)))
      (with-output-to-temp-buffer ("*lossage*")
	(format t "~:{~s ~s~%~}" keys))))
  t)

;;; M-x で入力したコマンドにショートカットキーがあれば教える
;;; http://white.s151.xrea.com/wiki/index.php?memo%2Fxyzzy%2Fminibuffer#j6a14d0e
;;; http://www2.ocn.ne.jp/~cheerful/script/xyzzy/library/minitool.html#helpShortCut :別ver.
(defun execute-extended-command2 (command &optional raw arg)
  (interactive "0CM-x: \nP\np")
  (let ((*prefix-args* raw)
	(*prefix-value* arg))
    (setq *last-complex-command* nil)
    (setq *this-command* command)
    (prog1
	(command-execute command (and (interactive-p)
				      (not *executing-macro*)
				      #'ed::record-complex-command))
      (when (and (interactive-p)
		 (not *executing-macro*))
	(let ((global (command-keys command *global-keymap* nil))
	      (local (command-keys command *global-keymap* (local-keymap)))
	      (minor (command-keys command *global-keymap* (local-keymap) (minor-mode-map))))
	  (when minor
	    (labels ((key-to-string1 (key)
		       (if (consp key)
			   (concat (key-to-string (first key)) " " (key-to-string1 (second key)))
			 (key-to-string key))))
	      (message "You can run the command '~A' with  ~{[~A]~^ or ~} (~A)"
		       command (mapcar #'key-to-string1 minor)
		       (cond (global "global-keymap")
			     (local "local-keymap")
			     (t "minor-mode-map"))))
	    (sit-for 3)))))))

;; (global-set-key #\M-x 'execute-extended-command2)

;;; 過去の遺産 -> site-lisp/emacs-help.l
(defun emacs-help ()
  "暫定的ヘルプ"
  (interactive)
  (let ((bef_ime (get-ime-mode)) ; IMEいらない
	cmd)
    (toggle-ime nil)
    (minibuffer-prompt "[Help] Type ? for further options: ")
    (setf cmd
	  (case (read-char *keyboard*)
	    ((#\A) 'user::imm-apropos)
	    ((#\a) 'user::imm-command-apropos)
	    ((#\b) 'user::imm-describe-bindings)
	    ((#\c) 'describe-key-briefly)
	    ((#\f) 'describe-function)
	    ((#\i) 'ed::info)
	    ((#\k) 'user::imm-describe-key)
	    ((#\l) 'view-lossage-detail)
	    ((#\v) 'describe-variable)
	    ;; w: where-is.  Type a command name; it displays which keystrokes invoke that command.
	    ((#\F1) 'show-html-help)
	    ((#\?) (progn
		     (message-box
		      (concat	; (!)タブに注意
		       "A: apropos		a: command-apropos	b: describe-bindings\n"
		       "c: describe-key-briefly	f: describe-function	i: info\n"
		       "k: describe-key		l: view-lossage		v: describe-variable\n"
		       "F1: show-html-help	?: ヘルプ(これ)\n")
		      "ヘルプ一覧(仮)")
		     nil))
	    ((#\C-g) 'quit)
	    ))
    (when cmd
      (call-interactively cmd))
    (toggle-ime bef_ime)))

;; (global-unset-key #\F1)		; imm-refer-selection

;; タートルグラフィックで遊ぼう
(require "wip/turtle")
(win-user::star)
(win-user::spirograph)
(win-user::koch)
(win-user::c-curve)
(win-user::cross)

(require "trash/lambda-tessellation")
(win-user::draw-lambda-tessellation)

;; メニューバーメニューをポップアップ
(track-popup-menu (copy-menu-items *app-menu* (create-popup-menu)))

;; RPN電卓 (Reverse Polish Notation, 逆ポーランド記法)
;; http://www.geocities.jp/kiaswebsite/xyzzy/mcalc.html

#+NIL
(defun open-filer ()
  (interactive)
  (multiple-value-bind (files result)
      (let ((omode (get-ime-mode))
            ;; ここで変数決めると外側の束縛が無意味になってしまう
            (*filer-primary-directory*
             (if (file-visited-p)
                 (directory-namestring (get-buffer-file-name))
                 (default-directory))))
        (unwind-protect
            (filer nil t nil t (not *filer-modal*))
          (and *filer-modal* (toggle-ime omode))))
    (when result
      (filer-readin-1 files))))

#+NIL
(defun filer-delete ()
  (long-operation
    (let ((marks (or (filer-get-mark-files)
                     ;; マークがなければカーソル位置のファイルを削除対象にする
                     (list (filer-get-current-file)))))
      (when (and marks
                 (if *filer-query-delete-precisely*
                     (filer-query-delete marks)
                     (yes-or-no-p "~A" (concat "選択されたファイルを削除しまっせ"
                                               (and *filer-delete-mask*
                                                    (filer-delete-mask-string *filer-delete-mask*
                                                                              "\n削除マスク: "))))))
        (filer-subscribe-to-reload (filer-get-directory) t)
        (let ((if-access-denied (if *filer-delete-read-only-files*
                                    :force :error))
              (delete-non-empty-directory
               *filer-delete-non-empty-directory*))
          (declare (special if-access-denied
                            delete-non-empty-directory))
          (filer-do-delete marks))
        (message "done.")))))

;; (defun hyperspec-lookup (&optional use-lispworks)
;;   (interactive "P")
;;   (let ((hyperspec::*hyperspec-root*
;;          (cond (use-lispworks "http://www.lispworks.com/documentation/HyperSpec/")
;;                (t hyperspec::*hyperspec-root*))))
;;     (hyperspec:hyperspec (completing-read
;;                           "Look up symbol in Common Lisp HyperSpec: "
;;                           hyperspec::*hyperspec-symbols*
;;                           :default (hyperspec::get-symbol-at-point)
;;                           :history hyperspec::*hyperspec-history*
;;                           :must-match t))))
;; (define-key ed::*lisp-mode-map* '(#\C-c #\h) 'hyperspec-lookup)
;; (define-key ed::*lisp-interaction-mode-map* '(#\C-c #\h) 'hyperspec-lookup)

;; (html-mode) が読み込まれていない状態で
;; デフォルトバッファをhtml-modeを指定すると
;; キーワードファイルの読み込みもhtml-modeが使われるために
;; 無限ループに陥る。その結果スタックオーバーフローになる。
(let ((*default-buffer-mode* 'html-mode))
  (with-output-to-temp-buffer (#1="*markdown output*" nil)
    (cat "C:/home/xyzzy/sample.ps"))
  (switch-to-buffer #1#))

;generic.l みたいに簡単にメジャーモードが作成できたらいいのにな
(defvar *python-keyword-file* "Python")
(defvar *python-keyword-hash-table* nil)
(defun python-mode ()
  (interactive)
  (kill-all-local-variables)
  (setq mode-name "Python")
  (setq buffer-mode 'python-mode)
  (and *python-keyword-file*
       (null *python-keyword-hash-table*)
       (setq *python-keyword-hash-table*
             (load-keyword-file *python-keyword-file* t)))
  (when *python-keyword-hash-table*
    (make-local-variable 'keyword-hash-table)
    (setq keyword-hash-table *python-keyword-hash-table*))
  #+NIL
  (run-hooks '*python-mode-hook*))

;; 2010-01-26T14:19:08+09:00
;; mv emacs/22.1/lisp/emacs-lisp/bindat.el ~/site-lisp/bindat.l
;; とりあえずコンパイルできるようにはなったが何が便利か分かっていない

;; 何でデコードできない?
;; -> "\\1"はsubstitute-stringの引数そのものに適用されるので
;; 関数で囲ったりすることは出来ない
(substitute-string "04_-_don%27t%20despair.mp3"
                   "\\(%[0-9a-zA-Z][0-9a-zA-Z]\\)"
                   (si:www-url-decode "\\1"))
(si:www-url-decode "04_-_don%27t%20despair.mp3") ; "04_-_don't despair.mp3"

;; なぜか toggle-cursor-line 定義が重複していることに気づいた
;; window.l
;; 218, 234

;; (call-process :output ...) の文字コードはsjisなので注意

(defun mml-play (mml)
  (shell-execute ;"C:\\Program Files\\Mozilla Firefox\\firefox.exe"
                 "file://C:/usr/local/flash/Players/FlashPlayer.exe"
                 (default-directory)
                 (format nil "file://~A?mml=~A"
                         "c:/home/niconico/mml/flmml.swf"
                         (si:www-url-encode mml nil "-A-Za-z0-9_.!'(|)"))))
(defun mml-play-file (filename)
  (interactive (list (read-file-name "MML: " :default (get-buffer-file-name))))
  (mml-play (if (string-match "^http://" filename)
                (nl::get-url filename)
              (nl::nl-read-file filename))))
;; 引数のMMLが長すぎるとダメみたい...
(mml-play-file "C:/home/niconico/mml/pokemon_vst.fml")
(mml-play-file "http://dic.nicovideo.jp/mml/3575")
(mml-play-file "http://dic.nicovideo.jp/mml/3219")


;; 作りかけ lua-mode
;; なぜか他のモードをを選択した後にLua-modeを使わないと色が出ない
(defvar *lua-keyword-hash-table* nil)
(defvar *lua-mode-syntax-table* nil)
(unless *lua-mode-syntax-table*
  (let ((syntab (make-syntax-table)))
    ;; シンタックスのコピーでなく、まともに定義した方が良い
    (copy-syntax-table ed::*c-mode-syntax-table* syntab)
    (set-syntax-start-c++-comment syntab #\- nil) ; comment-line
    (set-syntax-end-c++-comment syntab #\LFD nil)
    (set-syntax-match syntab #\{ #\})
    (setq *lua-mode-syntax-table* syntab)))

(defun lua-mode ()
  (interactive)
  (setq mode-name "Lua"
        buffer-mode 'lua-mode)
  (unless *lua-keyword-hash-table*
    (setq *lua-keyword-hash-table*
          ;; NOTE: Lua is a case-sensitive language
          (load-keyword-file "Lua" nil)))
  (when *lua-keyword-hash-table*
    (make-local-variable 'keyword-hash-table)
    (setq keyword-hash-table *lua-keyword-hash-table*))
  (use-syntax-table *lua-mode-syntax-table*)
  )

;; 波形を作る
(defun make-graph (column)
  (dolist (y (coerce (remove #\SPC column) 'list))
    (setq y (digit-char-p y 16))
    (dotimes (n y) (princ #\*))
    ;; (dotimes (n (- 16 y)) (princ #\SPC))
    (terpri)))
(make-graph "00 23 56 78 99 98 76 67 9A DF FE C9 85 42 11 00")
;;
;;
;; **
;; ***
;; *****
;; ******
;; *******
;; ********
;; *********
;; *********
;; *********
;; ********
;; *******
;; ******
;; ******
;; *******
;; *********
;; **********
;; *************
;; ***************
;; ***************
;; **************
;; ************
;; *********
;; ********
;; *****
;; ****
;; **
;; *
;; *


(popup-list (mapcar #'prin1-to-string *archiver-dll-list*)
            #'(lambda (x)
                (archiver-dll-config-dialog
                 (read-from-string x))))

;; archive-modeを作ってみたい(2010-06-01)
(progn
  (find-file-in-archive "C:/cygwin/usr/share/man/man7/urxvt.7.gz"
                        "urxvt.7")
  (si:*activate-toplevel))
(list-archive "C:/cygwin/usr/share/man/man7/urxvt.7.gz")
(("urxvt.7" "----" 107553 (2010 1 20 11 16 56)))
(file-info "C:/cygwin/usr/share/man/man7/urxvt.7.gz")
;; 属性・最終更新日・サイズ・短い
(defun nl-file-info (pathspec)
  (multiple-value-bind (attr ctime size shortname)
      (get-file-info pathspec))
  (list size mode device-mode uid guid atime mtime ctime))

;; 数値参照から実体文字へ変換 (中途半端)
(defun sgml-nref-to-char (str)
  (cond
   ((string-match "&#x\\([0-9a-fA-F]\\{,4\\}\\);" str)
    (string (unicode-char (parse-integer (match-string 1) :radix 16))))
   ((string-match "&#\\([0-9]\\{,4\\}\\);" str)
    (string (unicode-char (parse-integer (match-string 1) :radix 10))))
   (t nil)))
(sgml-nref-to-char "&#xa0;")    ; "\X0120"

(decode *encoding-sjis*
        "shell-execute: ShellExecute failed: \202\261\202\314\221\200\215\354\202\311\221\316\202\265\202\304\216w\222\350\202\263\202\352\202\275\203t\203@\203C\203\213\202\311\202\315\201A\203A\203v\203\212\203P\201[\203V\203\207\203\223\202\252V\230A\225t\202\257\202\347\202\352\202\304\202\242\202\334\202\271\202\361\201B"
        )
"shell-execute: ShellExecute failed: この操作に対して指定されたファイルには、アプリケーションがV連付けられていません。"

;; 実体参照・数値参照を元の文字に置換する
;; いいアイディアだと思ったが、バッファを二度三度巡回すると重複置換する可能性アリ
;; なので不採用
(labels ((rep (pattern to)
           (goto-char (point-min))
           ;; (while (re-search-forward re-from t) (replace-match to :literal t))
           (replace-buffer pattern to :case-fold t
                           :regexp t :literal t)))

  (rep "&nbsp;" "\X0120") ; U+00A0
  (rep "&lt;" "<")
  (rep "&gt;" ">")
  (rep "&quot;" "\"")
  (rep "&amp;" "&")
  )

;; [xyzzy][emacs]
;; バッファの検索・置換の方法色々
#+(emacs xyzzy)
(save-excursion
  (save-restriction
    (narrow-to-region from to)
    (goto-char (point-min))
    (while (re-search-forward "..." t)
      (replace-match "***" :literal t))))

#+xyzzy
(ed::text-decode-region #'decode from to)

#+xyzzy
(replace-buffer pat rep)
;; 置換後の文字列を選べない

#+xyzzy
(save-excursion
  (goto-char from)
  (while (scan-buffer pat :regexp t :limit to)
    (let ((str (match-string 1)))
      (delete-region (match-beginning 0) (match-end 0))
      (insert ...))))

(defun sgml-quote (start end &optional unquotep)
  "Quote SGML text in region START ... END.
Only &, < and > are quoted, the rest is left untouched.
With prefix argument UNQUOTEP, unquote the region."
  (interactive "r\nP")
  (save-restriction
    (narrow-to-region start end)
    (goto-char (point-min))
    (if unquotep
        ;; FIXME: We should unquote other named character references as well.
        (while (re-search-forward
                "\\(&\\(amp\\|\\(l\\|\\(g\\)\\)t\\)\\)[][<>&;\n\t \"%!'(),/=?]"
                t)
          (replace-match (if (match-end 4) ">" (if (match-end 3) "<" "&"))
                         :literal t))
      (while (re-search-forward "[&<>\"]" t)
        (replace-match (cdr (assoc (following-char)
                                   '((#\& . "&amp;")
                                     (#\< . "&lt;")
                                     (#\> . "&gt;")
                                     (#\" . "&quot;")
                                     )))
                       :literal t)))))

;; assocがバグってる
;; ...と思ったらそうでもなかった
(assoc 'a
       '((b . x) (c d e) (a f h i) (x y) (a . b))
       :key #'(lambda (arg) (print arg))
       )

;; HOMEキーの動作をVC++と同じにするには
;; 質問箱/250 - XyzzyWiki -
;; http://xyzzy.s53.xrea.com/wiki/index.php?cmd=read&page=%BC%C1%CC%E4%C8%A2%2F250&word=VC
(defun smart-home ()
  (interactive)
  (let ((opoint (point)))
    (back-to-indentation)
    (if (= (point) opoint)
        (goto-bol))))
(global-set-key #\Home 'smart-home)

;; toggle-scratch-bufferの残骸
(labels ((window-buffer-list ()
           (mapcar #'second (third (current-window-configuration)))))
  (let ((new-buffer-p (not (find-buffer #1="*scratch*")))
        (scratch (get-buffer-create #1#)))
    (if (or popup (find scratch (window-buffer-list)))
        (pop-to-buffer scratch t)
      (set-buffer scratch))
    (when (or (not (eq buffer-mode #2=*initial-buffer-mode*))
              new-buffer-p)
      (funcall #2#))))

;; http://www.cs.cmu.edu/~dst/Lisp/ppmx.lisp
(defmacro ppmx (form)
  "Pretty prints the macro expansion of FORM."
  `(let* ((exp1 (macroexpand-1 ',form))
	  (exp (macroexpand exp1))
	  (*print-circle* nil))
     (cond ((equal exp exp1)
	    (format t "~&Macro expansion:")
	    (pprint exp))
	   (t (format t "~&First step of expansion:")
	      (pprint exp1)
	      (format t "~%~%Final expansion:")
              (pprint exp)))
     (format t "~%~%")
     (values)))
(ppmx `(1 2 3 ,(+ 1 2 3)))
(ppmx (destructuring-bind (x (y1 &optional y2) z) '(1 (2) 3)
        (list x y1 y2 z)))

(pushnew '("\\.cilk$" . c-mode) *auto-mode-alist* :test #'equal)

(defun shobon ()
  "(´･ω･｀)ｼｮﾎﾞｰﾝ"
  (interactive)
  (do ((wait 0.1) (d 1) (h 0)
       (i 0 (mod (+ i d) 10))
       (j 0 (- 25 (expt (- 4 i) 2))))
      ()
    (case (read-char-no-hang *keyboard*)
      (#\n (setq wait (max 0.01 (- wait 0.01))))
      (#\p (setq wait (min 0.15 (+ wait 0.01))))
      (#\r (setq d (- d)))
      (#\j (setq h (mod (1+ h) 4)))
      ((#\q #\C-g) (return))
      (t (sit-for wait)
         (minibuffer-prompt "~VT~A" (* h j) (nth i shobobon))))))
;; (setq *print-circle* t)
(defvar shobobon
  (let ((s '("( 　 　´)"
             "(　　 ´･)"
             "(　 ´･ω)"
             "(　´･ω･)"
             "(´･ω･｀)"
             "(･ω･｀　)"
             "(ω･｀ 　)"
             "(･｀ 　　)"
             "(｀ 　 　)"
             "( 　　　 )" )))
    (setf (cdr (last s)) s)))
;; (makunbound 'shobobon)
;; (si:*specialp (quote shobobon))
;; (boundp 'shobobon)

;; 引数は (バッファ ヒストリ判別シンボル)
;; minibuffer-history-variable (see minibuf.l)
*enter-minibuffer-hook*
*exit-minibuffer-hook*

(defun less-= ()
  "表示中のファイル名(と文字コード)を表示する."
  (interactive)
  (message "~A lines ~A-~A/~A char ~A code ~A"
           (let ((f (get-buffer-file-name)))
             (if f (file-namestring f) ""))
           (get-window-start-line)
           (if (pos-visible-in-window-p (point-max))
               (buffer-lines)
             (+ (window-lines)
                (get-window-start-line)))
           (buffer-lines) ; FIXME: byteではない
           (buffer-size)
           (char-encoding-name (buffer-fileio-encoding))))

;; 前置引数(C-u *)で数値を挿入する
;; C-u 2 1 C-u 1
;; => 111111111111111111111 ("1"が21個)

;; 外部プロセスとの連携の際のエンコーディング問題で気をつけるもの
*expected-fileio-encoding*
*expected-eol-code*
(write-region FROM TO FILENAME nil ENCODING)
(let ((*expected-fileio-encoding*))
  (declare (special *expected-fileio-encoding*))
  (insert-file-contents FILENAME))

;; *expected-fileio-encoding* <- なんぞこれ？
;; insert-file-contents でファイルを挿入する時の文字コードを指定できるっぽい

;; => map-utf-8-region (kanji.l)
;; (defun map-utf-8-to-internal-region (from to)
;;   "Shift_JISと仮定して読み込んだ文字列をUTF-8に復元する."
;;   (interactive "*r")
;;   (ed::text-decode-region #'map-utf-8-to-internal from to))

;; OLEって何？
;; OLE - xyzzy Note2 http://hie.s64.xrea.com/xyzzy/note2/wiki.cgi?page=OLE
(setq app (ole-create-object "WScript.Shell"))
(setq app2 (ole-create-object "SAPI.SpVoice"))
(setq app3 (ole-create-object "WinHttp.WinHttpRequest.5.1"))

;; Emacsの *Message* バッファをまねる
;; http://hie.s64.xrea.com/xyzzy/ml/msg03426.html
(setq *old-status-window* *status-window*
      *status-window* (make-broadcast-stream
		       *status-window*
                       (make-buffer-stream (create-new-buffer "*Message*"))))

(defun toString (num &optional (radix 10))
  (unless (integerp num) (return-from toString num)) ; XXX
  (let ((minusp (minusp num))
        (acc '()))
    (if minusp (setq num (- num)))
    (while t
      (multiple-value-bind (x y)
          (truncate num radix)
        (push y acc)
        (setq num x)
        (if (= num 0) (return))))
    (concat (if minusp "-" "")
            (map 'string
                 #'(lambda (n)
                     (elt "0123456789abcdefghijklmnopqrstuvwxyz" n))
                 acc))))
(funcall (lambda (x y)
           (list (toString x y)
                 (format nil "~vr" y x)))
         #x-deadbeef 16)
;=> ("-deadbeef" "-deadbeef")
(toString 11111 32)

;; TODO: 空白以外にマッチする正規表現の表記は？
(defun xml-format-buffer ()
  (interactive "*")
  (labels ((%s (reg rep)
             (goto-char (point-min))
             (replace-regexp reg rep t)
             ))
    (save-excursion
      (%s "><" ">\n<")
      (%s ">\\([^ \t\n\r\f\v]\\)" ">\n\\1")
      (%s "\\([^ \t\n]\\)<" "\\1\n<")
      (xml-mode)
      (indent-region (point-min) (point-max)))    
    t))

(defun replace-zenkaku-number ()
  "全角数字を半角に置換する."
  (interactive)
  (while (scan-buffer "[１２３４５６７８９０]" :regexp t)
    (let ((str (match-string 0)))
      (delete-region (match-beginning 0) (match-end 0))
      (insert (hankaku str :ascii t)))))

(defun count-matches* ()
  "リージョンに対して count-matches を呼び出す."
  (interactive)
  (save-excursion
    (unwind-protect
        (progn
          (narrow-to-region (mark t) (point))
          (goto-char (point-min))
          (call-interactively 'count-matches))
      (widen))))

(require "modeline-anime")
(setq modeline-anime::*anime*
      '("(σ・ω・)σ" 6
        "(σ・ω・)σｹﾞｯﾂ" 10
        "(σ・ω・)σ" 6
        "(σ・ω・)σいいセンスだ" 10
        "(σ・ω・)σ" 6
        "(σ・ω・)σ)∀`)" 10
        "(σ・ω・)σ" 6
        "(σ回ω・)σ←↑→↓←↑" 10
        ))

;; JSONのキーを変数に束縛する
;; 階層的な指定ができない
(defmacro with-json ((&rest vars) json &body body)
  `(let ,(loop for v in vars
           collect `(,v (cdr (assoc ,(symbol-name v) ,json :test #'equal))))
     ,@body))
(setf (get 'with-json 'ed:lisp-indent-hook) 2)

(with-json (width height size)
    (json:json-decode "{\"height\":120,\"width\":60}")
  (list width height size))
;=> (60 120 nil)

;; ソートしながら追加する
(macrolet ((push-sorted (item place)
             `(if (null ,place)
                  (push ,item ,place)
                (let ((#1=#:n (position-if #'(lambda (#2=#:x) (<= ,item #2#)) ,place)))
                  (if (equal #1# 0)
                      (push ,item ,place)
                    (push ,item (cdr (nthcdr (1- (or #1# (length ,place))) ,place))))))
               
             ))
  (let ((acc))
    (dolist (n '(1 5 2 3 9 8 6 7 4 0))
      (push-sorted n acc))
    acc))

;; JavaScriptオブジェクトのようにvalueのみ評価されるalist
(macrolet ((@ (&rest args)
             `'(,@(loop for x in args collect `(,(car x) . ,(eval (cdr x)))))))
  (@ (a . 10)
     (b . 20)
     (c . (+ 1 2 3))
     (d . (concat "hello" "world"))
     ))
;;=> ((a . 10) (b . 20) (c . 6) (d . "helloworld"))

(defun markdown-region (from to)
  "指定したリージョンをMarkdown文章としてHTMLに変換します."
  (interactive "r")
  (let ((text (buffer-substring from to)))
    (with-output-to-temp-buffer ("*Markdown HTML*" t)
      (insert (xhr:xhr-response-text
               (xhr:xhr-post "https://api.github.com/markdown/raw" text
                             :headers '(("Content-Type" . "text/plain"))))))))

;; - マシン依存の設定はどこに書こう？
(load (merge-pathnames "init.l" (user-config-path)) :if-does-not-exist nil)
;(setq *keyword-load-path* (list (merge-pathnames "keyword/" (etc-path))))

;; ~/etc/DOC の再設定
;; (setq lisp::*documentation-path* nil)
;; (add-hook '*post-startup-hook* 'lisp::documentation-path)

;; 削除されたファイルのヒストリを削除する
#+nil
(setq *minibuffer-file-name-history*
      (remove-if-not #'file-exist-p *minibuffer-file-name-history*))

(dolist (key '(#\C-1 #\C-2 #\C-3 #\C-4 #\C-5 #\C-6 #\C-7 #\C-8 #\C-9 #\C-0))
 (if (eq (lookup-key-command key) 'digit-argument)
     (global-unset-key key)))

;; clipboard->kill-ring の中途半端な同期
(defun sync-kill-ring-if-update ()
  (setq *clipboard-newer-than-kill-ring-p*
        (not (string= (apply #'concat (car *kill-ring*))
                      (get-clipboard-data)))))
;; [2014-01-21] 設定＞クリップボードを完全に同期が機能すれば必要なくなる
;(add-hook '*activate-hook* 'sync-kill-ring-if-update)

;; from estartup.l
(defun load-xyzzyrc ()
  "$XYZZY/.xyzzy のロード"
  (trap-errors
    (let ((*loading-user-initial-file* t)) ; 何の効果が?
      (load (merge-pathnames ".xyzzy" (si:system-root))
            :if-does-not-exist nil :verbose nil :print nil))))
;; USBからの起動に使えそう
;; (add-hook '*post-startup-hook* 'load-xyzzyrc)

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

;; xyzzy@wine対策
(when (string-match "^Z:/" (si:system-root))
  (cd (si:system-root))
  ;; バックアップのパスが調子悪いので
  (setq ed::*backup-directory* nil))


;; PowerShell を使ってみる (2011-09-20T23:24:43+09:00)
;(setq *eshell* "powershell.exe")
;(setq *eshell* "cmd.exe")

;; quickrun がやりたかったんだと思う (2015-02-25)

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

;; 特殊文字
;(require "iso8859-1")
; C-x 8 *

(pushnew '(#\f . emacs-interactive-function-name) *interactive-specifier-alist* :test #'equal)

(defun ed::toggle-minor-mode-map (mode map)
  (if mode
      (set-minor-mode-map map)
    (unset-minor-mode-map map)))

;; view-mode はマイナーモードで使いたい
(defvar-local view-mode nil)

(defun view-minor-mode (&optional (arg nil sv))
  (interactive "p")
  (ed::toggle-mode 'view-mode arg sv)
  (ed::toggle-minor-mode-map view-mode *view-mode-map*)
  (update-mode-line t))

(pushnew '(view-mode . "View") *minor-mode-alist* :key #'car)

;; 文字列からキーワード生成が微妙に異なる
(intern "rest" :keyword)
;;=> #+xyzzy rest: ; :external
;;=> #+common-lisp :|rest| ; nil

;; つまり、こういうコードが成立しない
(getf '(:foo 10 :bar 20 :baz 30) (intern "bar" :keyword))
;;=> #+xyzzy 20
;;=> #+common-lisp NIL

;; while/until が一回余分に実行される
;; loop.l のバグ？
(with-input-from-string (input "XYZZY")
  (loop
    for ch = (read-char input nil)
    ;;until (eq ch nil)
    while (characterp ch)
    collect ch))
;;=> (#\X #\Y #\Z #\Z #\Y nil)

;; xyzzy 0.2.2.246 ならば DebugView にログ出力することが可能
(format *debug-output* "HELLO")

;; defstruct / 構造体
(progn
(defstruct (bar
            (:constructor create-bar (a b))
            (:constructor create-bar-x (x &aux (a (* x 10)) (b (* x 20))))
            (:print-function print-bar))
  a b)

#+xyzzy
(defun print-bar (bar stream depth)
  (declare (ignoable depth))
  (format stream "#<a=~A, b=~A>" (bar-a bar) (bar-b bar)))
#+common-lisp
(defun print-bar (obj stream depth)
  (print-unreadable-object (obj stream)
    (format stream "a=~A, b=~A" (bar-a obj) (bar-b obj))))

(create-bar 1 2)
;;=> #S(bar a 1 b 2)	(xyzzy では :print-bar が無視される？)
;;=> #<a=1, b=2>	(:print-bar 使用時)

;; Q. このエラーはどういうことなの？
;; A. 構造体の定義時に引数を指定しない(デフォルトの)コンストラクタを残しておく
;;    (:constructor make-foo)
#S(bar a 10 b 20)
~> コンストラクタがありません: bar
)

(let (xx)
  (declare (special xx))
  (setq xx :setq)
  (set 'xx :set)
  xx)
;;=> :setq
;;=> :set   スペシャル宣言(declare (special ...))がある場合

;; 型を定義する
(deftype string-designator ()
  '(or character symbol string))

(typep #\a '(or character symbol string)) ; t
(typep #\a 'string-designator)            ; nil (バグっぽい)

;; detect-char-encoding 関数は文字コード判定用にストリームから文字を読み取るが
;; 終了後にストリーム位置は復元されない？

(with-open-file (fp "~/.xyzzy" :direction :input)
  (list (detect-char-encoding fp)
        (read-line fp)))
;;!> EOFに達しました: #<file-input stream: ~/.xyzzy> (ファイルサイズが小さい場合に起こる)

(with-open-file (fp "~/docs/README.md" :direction :input)
  (list (detect-char-encoding fp)
        (read-line fp)))
;;=> (#.(make-utf8-encoding "utf8n" "Unicode (UTF-8N)" :signature nil :windows t :byte-order nil :cjk :jp)
;;      "ル」→「ショートカットの作成...」でできます。")

(xhr:xhr-get "http://query.yahooapis.com/v1/public/yql"
             :query '(:q "show tables"
                      :env "http://datatables.org/alltables.env"
                      :format "json")
             :key (lambda (key)
                    (json:json-decode (xhr:xhr-response-text key))))
