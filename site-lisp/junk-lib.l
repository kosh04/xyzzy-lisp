;;; junk-lib.l --- �g�p�p�x�̍������C�u����

(defun execute-buffer-file (&optional buffer)
  "�ҏW���̃o�b�t�@���֘A�t����ꂽ�v���O�����ŊJ��."
  (interactive)
  (shell-execute (or (get-buffer-file-name buffer)
                     (error "�o�b�t�@��ۑ����Ă�������"))
                 t))

(defmacro with-set-directory (dir &body body)
  "�ꎞ�I��(DEFAULT-DIRECTORY)��DIR�ɐݒ肵��BODY�����s����."
  `(let ((#1=#:odir (default-directory))
         (#2=#:obuf (selected-buffer)))
     (unwind-protect
         (progn (set-default-directory ,dir #2#) ,@body)
       (set-default-directory #1# #2#))))
(setf (get 'with-set-directory 'lisp-indent-hook) 1)

;; tips/�t�@�C���̈Í���(Rijndael) ���
;; http://xyzzy.s53.xrea.com/wiki/index.php?cmd=read&page=tips%2F%A5%D5%A5%A1%A5%A4%A5%EB%A4%CE%B0%C5%B9%E6%B2%BD(Rijndael)
(defmacro with-temp-file ((temp-file &rest args) &body body)
  `(let ((,temp-file ,(apply #'make-temp-file-name args)))
     (unwind-protect
         (progn ,@body)
       (delete-file ,temp-file :if-does-not-exist :error :if-access-denied :error))))
(setf (get 'with-temp-file 'ed:lisp-indent-hook) 1)
;; (with-temp-file (dest) (truename dest)) => "C:/tmp/~xyzirtx.tmp"

(defun echo (input &optional output)
  "INPUT�X�g���[���̒��g��OUTPUT�ɗ���.
�f�t�H���g�̏o�͐��*standard-output*."
  #+NIL
  ;; 1�����P�ʂ͂������ɒx��
  (do ((c #1=(read-char input nil :eof) #1#))
      ((eq c :eof))
    (write-char c output))
  #+xyzzy
  (loop
    ;; �����̉��s���l������Ȃ�read-line�͑��l�łƂ�ׂ�
    (multiple-value-bind (line missing-newline-p)
        (read-line input nil :EOF)
      (when (eq line :EOF) (return))
      (princ line output)
      (unless missing-newline-p (terpri output)))))

(defun cat (file &optional stream (encoding :text))
  "print FILE contents to STREAM (default *standard-output*)."
  (with-open-file (fp file :direction :input)
    (set-stream-encoding fp encoding)
    (echo fp stream)))

(defun shell-command-to-string (command)
  "Execute shell command COMMAND and return its output as a string."
  (with-temp-file (outfile)
    (with-output-to-string (stream)
      (call-process command :output outfile :show :minimize :wait t)
      (cat outfile stream))))

(defun command-substitution (command)
  "�O���R�}���h�̌��ʂ𕶎���ɂ��ĕԂ��܂�."
  (string-right-trim '(#\SPC #\TAB #\LFD)
    (shell-command-to-string command)))

(defmacro with-syntax-table (table &body body)
  "BODY �����s����ۂɈꎞ�I�ɃV���^�b�N�X�e�[�u����ύX���܂�."
  ;; �o�b�t�@���ۑ�����ׂ��H
  `(let ((#1=#:syntab (syntax-table)))
     (unwind-protect
         (progn (use-syntax-table ,table) ,@body)
       (use-syntax-table #1#))))
(setf (get 'with-syntax-table 'ed:lisp-indent-hook) 1)

(defmacro with-lisp-syntax-table (&body body)
  `(with-syntax-table ed::*lisp-mode-syntax-table*
     ,@body))
(setf (get 'with-lisp-syntax-table 'lisp-indent-hook) 0)

(defun current-word (&optional highlight?)
  "�J�[�\���ʒu�ɂ���P���Ԃ��܂�."
  (save-excursion
    (let* ((syntax (if (standard-char-p (following-char))
                       "w_" "w_jk"))
           (from (progn
                   (skip-syntax-spec-backward syntax)
                   (point)))
           (to (progn
                 (skip-syntax-spec-forward syntax)
                 (point))))
      (unless (eql from to)
        (prog1
            (buffer-substring from to)
          (and highlight? (reverse-region from to t)))))))

;; arglist
(defun show-arglist (symbol)
  (interactive "SArglist: ")
  (when (fboundp symbol)
    (message "(~A ~{~A~^ ~})" symbol (arglist symbol))))

(defun arglist (x)
  "Return function argment list."
  (labels ((arglist-helper (x)
             (cond ((consp x)
                    (mapcar #'arglist-helper x))
                   ((and (symbolp x) (not (keywordp x)))
                    (first (multiple-value-list (intern (string x)))))
                   (t
                    x))))
    (arglist-helper (arglist-1 x))))

(defun arglist-1 (x)
  (let* ((fn (or (and (consp x) (eq (car x) 'macro) x)
                 (coerce x 'function)))
         (cl (and (si:*closurep fn) (si:closure-body fn))))
    (cond ((si:*builtin-function-p fn)
           (labels ((symbol-builtin-function-name-p (sym)
                      (and (fboundp sym)
                           (si:*builtin-function-p (symbol-function sym))
                           sym))
                    ;; #'subr-name (Emacs)
                    (builtin-function-name (f)
                      (when (string-match "#<function: \\(.+\\)>"
                                          (princ-to-string f))
                        (match-string 1))))
             (get (some #'symbol-builtin-function-name-p
                        (find-all-symbols (builtin-function-name fn)))
                  'si::builtin-function-argument)))
          ((eq (car cl) 'lambda)
           (cadr cl))
          ((eq (safe-car fn) 'macro)
           (cadr fn)))))

(defun buffer-list-if (fn)
  "FN�𖞂����o�b�t�@�̃��X�g��Ԃ��܂�."
  (remove-if-not fn (buffer-list)))

(defun process-list ()
  "�o�b�t�@�v���Z�X�̃��X�g."
  (mapcar #'buffer-process
          (buffer-list-if #'buffer-process)))

(defun running-process-exist-p ()
  "���쒆�̃v���Z�X�����邩."
  (some #'(lambda (pid)
            (eq (process-status pid) :run))
        (process-list)))

;; (remove-if-not #'need-buffer-save-p (buffer-list))
(defun modified-buffer-exist-p ()
  "�ۑ�����K�v�̂���o�b�t�@�����邩."
  (/= (count-modified-buffers) 0))

(defun delete-dump-and-compile-siteinit ()
  (delete-file (si:dump-image-path) :if-does-not-exist :skip)
  (let ((siteinit (find-load-path "siteinit")))
    (when (and siteinit (string-match "\\.lc$" siteinit))
      ;; *.lc �����݂��� *.l �����݂��Ȃ��Ȃ�ĉ\��������񂾂�
      (trap-errors (compile-file (substring siteinit 0 -1))))))

;; ���ϐ��̕ύX�����f����Ȃ��̂͂��傤���Ȃ��̂�
;; [����]
;; (kill-xyzzy)���鎞��yes-no-or-cancel-p/yes-or-no-p�Ɉ���������ƃC���ɂȂ�
;; [�֘A�������] �o�b�t�@�v���Z�X�A�ۑ��A�r������
;; (need-buffer-save-p buf) (verify-buffers-file-modtime) (buffer-modified-p &optional buf)
;; *kill-xyzzy-hook*�Ɏ��Ԃ�������Ƃ܂������� -> ��Ɏ��s�����Ă�����
(defun reboot-xyzzy (&optional cleanup)
  "xyzzy���ċN������."
  (interactive "P")
  ;; (save-some-buffers)
  (cond ((and *query-kill-xyzzy-hook*
              (null (run-hook-with-args-while-success '*query-kill-xyzzy-hook*)))
         (return-from reboot-xyzzy))
        ((modified-buffer-exist-p) (error "�ۑ������悤�A�ȁI"))
        ((running-process-exist-p)
         (or (yes-no-or-cancel-p "�T�u�v���Z�X��S���E���čċN�����܂���?")
             (return-from reboot-xyzzy))
         (mapcar #'kill-process (process-list))
         (sleep-for 1.0))
        (:else nil))
  (when cleanup
    (delete-dump-and-compile-siteinit))
  (run-hooks '*kill-xyzzy-hook*)
  (let ((*kill-xyzzy-hook* nil)
        (*query-kill-xyzzy-hook* nil))
    (and (call-process (merge-pathnames "xyzzy.exe" (si:system-root))
                       ;; ���ϐ��̐ݒ�
                       :environ `(("XYZZYHOME" . ,(or (si:getenv "XYZZYHOME")
                                                      (map-slash-to-backslash
                                                       (remove-trail-slash
                                                        (si:system-root)))))
                                  ;; �ݒ�t�@�C�� (xyzzy.ini��) �̃f�B���N�g��
                                  ("XYZZYCONFIGPATH" . ,(or (si:getenv "XYZZYCONFIGPATH")
                                                            (user-config-path))))
                       :no-std-handles t
                       :exec-directory (si:system-root)
                       :show t
                       :wait nil)
         (kill-xyzzy))))

(setf (symbol-function 'restart-xyzzy) #'reboot-xyzzy)

(defun point-of (fn &rest args)
  "�֐�FN���Ăяo������̃|�C���g�ʒu��Ԃ�."
  (save-excursion (apply fn args) (point)))
;; (point-of #'goto-bol)

(defun map-internal-to-binary (input-string-or-stream &optional output-stream)
  (convert-encoding-to-internal *encoding-binary*
                                input-string-or-stream
                                output-stream))
(setf (symbol-function 'binary-string) #'map-internal-to-binary)

(setf (symbol-function 'hash->list) #'make-list-from-keyword-table)

(defun sha1-file (pathspec)
  (with-open-file (s pathspec :encoding :binary)
    (si:sha-1 s)))

(defun md5-file (pathspec)
  (with-open-file (s pathspec :encoding :binary)
    (si:md5 s)))