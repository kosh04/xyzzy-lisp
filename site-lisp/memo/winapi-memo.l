;;; -*- Mode: lisp-interaction; Package: user -*-
;;;
;;; xyzzy winapi を使うものメモ

;; winapi 略記
(defun hwnd () (get-window-handle))
(defun TEXT (str) (si:make-string-chunk str))
(c:*define NULL 0)

;;; 確か"xyzzyの音"から
(defun get-logical-drives()
  "論理ドライブの取得"
  (unless (fboundp 'GetLogicalDrives)
    (c:define-dll-entry winapi:LONG GetLogicalDrives nil "kernel32"))
  (let ((drives nil)
	(offset 25)
	(drive-bits (GetLogicalDrives)))
    (while (>= offset 0)
      (if (logbitp offset drive-bits)
	  (setf drives (cons (concat (string (code-char (+ 65 offset))) ":/")
			     drives)))
      (setf offset (1- offset)))
    drives))
(get-logical-drives)		; ("C:/" "D:/" "E:/" "F:/" "G:/")

(c:*define-dll-entry winapi:LONG GetLogicalDrives nil "kernel32")
(format nil "~B" (GetLogicalDrives))
; "1111100"
;  GFEDCBA [Drive]

(mapcan #'(lambda (x y)
            (unless (zerop x) (list y)))
        (map 'list #'digit-char-p (reverse "1111100"))      ; (0   0   1   1   1   1   1)
        (map 'list #'identity "ABCDEFGHIJKLMNOPQRSTUVWXYZ") ; (#\A #\B #\C #\D #\E #\F #\G #\H #\I #\J #\K #\L #\M #\N #\O #\P #\Q #\R #\S #\T #\U #\V #\W #\X #\Y #\Z)
        )                       ; (#\C #\D #\E #\F #\G)

;; ショートパスを元のパスに戻す
;; http://d.hatena.ne.jp/miyamuko/20050912/p1
(c:define-dll-entry winapi::DWORD GetLongPathName
  (winapi::LPCSTR winapi::LPCSTR winapi::DWORD)
  "kernel32" "GetLongPathNameA")
(defun get-long-path-name (short-path)
  (let ((buf (si:make-chunk nil 512)))
    (GetLongPathName (si:make-string-chunk short-path) buf 512)
    (si:unpack-string buf 0)))
(get-short-path-name "~/.xyzzy")                      ; "C:/home/xyzzy/XYZZY~1"
(get-long-path-name (get-short-path-name "~/.xyzzy")) ; "C:/home/xyzzy/.xyzzy"

(defun get-short-path-name_ (pathname)
  (unless (fboundp 'GetShortPathName)
    (c:define-dll-entry DWORD GetShortPathName (LPCSTR LPSTR DWORD)
      "kernel32.dll" "GetShortPathNameA"))
  (let* ((buf (si:make-chunk nil 512)))
    (GetShortPathName (si:make-string-chunk pathname) buf 512)
    (si:unpack-string buf 0)))
(get-short-path-name_ (merge-pathnames "newlisp/init.lsp" (si:getenv "programfiles")))
;; =>"C:/PROGRA~1/newlisp/init.lsp"

;; タイトルバーの文字取得
(c:*define-dll-entry c:int GetWindowText (winapi:HWND winapi:LPSTR c:int)
  "user32" "GetWindowTextA")
(defun GetWindowText_ (hwnd &optional (size 1000))
  (let ((c (si:make-chunk nil size)))
	(GetWindowText hwnd c size)
	(si:unpack-string c 0)))
(GetWindowText_ (get-window-handle)) ; "*scratch* - xyzzy 0.2.2.235@YOUR-D1BE424ADF"

;; 最大化する
(require "api")
(winapi::SendMessage
 ;; xyzzy のクラス名は "　" （全角スペース）
 (winapi::FindWindow (si:make-string-chunk "　") 0)
 winapi::WM_SYSCOMMAND		; #x0112
 winapi::SC_MAXIMIZE		; #xF030
 0)

(defun get-window-handle (&optional window)
  (declare (ignoable window))
  (FindWindow (si:make-string-chunk "　") 0))

;; リファレンスのハンドラ
(FindWindow (TEXT "HH Parent") (TEXT "xyzzy Reference"))
;; Editコントロールを取得したいのだがクラス名が "HH Child"
;; となる子ウィンドウが複数あるらしくて見つけ方が分からない
(FindWindowEx (FindWindowEx (FindWindow (TEXT "HH Parent") (TEXT "xyzzy Reference"))
			    0 (TEXT "HH Child") (TEXT ""))
	      0 (TEXT "Edit") (TEXT "")) ; 0

;;; 起動中のプロセスを列挙
;;; xyzzy Part9 >>633
;;; http://www.bookshelf.jp/2ch/win/1053880433.html#633
(require "foreign")
(c:define-dll-entry :int32 EnumProcesses (:int32 :int32 :int32) "psapi.dll")
(c:define-dll-entry :int32 OpenProcess (:int32 :int32 :int32) "kernel32.dll")
(c:define-dll-entry :int32 CloseHandle (:int32) "kernel32.dll")
(c:define-dll-entry :int32 EnumProcessModules (:int32 :int32 :int32 :int32) "psapi.dll")
(c:define-dll-entry :int32 GetModuleBaseName (:int32 :int32 :int32 :int32)
  "psapi.dll" "GetModuleBaseNameA")
(defun list-process-base-name ()
  (let ((procid (si:make-chunk nil 4096))
	(hmod (si:make-chunk nil 4))
	(needed (si:make-chunk nil 4))
	(name (si:make-chunk nil 256))
	(result nil))
    (EnumProcesses procid 4096 needed)
    (dotimes (i (/ (si:unpack-int32 needed 0) 4) result)
      (let ((hproc (OpenProcess #x0410 0 (si:unpack-int32 procid (* i 4)))))
	(unless (zerop hproc)
	  (EnumProcessModules hproc hmod 4 needed)
	  (unless (zerop (GetModuleBaseName hproc (si:unpack-int32 hmod 0) name 256))
	    (push (si:unpack-string name 0 256 t) result))
	  (CloseHandle hproc))))))
(list-process-base-name)
;; ("xyzzy.exe" "conime.exe" "MemCleaner.exe" "ZTop.exe" "ytclock.exe" "TPTray.exe" "PROCEXP.EXE" "Apntex.exe" "ImeWatch.exe" "firefox.exe" "orchis.exe" "KPFW32.EXE" "ctfmon.exe" "KAVStart.exe" "TvsTray.exe" "Apoint.exe" "igfxpers.exe" "hkcmd.exe" "Explorer.EXE" "StarWindServiceAE.exe" "KMailMon.EXE" "KISSvc.EXE" "DVDRAMSV.exe" "cvpnd.exe" "CFSvcs.exe" "spoolsv.exe" "KWatch.EXE" "KPfwSvc.EXE" "ACS.exe" "svchost.exe" "svchost.exe" "lsass.exe" "services.exe" "winlogon.exe" "smss.exe")

;;; xyzzy Part5 >>502
(c:define-dll-entry winapi:LONG GetWindowLong (winapi:HWND c:int)
  "user32" "GetWindowLongA")
(c:define-dll-entry winapi:LONG SetWindowLong (winapi:HWND c:int winapi:LONG)
  "user32" "SetWindowLongA")
(c:define-dll-entry winapi:LONG
  SetLayeredWindowAttributes (winapi:HWND winapi:DWORD winapi:BYTE winapi:DWORD)
  "user32")
(c:*define GWL_EXSTYLE -20)
(defun set-alpha (rate)
  "lisp だけで透明化してみる。"
  (let ((ex-style (GetWindowLong (get-window-handle) GWL_EXSTYLE)))
    (SetWindowLong (get-window-handle) GWL_EXSTYLE (logior ex-style #x80000))
    (SetLayeredWindowAttributes (get-window-handle) 0 rate 2)))
(set-alpha 200)

(c:define-dll-entry winapi:BOOL IsZoomed (winapi:HWND) "user32")
(defun zoomp (&optional (hwnd (get-window-handle)))
  "ウィンドウが最大化されているかどうか判別する."
  (not (zerop (IsZoomed hwnd))))

(c:define-dll-entry c:int MessageBox
  (winapi:HWND winapi:LPSTR winapi:LPCSTR winapi:UINT)
  "user32" "MessageBoxA")
(let ((NULL 0)
      (s (si:make-string-chunk "ぬるぽ"))
      (r (si:make-string-chunk "3ch"))
      (MB_OK #x00)
      (MB_ICONEXCLAMATION #x30)
      (MB_ICONINFORMATION #x40))
  (MessageBox NULL s r (logior MB_OK MB_ICONINFORMATION)))

;; 壁紙変更
(funcall (or (and (fboundp 'SetDeskWallpaper)
		  #'SetDeskWallpaper)
	     (c:define-dll-entry winapi:BOOL
	       SetDeskWallpaper (winapi:LPCSTR) "user32"))
	 (si:make-string-chunk
	  "C:/home/MyPicture/wallpaper/miku_oto_01_01.bmp")) ; 1

(c:define-dll-entry c:short GetKeyState (c:int) "user32")

(c:*define-dll-entry winapi:HWND FindWindowEx
  (winapi:DWORD winapi:DWORD winapi::LPCSTR winapi::LPCSTR)
  "user32" "FindWindowExA")
(defun get-statusbar-handle ()
  "ステータスバーのハンドル"
  (winapi:FindWindowEx (get-window-handle) 0
		       (si:make-string-chunk "msctls_statusbar32") 0))

;;; XXXをYYYで開く
(ShellExecute 0 0 (si:make-string-chunk "notepad.exe")
	      (si:make-string-chunk "C:/home/xyzzy/.xyzzy")
	      0 SW_SHOWNORMAL)
;;; 関連付けられたプログラムで開く
(ShellExecute 0 (si:make-string-chunk "open")
	      (si:make-string-chunk "http://www.sm.rim.or.jp/~shishido/shelle.html")
	      0 0 SW_SHOWNORMAL)

(defun mouse-avoidance-mode ()
  ;; ウィンドウ上にカーソルが乗っているか
  (when (let ((cp (make-POINT)))
	  (GetCursorPos cp)
	  (let ((x (POINT-x cp))
		(y (POINT-y cp))
		(wr (make-RECT)))
	    (GetWindowRect (get-window-handle) wr)
	    (and (<= (RECT-left wr) x (RECT-right wr))
		 (<= (RECT-top wr) y (RECT-bottom wr)))))
    ;; カーソルを右上に
    (let ((wr (make-RECT)))
      (GetWindowRect (get-window-handle (selected-window)) wr)
      (SetCursorPos (- (RECT-right wr) 20) (RECT-top wr)))))
;; マウススクロールと共存できないので注意
(add-hook '*post-command-hook* 'mouse-avoidance-mode)
(delete-hook '*post-command-hook* 'mouse-avoidance-mode)

(list (GetSystemMetrics SM_CXSCREEN)
      (GetSystemMetrics SM_CYSCREEN)) ; (1024 768)

(c:*define-dll-entry DWORD GetShortPathName (LPCSTR LPCSTR DWORD)
  "kernel32.dll" "GetShortPathNameA")
(let ((s (si:make-chunk nil 300)))
  (GetShortPathName (TEXT "C:/Program Files/newlisp/newlisp.exe") s 300)
  (si:unpack-string s 0))       ; "C:/PROGRA~1/newlisp/newlisp.exe"

;; http://d.hatena.ne.jp/miyamuko/20050912
(c:*define-dll-entry DWORD GetLongPathName (LPCSTR LPCSTR DWORD)
  "kernel32" "GetLongPathNameA")
(defun get-long-path-name (pathname)
  #+xyzzy (let ((buf (si:make-chunk nil 512)))
	    (GetLongPathName (si:make-string-chunk pathname) buf 512)
	    (si:unpack-string buf 0))
  #+common-lisp (truename pathname))

;; 正しくは (LPCSTR DWORD LPTSTR LPTSTR)
(c:*define-dll-entry DWORD GetFullPathName (LPCSTR DWORD LPSTR LPSTR)
  "kernel32.dll" "GetFullPathNameA")
(let ((buf (si:make-chunk nil 512)))
  (GetFullPathName (TEXT "memo.l") 512 buf NULL)
  (si:unpack-string buf 0))     ; "C:\\home\\xyzzy\\memo.l"

(c:define-dll-entry BOOL MessageBeep (UINT) "user32.dll")

(defun beep (&optional (type :ok))
  (MessageBeep (case type
                 (:ok #x00)
                 (:hand #x10)
                 (:question #x20)
                 (:exclamation #x30)
                 (:asterisk #x40)
                 (t -1))))
(beep :exclamation)

;; http://miyamuko.s56.xrea.com/xyzzy/sound.html
;; PlaySound API の wrapper

(defun play-sound-file (wavfile)
  (or (fboundp 'PlaySound)
      (c:define-dll-entry BOOL PlaySound (LPCSTR HMODULE DWORD) "Winmm.dll"))
  (let ((SND_SYNC      #x0)
        (SND_ASYNC     #x1)
        (SND_NODEFAULT #x2)
        (SND_MEMORY    #x4)
        (SND_LOOP      #x8)
        (SND_NOSTOP    #x10)
        ;; (NULL          #x0)
        )
    (null (zerop (PlaySound (TEXT wavfile) NULL SND_ASYNC)))))
(play-sound-file "C:/home/MyMusic/misc/Win2K_on.wav")
(play-sound-file "Windows XP Startup.wav")
(play-sound-file "chimes")
(file-exist-p "C:/WINDOWS/Media/chimes.wav") ; t

#|
Direct execution mode --- newLISP Manual and Reference
Small pieces of newLISP code can be executed directly from the command-line:
$ newlisp -e "(+ 3 4)" -> 7
The expression enclosed in quotation marks is evaluated, and the result
is printed to standard out (STDOUT). In most Unix system shells, single
can also be used as command-line delimiters. Note that there is a space
between -e end the quoted command string.
|#

;; Private Declare Function LoadLibraryA Lib "kernel32" (ByVal s As String) As Long
(c:define-dll-entry HMODULE LoadLibrary (LPCSTR) "kernel32" "LoadLibraryA")
;; Private Declare Sub FreeLibrary Lib "kernel32" (ByVal h As Long)
(c:define-dll-entry BOOL FreeLibrary (HMODULE) "kernel32")
;; Declare Function lstrLen Lib "kernel32" Alias "lstrlenA" (ByVal lpString As Long) As Long
(c:define-dll-entry LONG lstrlenA (LONG) "kernel32")
;; Declare Function lstrCpy Lib "kernel32" Alias "lstrcpyA" (ByVal lpString1 As String, ByVal lpString2 As Long) As Long
(c:define-dll-entry LONG lstrcpyA (LONG) "kernel32")

(newlispEvalStr (TEXT "(+ 3 10)")) ; 90424968
"C:/PROGRA~1/newlisp/NEWLIS~1.LSP" ; newlisp-edit.lsp


;; BOOL SetEnvironmentVariable(
;;   LPCTSTR lpName,  // 環境変数の名前
;;   LPCTSTR lpValue  // 環境変数の新しい値
;; );
(c:*define-dll-entry BOOL SetEnvironmentVariable (LPCSTR LPCSTR)
  "kernel32" "SetEnvironmentVariableA")
(SetEnvironmentVariable (si:make-string-chunk "FOO")
                        (si:make-string-chunk "C:/home/xyzzy/"))

(c:*define-dll-entry c:int _putenv (c:char*) "msvcrt.dll")
(defun putenv (variable value)
  (zerop (_putenv (si:make-string-chunk (concat variable "=" value)))))
(putenv "FOO" "newLISP")        ; t
(si:getenv "FOO")               ; nil ?

;; 自動テスト用にコンソール出力が出来ると便利
(c:*define-c-type c:void* FILE)
(c:*define-dll-entry BOOL AllocConsole () "kernel32")
(c:*define-dll-entry FILE freopen (c:char* c:char* FILE) "msvcrt")
(AllocConsole)
;; stdin/stdout の値を調べる関数ある？
(freopen "CONIN$" "r+t" stdin)
(freopen "CONOUT$" "w+t" stdout)
(freopen "CONOUT$" "r+t" stderr)

(c:*define-dll-entry BOOL AttachConsole (DWORD) "kernel32")
(AttachConsole -1)
