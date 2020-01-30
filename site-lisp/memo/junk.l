;;; memo/junk.l --- 使用頻度の高くないもの

;; xyzzy が終了できない事態になったらひとまずこいつを実行
(defun run-kill-xyzzy-hook ()
  "*kill-xyzzy-hook* を実行する."
  (interactive)
  (run-hooks '*kill-xyzzy-hook*))

;; XyzzyWikiから拾ってきたんだと思う
(defun recentf-open-files ()
  "履歴からファイルを開く"
  (interactive)
  (let (hlist filename)
    (setq hlist (mapcar #'(lambda (x)
                            (list (abbreviate-display-string x 60 t) x))
                        *minibuffer-file-name-history*))
    (multiple-value-bind (result data)
        (dialog-box
         '(dialog 0 0 286 162
           ;;(:caption "最近使ったﾌｧｲﾙ")
           (:caption "最近使ったファイル")
           (:font 9 "ＭＳ Ｐゴシック")
           (:control
            (:listbox flist nil #x50b10111 7 7 216 148)
            (:button IDOK "OK" #x50010001 229 7 50 14)
            (:button IDCANCEL "ｷｬﾝｾﾙ" #x50010000 229 24 50 14)))
         (list (cons 'flist hlist))
         `((flist :must-match t :enable (IDOK))))
      (when result
        (setq filename (car (cddr (assoc 'flist data))))
        (find-file filename)
        (add-history filename '*minibuffer-file-name-history*)))))

#|
(defun foobar ()
  "最近開いたファイル"
  (interactive)
  (popup-list (subseq *minibuffer-file-name-history* 0 9)
              #'(lambda (file)
                  (find-file file)
                  (add-history file '*minibuffer-buffer-name-history*)
                  (refresh-screen))))
|#

;; 閉じたタブを元に戻す、を自分用に改変
;; TODO: ダイアログ使いたい
;; http://white.s151.xrea.com/wiki/index.php?memo%2Fxyzzy%2Ffile#k96261fd
(defvar *recent-killed-buffers* nil)

(defun push-visited-file-recent-killed (buffer)
  (when (file-visited-p buffer)
    (pushnew (get-buffer-file-name buffer)
             *recent-killed-buffers* :test #'equal))
  t)
(add-hook '*delete-buffer-hook* 'push-visited-file-recent-killed)

(defun recentf ()
  "最近閉じたファイル"
  (interactive)
  (unless *recent-killed-buffers*
    (error "最近閉じられたバッファはありますん"))
  (popup-list (subseq *recent-killed-buffers*
                      0 (min (length *recent-killed-buffers*) 9))
              #'(lambda (file)
                  (find-file file)
                  (add-history file '*minibuffer-buffer-name-history*)
                  (setf *recent-killed-buffers*
                        (delete file *recent-killed-buffers* :test #'equal))
                  (refresh-screen))))

;; 'si:*trace-on-error* とかクオートされたシンボルの値を評価したい
(defun get-variable-value ()
  "現在のポイント上にあるシンボルを評価します."
  (interactive)
  (let ((name (with-syntax-table ed::*lisp-mode-syntax-table*
                (buffer-substring (progn
                                    (skip-syntax-spec-backward "w_")
                                    (point))
                                  (progn
                                    (skip-syntax-spec-forward "w_")
                                    (point))))))
    (if (string= name "")
        ;;(return-from get-variable-value)
        (warn "symbol not found at point")
        (let ((symbol (multiple-value-bind (sym pac)
                          (values-list (reverse (split-string name ":")))
                        (when sym
                          ;; (find-symbol sym (or (find-package pac) (find-package *buffer-package*) *package*))
                          ;; 全てのシンボル名は被ることが無いという前提ありで使う
                          (some (lambda (x) (and (boundp x) x))
                                (find-all-symbols sym))
                          ))))
          (if (and symbol
                   (boundp symbol))
              (message "~S -> ~S" symbol (symbol-value symbol))
              (plain-error "変数が定義されていません: ~A" name))))))
(define-key spec-map #\C-e 'get-variable-value)


;; 毎度毎度 do-all-symbols は時間がかかるのでキャッシュで誤魔化す
(defvar *keymaplist* nil)

(defun keymaplist (&optional force-update)
  (or (and (not force-update)
           *keymaplist*)
      (long-operation
        (do-all-symbols (sym *keymaplist*)
          (if (and (boundp sym)
                   (keymapp (eval sym)))
              (push sym *keymaplist*))
          ))))

(defun describe-binding-anymap (keymap)
  "任意のキーマップの割り当て一覧を表示."
  (interactive (find-all-symbols
                (completing-read "Describe binding: "
                                 (keymaplist)
                                 :must-match t)))
  (with-output-to-temp-buffer ((string keymap))
    (format t "~S:~%key~20Tbinding~%---~20T-------" keymap)
    (ed::describe-bindings-1 "" (eval keymap) nil)
    (goto-char (point-min))
    (toggle-read-only t)))

(defvar-local *summaries* nil
  "`ed::build-summary-function' のキャッシュ")

(defun build-summary-function (&key (update t) (if-does-not-exist :skip))
  (cond ((boundp 'ed::build-summary-function)
         (when (or update (null *summaries*))
           (setf *summaries* (funcall ed::build-summary-function)))
         (or *summaries*
             #1=(if (eq if-does-not-exist :error)
                    (error "関数ないアルヨ")
                  nil)))
        (t #1#)))

(defun goto-function (fname)
  "バッファ中の関数名 FNAME にジャンプする."
  (interactive
      (list (let ((fns (build-summary-function :update t :if-does-not-exist :error)))
              (completing-read "Goto Function: "
                               (mapcar #'second fns)
                               :must-match t))))
  (let ((x (find fname (build-summary-function :update nil) :key #'second :test #'equal)))
    (when x
      (goto-line (first x)))))

(define-key spec-map #\l 'goto-function)

;; (require "paren") とかにもそれなりに対応
(defun ffap-find-file (filename)
  "find file at point."
  (interactive "fFind-file: " :default0 (pathname-at-point *prefix-args*))
  (find-file filename)
  (add-history filename '*minibuffer-file-name-history*))

(defun pathname-at-point (&optional arg)
  ;; 2010-04-16:fixed:バックスラッシュもスキップする文字に追加
  (let* ((skip-chars "-a-zA-Z0-9_/~.#@%?&=+(),'$!*:\\")
         (from (save-excursion
                 (skip-chars-backward skip-chars)
                 (point)))
         (to (save-excursion
               (skip-chars-forward skip-chars)
               (point)))
         (odir (default-directory)))
    (unless (eql from to)
      ;; (or (default-directory) (directory-namestring (get-buffer-file-name)))
      (set-default-directory (pwd))
      (let* ((word (buffer-substring from to))
             (path (cond ((file-exist-p word)
                          (if (file-directory-p word)
                              (append-trail-slash (namestring word))
                              (namestring word)))
                         (arg
                          ;; 環境変数から検索
                          (some #'(lambda (dir)
                                    (let ((x (merge-pathnames word dir)))
                                      (when (file-exist-p x)
                                        x)))
                                (mapcar #'map-backslash-to-slash
                                        `(,@(split-string (si:getenv "PATH") #\;)
                                          ,(si:getenv "HOME")
                                          ,(si:getenv "XYZZYHOME")
                                          ))
                                ))
                         (t
                          (or (find-load-path (concat word ".l"))
                              (find-load-path word))))))
        (prog1
            path
          (and path (reverse-region from to t))
          (set-default-directory odir))))))

;; xyzzy スレ >>383
;; http://yasai.2ch.net/win/kako/979/979930156.html#383
(defun colortest ()
  "番号と色の対応確認。(前景色:背景色)"
  (interactive)
  (let ((obuffer (selected-buffer)))
    (with-output-to-temp-buffer (" *ColorTest*" t)
      (dotimes (x 16)
        (dotimes (y 16)
          (let ((beg (point)) end)
            (insert (format nil "~2D:~2D" x y))
            (set-text-attribute beg (point) 'color
                                :foreground x
                                :background y)))
        (insert "\n"))
      (goto-char (point-min)))
    (pop-to-buffer obuffer)))
(setf (symbol-function 'list-colors-display) #'colortest)


(defun pwd ()
  "作業中のディレクトリ."
  (if (file-visited-p)
      (directory-namestring (get-buffer-file-name))
      (default-directory)))

(defun ed::message! (fmt &rest args)
  "メッセージを表示するついでに音も鳴らします."
  (ding)
  (apply #'message fmt args))


;; @@describeシリーズ

(defun symbol-describe (symbol)
  `((:name     ,(symbol-name symbol))
    (:package  ,(symbol-package symbol))
    (:value    ,(and (boundp symbol) (symbol-value symbol)))
    (:function ,(and (fboundp symbol) (symbol-function symbol)))
    (:plist    ,(symbol-plist symbol))))
;; (symbol-describe 'lisp::*terminal-io*)

(defun process-describe (process)
  `((:command   ,(process-command process))
    (:buffer    ,(process-buffer process))
    (:eol-code  ,(process-eol-code process))
    (:exit-code ,(process-exit-code process))
    (:filter    ,(process-filter process))
    (:sentinel  ,(process-sentinel process))
    (:incode    ,(process-incode process))
    (:outcode   ,(process-outcode process))
    (:maker     ,(process-marker process))))

(defun hash-describe (hash-table)
  `((:size        ,(hash-table-size hash-table))
    (:rehash-size ,(hash-table-rehash-size hash-table))
    (:test        ,(hash-table-test hash-table))
    (:count       ,(hash-table-count hash-table))
    (:item        ,(make-list-from-keyword-table hash-table))))

(defun package-describe (package)
  `((:name              ,(package-name package))
    (:nicknames         ,(package-nicknames package))
    (:shadowing-symbols ,(package-shadowing-symbols package))
    (:use-list          ,(package-use-list package))
    (:used-by-list      ,(package-used-by-list package))))

(defun radix-list (n)
  "N進数表."
  `((:bin ,(format nil "#b~B" n))
    (:oct ,(format nil "#o~O" n))
    (:dec ,(format nil   "~D" n))
    (:hex ,(format nil "#x~X" n))))

(defun pathname-describe (pathname)
  `((:device    ,(pathname-device pathname))
    (:host      ,(pathname-host pathname))
    (:directory ,(pathname-directory pathname))
    (:name      ,(pathname-name pathname))
    (:type      ,(pathname-type pathname))
    (:version   #-xyzzy ,(pathname-version pathname)
                #+xyzzy nil)))

(defun encoding-names (encoding)
  "文字エンコーディングENCODINGの名前一覧を返す."
  `((:display-name ,(char-encoding-display-name encoding))
    (:name         ,(char-encoding-name encoding))
    (:misc         ,(cdr (assoc encoding ed:*character-set-alist*
                                :key #'symbol-value)))))

;; (name-encoding "Shift_JIS") => #.(make-sjis-encoding "sjis" "日本語(Shift_JIS)") ; t
(defun name-encoding (name)
  "NAMEに対応する文字コードオブジェクトを返します."
  (gethash name *mime-charset-name-hash-table*))

(defun refwiki-symbol->url (symbol &optional and-go)
  "SYMBOLを参照するrefwikiのURLを返す."
  (interactive "Srefwiki: " :default0 (current-word t))
  (let ((url (concat "http://xyzzy.s53.xrea.com/reference/wiki.cgi?p="
                     (symbol-name symbol))))
    (cond ((or and-go (interactive-p))
           (shell-execute url t))
          (t
           (format t "~A" url)))))

(defun toggle-read-only-colorful (&optional (arg nil sv))
  "書込み禁止バッファを色付けで区別する."
  (interactive "p")
  (toggle-read-only)
  (if buffer-read-only
      (set-buffer-colors #(0 #xcccccc))
      (set-buffer-colors nil)))
;; (global-set-key '(#\C-x #\C-q) 'toggle-read-only-colorful)

(defun get-window-end-line (&optional window)
  "ウィンドウの後尾行"
  (save-window-excursion
    (set-window window)
    (if (pos-visible-in-window-p (point-max))
        (buffer-lines)
      (+ (window-lines) (get-window-start-line)))))

;; 普段見えないバッファだって参照したいときもある
(defun switch-to-invisible-buffer (buffer)
  (interactive
      (list (completing-read
             "Switch to buffer: "
             (mapcar #'buffer-name
                     (remove-if-not #'(lambda (buf)
                                        (find #\SPC (buffer-name buf) :end 1))
                                    (buffer-list)))
             :must-match t :case-fold t)))
  (switch-to-buffer buffer))

(defun refresh-xyzzy ()
  (refresh-screen)
  (refresh-title-bar)
  (refresh-tool-bars)
  (do-events))

(defun map-backslash-to-slash-region (from to)
  (interactive "*r")
  (save-restriction
    (goto-char (min from to))
    (narrow-to-region from to)
    (replace-string "\\" "/" 'noerror)))

(defun map-slash-to-backslash-region (from to)
  (interactive "*r")
  #+nil
  (ed::text-decode-region
   #'(lambda (in &optional out)
       (format out "~a" (map-backslash-to-slash in)))
   from to)
  #-nil
  (save-restriction
    (goto-char (min from to))
    (narrow-to-region from to)
    (replace-string "/" "\\" 'noerror)))

(defun tail-f-console (filename)
  (interactive "ftail-f: " :title0 "tail-f")
  (launch-application (format nil "\"~A\" ~A"
                              (merge-pathnames "tail-f.exe" (etc-path))
                              filename)))

(defun calc1 (&optional expr)
  "一行電卓"
  (interactive "scalc: ")
  (require "calc")
  (message "~a=~a" expr (ed::calc-string expr)))

(defun defshell (&key name command
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
    ))

#|
(defshell :name "JavaScript"    ; rhino
          :command "java -classpath C:/Users/shigeru/bin/js.jar org.mozilla.javascript.tools.shell.Main -strict")
(defshell :name "JScript"
          :command "cscript C:/cygwin/home/shigeru/code/wsh/shell.js")
(defshell :name "jrunscript"
          :command "C:/Program Files/Java/jdk1.6.0_30/bin/jrunscript.exe")
(defshell :name "Clojure"
          :command "java -cp C:/Users/shigeru/bin/clojure-1.3.0.jar clojure.main")
|#


(defun set-local-tab-columns (col)
  "タブ幅の設定をします (バッファローカル)"
  (interactive "nTab tolumn: ")
  (unless (<= 1 col 32)
    (error "範囲外の整数です"))
  (set-tab-columns col (selected-buffer)))

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

;(global-set-key #\C-F8 'indent-buffer)

(defun tac-region (start end)
  "行を逆順にする."
  (interactive "*r")
  (filter-region "C:/cygwin/bin/tac.exe" start end))

;; xyzzy で Unicode エスケープ
;; http://ukgk.g.hatena.ne.jp/faerie/20061005/1160035556
(defun unicode-escape (input &optional output)
  "ストリームを Unicode エスケープする。"
  (let (c)
    (while (setq c (read-char input nil))
      (if (> (char-unicode c) 255)
          (format output "\\u~4,'0X" (char-unicode c))
        (write-char c output)))))

(defun unicode-escape-region (from to)
  "リージョンを Unicode エスケープする。"
  (interactive "*r")
  (ed::text-decode-region #'unicode-escape from to))

(defun unicode-escape-string (s)
  "文字列を Unicode エスケープする。"
  (with-output-to-string (o)
    (with-input-from-string (i s)
      (unicode-escape i o))))

#+nil
(unicode-escape-string "いろは") ; "\\u3044\\u308d\\u306f"

(defun one-line (str &optional (padding #\SPC))
  "文字列を一行にまとめる."
  (if padding
      (substitute padding #\LFD str)
      (remove #\LFD str)))

;; (provide ".xyzzy") => ".xyzzy"
;; FIXME: goal-column を考慮してない、てか移動するの？
(defun find-buffer-provide ()
  (save-excursion
    (ed::protect-match-data
      (goto-char (point-min))
      (and (or (re-search-forward "(provide \"\\(.+\\)\")" t) ; (privide "foo")
               (re-search-forward "(provide '\\(.+\\))" t))   ; (probide 'foo)
           (match-string 1)))))


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

(global-set-key '(#\C-c #\t #\f) 'toggle-buffer-fold)

(defun get-in (object keys &optional not-found)
  (reduce #'(lambda (obj key)
              (case (type-of key)
                (integer (elt obj key))
                (symbol        (cdr (assoc key obj)))
                (simple-string (cdr (assoc key obj :test #'string=)))
                (otherwise (error "Unknown key type: ~a" key))))
          keys :initial-value object))

(defun escape-stream (in out)
  "入力INをエスケープ処理してOUTに出力します."
  (check-type out stream)
  (map nil (lambda (c)
             (if (or (char<= #\x20 c #\x7e) ; printable ascii
                     (char= c #\newline))
                 (format out "~c" c)
               (format out "\\x~02,'0x" (char-code c))))
       (convert-encoding-to-internal *encoding-binary* in)))

(defun escape (in &optional out)
  (if (null out)
      (with-output-to-string (_o)
        (escape-stream in _o))
    (escape-stream in out)))

#+test
(escape "[a-z] こんにちは?")

(defun escape-region (from to)
  (interactive "*r")
  (ed::text-decode-region #'escape from to))

(defun text-filter-region (command from to)
  "選択範囲(FROM-TO)をCOMMANDでフィルタします."
  (interactive "*aFilter command: \nr")
  (ed::text-decode-region command from to))
