;; conf.isearch.l

(require "isearch")

#+NIL
(define-key *isearch-map* #\LBtnDown 'isearch-exit) ; 動かない

;; ローマ字のまま日本語を検索する
;; ** isearch.l を上書きする
;; http://www7a.biglobe.ne.jp/~hat/xyzzy/migemo.html
(require "migemo")
(setq *migemo-dict-file* (namestring "~/dict/migemo-dict"))
;; [C-c m t]
(migemo-toggle t)

;; http://white.s151.xrea.com/wiki/index.php?cmd=read&page=script%2Figsearch
(require "igsearch")
(setq *igsearch-attribute* '(:background 2 :bold t))
#+NIL
(setf *igsearch-init-state* :migemo)     ; migemo から始める
(setf *igsearch-grep* nil)      ; 同一バッファ内の全候補列挙
