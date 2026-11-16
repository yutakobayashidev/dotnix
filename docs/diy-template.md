# DIY development template

DIY用のプロジェクトテンプレートは [ashiba](https://github.com/yutakobayashidev/ashiba)
で管理する。dotnixはホスト設定を管理し、Arduino IDE・FreeCAD・KiCadを共通パッケージへ直接追加しない。

新しいプロジェクトのディレクトリで初期化する。

```bash
nix flake init -t github:yutakobayashidev/ashiba#diy
git add flake.nix flake.lock nix skills .envrc .gitignore AGENTS.md README.md
nix develop
```

用途別shell、Agent Skills、
ツールの固定と検証については [テンプレートのREADME](https://github.com/yutakobayashidev/ashiba/tree/main/diy)
を参照。

ホスト側のデバイス権限は引き続きdotnixで管理する。パッケージ削除の実環境への適用は、
次回のHome Manager / システム反映時に行われる。
