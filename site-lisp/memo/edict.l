;;; memo/edict.l

;; �p�a (C-c e)
(lookup-dictionary *edict-dictionary-path* "xyzzydic" "xyzzye2j" "go")
;;=> ("1.?�ɐi�s����,�s��,�����ɍs��,����,�߂���,����,�y��,2.?�Ə����Ă���")

;; �a�p (C-c j)
(lookup-dictionary *edict-dictionary-path* "xyzzydic" "xyzzyj2e" "ം�")
;;=> ("v5k,vi) (uk) to clamour" "to crowd" "to jostle")

;; �n��A�C�f�B�I�� (C-c i)
(lookup-dictionary *edict-dictionary-path* "xyzzydic" "xyzzyidi" "lookup")
;;=> ("adj-pn) reverse lookup (e.g. dictionary, address resolution, etc." "adj-pn) reverse lookup (e.g. dictionary, address resolution, etc." "n) lookup, e.g., in a dictionary, address list, etc." "n) lookup, e.g., in a dictionary, address list, etc.")

;; �ǂ݉��� (C-c r)
(lookup-dictionary *edict-dictionary-path* "xyzzydic" "xyzzyjrd" "ം�")
;;=> ("�Ђ��߂�")

;; �p���Y�𓱓�����ƌ�b��������̂ŃI�X�X��

;; lisp
("{������}�k�s���S�Ȕ����Łl�㑫�炸�ɘb��"
 "{��-1}�k�q�ǂ��Ȃǂ́l�㑫�炸�Șb����"
 "{��-2}�s����w�t���C���o������ ����p�ُ̈픭���o�����傤 �͂���p��s��z��th�Ɣ�������邱�ƁB"
 "{��-3}�k�����m�o�Ԃ� �ǂ����p�́l�_�炩���C��鉹"
 "{��}��list processing���s�R�t���X�g�v���Z�b�V���O��1958�N�Ƀ}�T�`���[�Z�b�c�H�ȑ�w(MIT)��John McCarthy�����𒆐S�Ƃ��錤���O���[�v�ɂ���ĊJ�����ꂽ�v���O���~���O����B")

;; xyzzy
("{��-1}�s�R�t�����o���߂��p�̂��߂Ɏg���ˋ�o�������p�̖��O�o�Ȃ܂��p�̈�������́A1�������ǂ񂾁u�G�b�N�X�E���C�E�Y�B�Y�B�[�v�A�܂��́u�Y�B�Y�B�[�v"
 "{��-2}�s�R�tWindows��œ���o�ǂ����p����t���[��Emacs���G�f�B�^")