# Android development template

Android用のプロジェクトテンプレートは [ashiba](https://github.com/yutakobayashidev/ashiba)
で管理する。dotnixはホスト設定を管理し、android-toolsを共通パッケージへ直接追加しない。

新しいプロジェクトのディレクトリで初期化する。

```bash
nix flake init -t github:yutakobayashidev/ashiba#android
git add flake.nix flake.lock registry android-dev.sh .maestro .envrc .gitignore AGENTS.md README.md
nix develop
```

用途別shell、Agent Skills、
ツールの固定と検証については [テンプレートのREADME](https://github.com/yutakobayashidev/ashiba/tree/main/android)
を参照。

ホスト側のデバイス権限は引き続きdotnixで管理する。パッケージ削除の実環境への適用は、
次回のHome Manager / システム反映時に行われる。
