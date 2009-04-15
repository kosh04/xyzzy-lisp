;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is NOT part of xyzzy.

;;; てきとー作りかけ。USB-xyzzy では使わないから分離しただけ。

(provide "cygwin")

(in-package "editor")

(export '(*cygwin-root* *manpath*))
(export '(run-cygwin-console shell-on-cygwin cygpath))

(defvar *cygwin-root* "C:/cygwin/")

;;; shellの切り替え
;;; /etc/profile の cd "${HOME}" 周辺をコメントアウトする
;;; ただし bash --login では制御文字を処理できない
;; (setq *eshell* "bash --login -i")  ;; デフォルトはcmd.exe
(defun run-cygwin-console (&optional login)
  (interactive "P")
  (if login
      (launch-application "cmd /c env CHERE_INVOKING=yes bash --login -i")
    (launch-application (cygpath "/bin/bash -i"))))

(defun shell-on-cygwin ()
  "xyzzy のバッファから bash を操作します。"
  (interactive)
  (set-buffer (get-buffer-create "*Bash*"))
  (let ((*eshell* "bash -i")
	(proc (buffer-process (selected-buffer))))
    (and proc (eq (process-status proc) :run)
	 (return-from shell-on-cygwin t))
    (goto-char (point-max))
    (ed::shell-mode)
    (make-process *eshell*
		  :output (selected-buffer)
		  :environ '(("PS1" . "[\\u@\\h:\\w]\\n\\$ "))
		  ;;:incode
		  :eol-code *eol-guess*
		  )
    ))

;;; UN*X のマニュアルを見る
;;; 参考: "C:/home/emacs/22.1/lisp/man.el"
;;; "LANG=C; man man|[col -b |colcrt]" を使う方法もある
;;; TODO:
;;; * 日本語MANも見たい (cygwinの問題?)
;;; * 下線、太線の強調
;;; * manual-mode (view-mode, less-mode)
;;; (set-text-attribute FROM TO TAG :bold t :underline t)
;; '(1.ユーザ用コマンド 2.システムコール 3.ライブラリ関数 4.デバイスファイル
;;   5.各種設定ファイル 6.ゲームプログラム 7.習慣等の説明 8.管理者用コマンド)
;; (export 'man-page)
(defun man-page (str &optional section)
  "cygwin のマニュアルを参照します."
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
	      (call-process (format nil "~A ~A" (cygpath "/bin/man.exe") str)
			    :environ '(("LANG" . "C"))
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

;; make-process 版 man-page
(export 'manual-entry)
(defun manual-entry (str &optional section)
  ;; (interactive "sManual entry: ")
  (interactive (list (read-manual-entry "Manual entry: ") *prefix-value*))
  (if section (setq str (format nil "~D ~A" section str)))
  (let* ((tmpbuf (create-new-buffer " *Man temp*"))
         (proc (make-process (format nil "man ~A" str)
                             :output tmpbuf
                             :environ '(("LANG" . "C")))))
    (message "Invoking man ~A in the background" str)
    (set-process-sentinel proc
                          ;; この関数内でエラーを投げると正常に機能しない？
                          ;; エラーキャッチはできるんだが、音と表示が出ない
                          #'(lambda (pid)
                              (declare (ignore pid))
                              (labels ((trim-buffer (regexp)
                                         (save-excursion
                                           (goto-char (point-min))
                                           (replace-buffer regexp "" :regexp t))))
                                (unwind-protect
                                    (progn
                                      (with-input-from-buffer (tmpbuf)
                                        (let ((res (read-line *standard-input*)))
                                          (when (string-match "^\\(No\\|What\\)" res)
                                            (message! res)
                                            (error res))))
                                      (with-output-to-temp-buffer ((format nil "*Man ~A*" str) t)
                                        (insert-buffer tmpbuf)
                                        (trim-buffer "_") ; 下線
                                        (trim-buffer ".") ; 太字
                                        (toggle-read-only t)
                                        (refresh-screen))
                                      (message "~A man page formatted" str))
                                  (delete-buffer tmpbuf)))))))

;; cygwin-mount.l参照しようか
;; http://cygwin.com/cygwin-ug-net/using-utils.html#cygpath
(defun cygpath (pathname &key (type :unix))
  "Convert Unix and Windows format paths, or output system path information."
  (case type
    (:dos (get-short-path-name pathname))
    (:mixed (map-backslash-to-slash (namestring pathname)))
    (:unix (cond ((string-match "^/" pathname)
                  (merge-pathnames (subseq pathname 1) *cygwin-root*))
                 (t pathname)))
    (:windows (map-slash-to-backslash (namestring pathname)))))

(defvar *manpath* '("/usr/local/man" "/usr/share/man" "/usr/man")
  "環境変数 MANPATH と大体同じ.")

(defvar *manual-list* nil)

;; C:/cygwin/etc/profile
;; MANPATH=/usr/local/man:/usr/share/man:/usr/man:$MANPATH
;; woman-topic-all-completions
;; woman-file-name-all-completions
(defun manual-completions ()
  (let ((*manpath* (mapcar #'cygpath *manpath*)))
    ;; (declare (speical *manpath*))
    (long-operation
      (message "Making manual list...")
      (setq *manual-list*
	    (delete-duplicates
	     (mapcan #'(lambda (x)
			 (mapcar #'(lambda (path)
				     ;; FIXME
				     (pathname-name (pathname-name path)))
				 (directory x :recursive t :file-only t
					    ;; "*.1.gz"
					    :wild '("*.1" "*.gz" "*.n" "*.n.gz"))))
		     *manpath*)
	     :test #'string-equal))
      (message "Making manul list..done"))
    *manual-list*))

(defun read-manual-entry (prompt &key default)
  (completing-read prompt
		   (or *manual-list*
		       (manual-completions))
		   :case-fold t
		   :default default
		   :must-match nil))

;;; cygwin.l ends here.
