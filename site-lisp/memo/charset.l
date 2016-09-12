;;; memo/charset --- 文字コード

;; &nbsp; (U+00A0)
(unicode-char #x00a0)           ;=> #\x0120
(char-name #\x0120)             ;=> "no_break_space"

(char-code    #\x0120)          ;=> 288
(char-unicode #\x0120)          ;=> 160

;; no-BMP (U+10000..U+10FFFF) はどう扱う？ 特に絵文字

;; U+1F363 is SUSHI
(unicode-char #x1f363)          ;;=> "\Xd83c\Xdf63"
(concat (list #\XD83C #\XDF63))

