;;; memo/edict.l

;; 英和 (C-c e)
(lookup-dictionary *edict-dictionary-path* "xyzzydic" "xyzzye2j" "go")
;;=> ("1.?に進行する,行く,をしに行く,動く,過ぎる,至る,及ぶ,2.?と書いてある")

;; 和英 (C-c j)
(lookup-dictionary *edict-dictionary-path* "xyzzydic" "xyzzyj2e" "犇く")
;;=> ("v5k,vi) (uk) to clamour" "to crowd" "to jostle")

;; 熟語、イディオム (C-c i)
(lookup-dictionary *edict-dictionary-path* "xyzzydic" "xyzzyidi" "lookup")
;;=> ("adj-pn) reverse lookup (e.g. dictionary, address resolution, etc." "adj-pn) reverse lookup (e.g. dictionary, address resolution, etc." "n) lookup, e.g., in a dictionary, address list, etc." "n) lookup, e.g., in a dictionary, address list, etc.")

;; 読み仮名 (C-c r)
(lookup-dictionary *edict-dictionary-path* "xyzzydic" "xyzzyjrd" "犇く")
;;=> ("ひしめく")

;; 英辞郎を導入すると語彙が増えるのでオススメ

;; lisp
("{自他動}〔不完全な発音で〕舌足らずに話す"
 "{名-1}〔子どもなどの〕舌足らずな話し方"
 "{名-2}《言語学》歯擦音｛しさつ おん｝の異常発音｛いじょう はつおん｝◆sやzがthと発声されること。"
 "{名-3}〔物同士｛ぶつ どうし｝の〕柔らかく擦れる音"
 "{略}＝list processing●《コ》リストプロセッシング◆1958年にマサチューセッツ工科大学(MIT)のJohn McCarthy教授を中心とする研究グループによって開発されたプログラミング言語。")

;; xyzzy
("{名-1}《コ》説明｛せつめい｝のために使う架空｛かくう｝の名前｛なまえ｝の一つ◆発音は、1文字ずつ読んだ「エックス・ワイ・ズィズィー」、または「ズィズィー」"
 "{名-2}《コ》Windows上で動作｛どうさ｝するフリーのEmacs風エディタ")
