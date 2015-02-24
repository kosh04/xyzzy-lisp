;; conf.isearch.l

(require "isearch")

#+NIL
(define-key *isearch-map* #\LBtnDown 'isearch-exit) ; �����Ȃ�

;; ���[�}���̂܂ܓ��{�����������
;; ** isearch.l ���㏑������
;; http://www7a.biglobe.ne.jp/~hat/xyzzy/migemo.html
(require "migemo")
(setq *migemo-dict-file* (namestring "~/dict/migemo-dict"))
;; [C-c m t]
(migemo-toggle t)

;; http://white.s151.xrea.com/wiki/index.php?cmd=read&page=script%2Figsearch
(require "igsearch")
(setq *igsearch-attribute* '(:background 2 :bold t))
#+NIL
(setf *igsearch-init-state* :migemo)     ; migemo ����n�߂�
(setf *igsearch-grep* nil)      ; ����o�b�t�@���̑S����