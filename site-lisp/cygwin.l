;;; -*- Mode: Lisp; Package: EDITOR; Encoding: Shift_JIS -*-
;;;
;;; cygwin.l --- cygwinのコマンド群を扱うパッケージ
;;;
;;; This file is NOT part of xyzzy.
;;;

#|
### これはなに？

xyzzyからcygwinのコマンドを扱う際に便利そうな関数を集めたものです。
今のところmanページを表示するくらいしかできません…

### インストール

(require "cygwin")
;; 日本語マニュアルを使っている場合
(setq ed::*cygwin-environment-alist* '(("LANG" . "ja_JP.SJIS")))
(pushnew "/usr/local/share/man" *manpath* :test #'equal)

### マニュアル

-- Function: run-cygwin-console &optional LOGIN

   別ウィンドウでコンソールを起動します。
   引数を与えるとログインした状態でコンソールを起動します。

-- Function: shell-on-cygwin

   xyzzyのバッファからシェルを操作します。あまり使っていません:-P

-- Function: less-mode &optional (ARG nil SV)

   lessのキーバインドを真似るマイナーモードです。"q"で終了します。

-- Function: man STR &optional SECTION

   manページを表示します。SECTIONはmanのセクション番号(1-9)を指定します。
   *** /cygwin/bin にパスが通っていないと多分動きません

### ChangeLog

2008-10-01 初版
2009-08-20 less-mode追加
2009-10-26 save-manual-cache追加
2010-01-01 色々間違っていたcygpathの修正、manual-listをもう少し効率良く
2010-07-02 manプロセス実行中にカーソルがミニバッファにあるとマズかったので修正
2010-07-16 manの履歴を保存できるようにした
           read-manual-entryの大文字小文字の区別をちょっとだけ賢く

;;; by KOBAYASHI Shigeru (kosh)  <shigeru.kb[at]gmail.com>
|#

(provide "cygwin")

(in-package "editor")

(export '(*cygwin-root*))
(export '(run-cygwin-console shell-on-cygwin))

(defvar *cygwin-root* "C:/cygwin/"
  "cygwinのルートディレクトリ")
(defvar *cygwin-shell* "/bin/bash")

(defvar *cygwin-environment-alist* '(("LANG" . "C"))
  "cygwinを起動する際に用いる環境変数")

;;; shellの切り替え
;;; /etc/profile の cd "${HOME}" 周辺をコメントアウトする
;;; ただし bash --login では制御文字を処理できない
;; (setq *eshell* "bash --login -i")  ;; デフォルトはcmd.exe
(defun run-cygwin-console (&optional login)
  (interactive "P")
  (if login
      (launch-application "cmd /c env CHERE_INVOKING=yes bash --login -i")
    (launch-application (format nil "~A -i"
                                (cygpath *cygwin-shell* :type :windows)))))

(defun shell-on-cygwin ()
  "xyzzy のバッファから bash を操作します。"
  (interactive)
  (set-buffer (get-buffer-create "*Bash*"))
  (let ((*eshell* "bash -i")
        (*cygwin-environment-alist*
         `(("PS1" . "[\\u@\\h:\\w]\\n\\$ ") ,@*cygwin-environment-alist*))
        (proc (buffer-process (selected-buffer))))
    (and proc (eq (process-status proc) :run)
         (return-from shell-on-cygwin t))
    (goto-char (point-max))
    (ed::shell-mode)
    (make-process *eshell*
                  :output (selected-buffer)
                  :environ *cygwin-environment-alist*
                  :incode *encoding-sjis*
                  :outcode *encoding-euc-jp*
                  :eol-code *eol-guess*)
    ))

;; cygwin-mount.l が参考になりそう
;; http://miyamuko.s56.xrea.com/xyzzy/cygwin-mount/

;; http://cygwin.com/cygwin-ug-net/using-utils.html#cygpath
;; -d, --dos	print DOS (short) form of NAMEs (C:\PROGRA~1\)
;; -m, --mixed	like :windows, but with regular slashes (C:/WINNT)
;; -u, --unix	(default) print Unix form of NAMEs (/cygdrive/c/winnt)
;; -w, --windows print Windows form of NAMEs (C:\WINNT)

;; FIXME: 動けば良い程度の出来
;(export '(cygpath))
(defun cygpath (pathname &key (type :unix))
  "Convert Unix and Windows format paths, or output system path information."
  (labels ((u2w (path)
             (cond ((string-match "^/cygdrive/[a-zA-Z]\\(.*\\)" path)
                    (namestring (match-string 1)))
                   ((string-match "^/" path)
                    (merge-pathnames (string-left-trim "/" path) *cygwin-root*))
                   (t
                    (namestring pathname)))))
    (case type
      (:dos (get-short-path-name (u2w pathname)))
      (:mixed (map-backslash-to-slash (u2w pathname)))
      (:unix (map-backslash-to-slash
              (if (file-name-absolute-p pathname)
                  (format nil "/cygdrive/~A/~A"
                          (string-downcase (pathname-device pathname))
                          (substring pathname 3))
                pathname)))
      (:windows (map-slash-to-backslash (u2w pathname)))
      (t (error "不正な変換指定です: ~S"  type)))))

(defun file-name-absolute-p (filename)
  (if (string-match "^[a-zA-Z]:" filename) t nil))


;;; へなちょこ less モード
(export 'less-mode)

(pushnew '(less-mode . "Less") *minor-mode-alist* :key #'car)
(defvar-local less-mode nil)

(defun less-message ()
  (message "HELP -- Press RETURN for more, or q when done"))

(defun less-mode (&optional (arg nil sv))
  (interactive "p")
  (toggle-mode 'less-mode arg sv)
  (cond (less-mode
         ;; (add-hook '*post-command-hook* 'less-message)
	 (set-minor-mode-map *less-mode-map*))
	(t
         ;; (delete-hook '*post-command-hook* 'less-message)
	 (unset-minor-mode-map *less-mode-map*)))
;  (toggle-read-only less-mode)
  (update-mode-line t))

(defvar *less-mode-map* nil)
(unless *less-mode-map*
  (setf *less-mode-map* (make-sparse-keymap))
  (mapc #'(lambda (x)
            (let ((keys (mapcar #'(lambda (str)
                                    (coerce str 'list))
                                (car x)))
                  (command (cdr x)))
              (dolist (key keys)
                (define-key *less-mode-map* key command))))
        '(;; キーマップの詳細はlessのヘルプ参照
	  (("h" "H") . undefined) ; help
          (("q" ":q" "Q" "ZZ") . less-quit)
          (("e" "\x05" "j" "\x0e" "\x0d") . less-scroll-down) ; ^E ^N ^M
          (("y" "\x19" "k" "\x0b" "\x10") . less-scroll-up)   ; ^Y ^K ^P
          (("f" "\x06" "\x16" " ") . next-page)               ; ^F ^V
          (("b" "\x02" "\x8076") . previous-page)             ; ^B ESC-v
          (("z") . next-page)
          (("w") . previous-page)
          ;; (("\X8020") . less-next-page?) ; ESC-SPACE
          (("d" "\x04") . (lambda ()
                            (interactive)
                            (let ((*page-scroll-half-window* t))
                              (next-page)))) ; ^D
          (("u" "\x15") . (lambda ()
                            (interactive)
                            (let ((*page-scroll-half-window* t))
                              (previous-page)))) ; ^U
          (("\X8028" "\xff06") . scroll-right)   ; ESC-( RightArrow
          (("\X8028" "\Xff04") . scroll-left)    ; ESC-) LeftArrow
          ;; (("F") . tail-f?)
          (("r" "\x12" "\x0c") . (lambda () (interactive) (refresh-screen))) ; ^R ^L
          ;; (("R") . refresh-screen-noinput?)
          (("/") . search-forward)
          (("?") . search-backward)
          (("n") . repeat-forward-search) ; search-forward-again?
          (("N") . repeat-backward-search) ; search-backward-again?
          ;; (("ESC-n") . undefined)
          ;; (("ESC-N") . undefined)
          ;; (("ESC-u"). undefined)
          (("g" "<" "\X803c") . beginning-of-buffer) ; ESC-<
          (("G" ">" "\X803e") . end-of-buffer)       ; ESC->
          (("p" "%") . less-goto-page)
          (("{" "(" "[" "}" ")" "]") . goto-matched-parenthesis)
          ;; (("ESC-^F <c1> <c2>") . undefined)
          ;; (("ESC--B <c1> <c2>") . undefined)
          ;; (("m") . less-mark-line)
          ;; (("'" "\x18\x18") . less-goto-mark) ; ^X^X
          ;; (("=" "\x07" ":f") . undefined) ; 表示中のファイル名(と文字コード)を表示する
          (("!") . execute-subprocess)
          ;; (("@") . change-fileio-encoding)
          (("v") . less-quit)   ; バッファを編集する
          (("1" "2" "3" "4" "5" "6" "7" "8" "9" "0") . digit-argument)))
  )

(defun less-scroll-down (&optional (arg 1))
  (interactive "p")
  (scroll-window arg))

(defun less-scroll-up (&optional (arg 1))
  (interactive "p")
  (scroll-window (- arg)))

(defun less-goto-page (&optional (arg 0))
  (interactive "p")
  (goto-line (* (/ (buffer-lines) 100) arg))
  (recenter 0))

(defun less-quit ()
  (interactive)
  (less-mode nil))


;;; マニュアルを参照する

;; 参考: $EMACS/lisp/man.el
;; "LANG=C man man | [col -b | colcrt]" を使う方法もある
;; TODO:
;; * 日本語MANも見たい (cygwin側で設定が必要、それと文字コード関連)
;; * 下線、太線の強調
;; * manual-mode (view-mode, less-mode)
;; (set-text-attribute FROM TO TAG :bold t :underline t)

;; セクション一覧
;; ==============
;; 1. ユーザ用コマンド
;; 2. システムコール
;; 3. ライブラリ関数
;; 4. デバイスファイル (/dev)
;; 5. ファイルフォーマット、各種設定ファイル (eg /etc/passwd)
;; 6. ゲーム
;; 7. その他、習慣等の説明
;; 8. 管理者用コマンド
;; 9. カーネルルーチン [Non standard]

;; Known bugs
;; ==========
;; - 元の表示とは違う位置で改行が入る(再現性はあるっぽい)

(export '(manual-entry
          man
          manpage-fontify-buffer))

(export '(*manpath*
          *manual-cache-filename*))

(defvar *manpath* '("/usr/local/man" "/usr/share/man" "/usr/man")
  "環境変数 $MANPATH と大体同じ.")
(defvar *manual-cache-filename* "~/usr/.man-cache.l"
  "manを参照するためのトピックリストを保存するファイル名.")
;; 自前で保存場所を決めるべきか
;; ヒストリ変数として他とまとめるべきか
(defvar *manual-list* nil)

;; ヒストリ
(define-history-variable *manual-name-history* nil)
(setf (get ':manual-name 'minibuffer-history-variable) '*manual-name-history*)
;; ヒストリ削除
;; (unregister-history-variable 'ed::*manual-name-history*)

;; FIXME: 色付けは未実装
;; 制御文字を取り除いてテキスト表示するのみ
;; 取り除くべき制御文字に「改行文字」も含まれている気がする
;; http://www.isthe.com/chongo/tech/comp/ansi_escapes.html
(defun manpage-fontify-buffer ()
  (interactive "*")
  (labels ((trim-buffer (pattern &optional (regexp nil))
             (save-excursion
               (goto-char (point-min))
               (replace-buffer pattern "" :regexp regexp))))
    (trim-buffer ".\b\b" t)     ; ?
    (trim-buffer "_\b" t)       ; 下線 :underline
    (trim-buffer "\b." t)       ; 太字 :bold

    (trim-buffer "\033[0m")   ; for windows7
    (trim-buffer "\033[1m")
    (trim-buffer "\033[4m")
    (trim-buffer "\033[22m")
    (trim-buffer "\033[24m")
    (trim-buffer "\033[\n1m")
    (trim-buffer "\033[0\nm")
    ))

;; (use 'make-process)
;; 日本語版マニュアル配布元: JM Project - http://www.linux.or.jp/JM/
;; 公式配布のマニュアルの文字コードはeuc-jp:lfのみ提供だったはず
(defun man (str &optional section)
  "cygwin のマニュアルを参照します."
  (interactive (list (read-manual-entry "Manual entry: ") *prefix-value*))
  (if (string= str "")
      (error "What manual page do you want?"))
  (if section (setq str (format nil "~D ~A" section str)))
  (message "Invoking man ~A in the background" str)
  (let* ((tmpbuf (create-new-buffer " *Man temp*"))
         (proc (make-process (format nil "\"~A\" ~A" (cygpath "/bin/man" :type :windows) str)
                             :output tmpbuf
                             :environ (cons (cons "MANPATH"
                                                  (format nil "~{~A~^:~}" *manpath*))
                                            *cygwin-environment-alist*)
                             )))
;    (set-process-incode proc *encoding-euc-jp*)
    (set-process-incode proc *encoding-utf8n*)
    (set-process-eol-code proc *eol-lf*)
    (set-process-filter proc
                        #'(lambda (process str)
                            (save-excursion
                              (with-set-buffer
                                (set-buffer tmpbuf)
                                (insert str "\n")))))
    (set-process-sentinel
     proc
     ;; この関数内でエラーを投げると正常に機能しない？
     ;; エラーキャッチはできるんだが、音と表示が出ない
     #'(lambda (process)
         (unwind-protect
             ;; `man -k STRING` も返り値１になるようだが使わないので無視する
             (cond ((/= 0 (process-exit-code process))
                    (save-excursion
                      (with-set-buffer
                        (set-buffer tmpbuf)
                        (goto-char (point-min))
                        ;; "No manual entry for STRING"
                        ;; "No entry for STRING in section N of the manual"
                        (let ((msg (and (scan-buffer
                                         (compile-regexp
                                          "^No \\(manual \\)?entry for .*$"))
                                        (match-string 0))))
                          (progn (ding) (message "~A" msg))
                          (error "~A" msg)))))
                   (:else
                    (with-output-to-temp-buffer ((format nil "*Man ~A*" str) t)
                      (progn
                        ;; [euc-jp:lf]
                        (set-buffer-fileio-encoding *encoding-euc-jp*)
                        (change-eol-code *eol-lf*))
                      (insert-buffer tmpbuf)
                      (manpage-fontify-buffer)
                      (toggle-read-only t)
                      ; (less-mode t)
                      ; (set-default-directory (selected-buffer))
                      (message "~A man page formatted" str)
                      )))
           (progn
             (or (deleted-buffer-p tmpbuf)
                 (delete-buffer tmpbuf))
             (refresh-screen)))))))

(setf (symbol-function 'manual-entry) #'man)

;; (use 'call-process)
#+NIL
(defun man-page (str &optional section)
  (interactive (list (read-manual-entry "Manual entry: ") *prefix-value*))
  (if section
      (setq str (format nil "~D ~A" section str)))
  (labels ((trim-buffer (regexp)
             (save-excursion
               (goto-char (point-min))
               (replace-buffer regexp "" :regexp t))))
    (let ((tempfile (make-temp-file-name "man")))
      (unwind-protect
          (long-operation
            (call-process (format nil "~A ~A"
                                  (cygpath "/bin/man.exe" :type :windows)
                                  str)
                          :environ *cygwin-environment-alist*
                          :output tempfile :show :minimize :wait t)
            (with-open-file (s tempfile :direction :input)
              (let ((res (read-line s nil "[EOF]")))
                ;; "No manual entry for ***"
                ;; "What manual page do you want?"
                (if (string-match "^\\(No\\|What\\)" res)
                    (error res))))
            (with-output-to-temp-buffer ((format nil "*Man ~A*" str) t)
              (insert-file-contents tempfile)
              ;; 下線->太字の順に消すと上手くいく
              (trim-buffer "_") ; 下線
              (trim-buffer ".") ; 太字
              (toggle-read-only t)))
        (delete-file tempfile)))))

(defun manual-list (&optional re-cache nomsg)
  (when (or (null *manual-list*) re-cache)
    (long-operation
      (unless nomsg (message "Making manual list..."))
      (dolist (dir (mapcar #'(lambda (path)
                               (cygpath path :type :windows))
                           *manpath*))
        (dolist (file (directory dir :recursive t :file-only t))
          ;; filename.ext1.ext2 => filename
          (pushnew (pathname-name (pathname-name file))
                   *manual-list* :test #'equal)))
      (save-manual-cache *manual-cache-filename*)
      (unless nomsg (message "Making manul list..done"))))
  *manual-list*)

;; XXX: cygwinパッケージを更新したらマニュアルも更新
(export '(manual-list-update))
(defun manual-list-update ()
  (interactive)
  (manual-list t))

;; $CYGWIN/etc/profile
;; MANPATH=/usr/local/man:/usr/share/man:/usr/man:$MANPATH
;; woman-topic-all-completions
;; woman-file-name-all-completions
(defun read-manual-entry (prompt &key default)
  (labels ((fixed-case (str)
             (or (find str (manual-list) :test #'string=)
                 (find str (manual-list) :test #'string-equal))))
    (fixed-case
     (completing-read prompt
                      (manual-list)
                      :case-fold t
                      :default default
                      :history :manual-name
                      :must-match t))))

(defun save-manual-cache (filename)
  (with-open-file (outfile filename
                           :direction :output
                           :if-exists :supersede
                           :if-does-not-exist :create)
    (princ (concat
            ";;; Cygwin manual list. -*- mode:lisp -*-\n"
            ";;; This file is generate automatically. do not edit!\n")
           outfile)
    (print `(in-package "editor") outfile)
    (terpri outfile)
    (print `(setq *manual-list* ',(manual-list)) outfile)
    (terpri outfile))
  t)

(defun restore-manual-cache (&optional filename)
  (when (or filename
            (and #1=*manual-cache-filename*
                 (file-exist-p #1#)
                 (setq filename #1#)))
    (load filename :verbose nil)))

(add-hook '*post-startup-hook* 'restore-manual-cache)

(export '(manual-file))
(defun manual-file (file)
  "マニュアルファイルを直接指定してmanコマンドを実行する."
  (interactive
      (list (read-exist-file-name "Manual file: "
                                  :default (get-buffer-file-name)
                                  :title "マニュアルファイル")))
  ;; man は引き数 name にスラッシュ (/) がある場合、
  ;; ファイルの指定であると解釈して検索を行わない
  (man (cygpath file :type :unix)))

;;; cygwin.l ends here.
