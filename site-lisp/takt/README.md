Takt-mode for xyzzy
-------------------

テキスト形式の音楽プログラミング言語 Takt の編集用モードです。

配布されている Takt パッケージに含まれている Emacs 用モード `takt-mode.el` の
操作感 を xyzzy でも扱えるようになります。

## 機能

- 関数/マクロ/オブジェクト等キーワードの色付け
- Takt ファイルのハイライト付き再生

## ファイル

- `takt-mode.l` : Takt 編集用モード
- `takt-play.l` : Takt 演奏用
- `takt-track-mode.l` : takt-track-mode 用
- `Takt.kwd` : 編集用キーワードファイル

## インストール

上記のファイルを `*load-path*` の通った場所に置いて .xyzzy に一行加えてください。

	(require 'takt-mode)

## コマンド

- <kbd>C-c f</kbd> `takt:play-this` : 現在の Takt バッファを再生します
- <kbd>C-c q</kbd> `takt:stop` : 演奏中の Takt バッファを停止します
- <kbd>C-c i</kbd> `takt:show-interp-console` : コンソールバッファを表示します (デバッグ用)
- <kbd>C-c t</kbd> `takt-show-track-summary` : トラック情報を `*takt-track*` に表示します

## できないこと (TODO)

`takt-mode.el` と比較してのお話

- ステップ再生 `takt-step-record`
- ソロ再生 `takt-track-solo`
- ミュート指定 `takt-track-set-mute`
- takt-track-mode 全般のコマンドが未実装
- 編集モードがしょぼい

## 既知のバグ

- 行数の長い Takt ファイルでは複数トラック再生時にカーソルが荒ぶる
- トラックを連続して再生するとハイライトの色が変化する

## リンク

- [Takt | Text-based Music Programming Tools](http://takt.sourceforge.net/?lang=ja)
