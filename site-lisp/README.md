xyzzy用に自作したライブラリや設定ファイルを置いています。

## CommonLispから移植したものなど

* cl.l             - xyzzyにないCommonLisp関数群
* corman_search.l  - CommonLispのみで文字列検索
  ただし正規表現が使えるed:string-matchの方が明らかに便利
* dbind.l          - destructuring-bindが使えるように
  lisp/condition.l に若干修正が必要
  (See lisp/condition.diff <../lisp/condition.diff>)
  g000001さん移植のdestructuring-bind.lとほぼ同じ機能です <http://bit.ly/9SgwyN>
  違うのはマクロ展開時のS式くらい


## Emacsから移植したもの

* animate.l     - 文字列をアニメーション表示する
* cmacexp.l     - Cプログラムのマクロ定義を展開する
* regexp-opt.l  - 正規表現生成支援ツール
* zone.l        - ジョークプログラム


## 自作ライブラリ

* cygwin.l      - 今のところmanコマンドが使えるくらい
* newlisp.l     - newLISP編集用メジャーモード
  必要なファイル
  - ../etc/newLISP - キーワードファイル
  - http://github.com/kosh04/newlisp-files >> nelisp_manual.txt - マニュアルファイル
* newlispfn.l      - newLISPの関数の移植
* libmagic.l       - ファイル識別ライブラリ(file)
* emacs-help.l  - [F1]をヘルプキーとして扱う
* emacs-fn.l    - 自前のElisp関数、コマンド
* redef.l       - ~/lisp/*.l 以下の関数の再定義
* junk-lib.l    - その他小物

他にもあるかも


## 設定ファイル

- `init.l` - ここから
- `conf/NN-XXX.l` - 各種ライブラリの設定 (init-loader 風)


## 仕様

GitHubのWebページの文字コード(utf8)と各ファイルの文字コード(sjis)が異なるため、
ブラウザでの表示が化けて見えるかもしれません。

NetInstallerには対応していません。本人が使っていないので。
