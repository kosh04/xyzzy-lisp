Takt-mode for xyzzy
-------------------

�e�L�X�g�`���̉��y�v���O���~���O���� Takt �̕ҏW�p���[�h�ł��B

�z�z����Ă��� Takt �p�b�P�[�W�Ɋ܂܂�Ă��� Emacs �p���[�h `takt-mode.el` ��
���슴 �� xyzzy �ł�������悤�ɂȂ�܂��B

## �@�\

- �֐�/�}�N��/�I�u�W�F�N�g���L�[���[�h�̐F�t��
- Takt �t�@�C���̃n�C���C�g�t���Đ�

## �t�@�C��

- `takt-mode.l` : Takt �ҏW�p���[�h
- `takt-play.l` : Takt ���t�p
- `takt-track-mode.l` : takt-track-mode �p
- `Takt.kwd` : �ҏW�p�L�[���[�h�t�@�C��

## �C���X�g�[��

��L�̃t�@�C���� `*load-path*` �̒ʂ����ꏊ�ɒu���� .xyzzy �Ɉ�s�����Ă��������B

	(require 'takt-mode)

## �R�}���h

- <kbd>C-c f</kbd> `takt:play-this` : ���݂� Takt �o�b�t�@���Đ����܂�
- <kbd>C-c q</kbd> `takt:stop` : ���t���� Takt �o�b�t�@���~���܂�
- <kbd>C-c i</kbd> `takt:show-interp-console` : �R���\�[���o�b�t�@��\�����܂� (�f�o�b�O�p)
- <kbd>C-c t</kbd> `takt-show-track-summary` : �g���b�N���� `*takt-track*` �ɕ\�����܂�

## �ł��Ȃ����� (TODO)

`takt-mode.el` �Ɣ�r���Ă̂��b

- �X�e�b�v�Đ� `takt-step-record`
- �\���Đ� `takt-track-solo`
- �~���[�g�w�� `takt-track-set-mute`
- takt-track-mode �S�ʂ̃R�}���h��������
- �ҏW���[�h������ڂ�

## ���m�̃o�O

- �s���̒��� Takt �t�@�C���ł͕����g���b�N�Đ����ɃJ�[�\�����r�Ԃ�
- �g���b�N��A�����čĐ�����ƃn�C���C�g�̐F���ω�����

## �����N

- [Takt | Text-based Music Programming Tools](http://takt.sourceforge.net/?lang=ja)
