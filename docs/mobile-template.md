# Android development template

Android用のプロジェクトテンプレートは [ashiba](https://github.com/yutakobayashidev/ashiba)
で管理する。dotnixはホスト設定を管理し、android-toolsを共通パッケージへ直接追加しない。

新しいプロジェクトのディレクトリで初期化する。

```bash
nix flake init -t github:yutakobayashidev/ashiba#android
git add flake.nix flake.lock .maestro .envrc .gitignore AGENTS.md README.md
nix develop
```

用途別shell、Agent Skills、
ツールの固定と検証については [テンプレートのREADME](https://github.com/yutakobayashidev/ashiba/tree/main/android)
を参照。

ホスト側のデバイス権限は引き続きdotnixで管理する。パッケージ削除の実環境への適用は、
次回のHome Manager / システム反映時に行われる。

APK解析だけなら `reverse-android` テンプレートを使う。SDKやエミュレータは取得せず、
JADX・Apktool・Frida・ADBと解析Skillを利用できる。
Androidの `analysis` shellは開発環境にこの解析moduleを加え、`full` shellはさらに
Ghidra CLIの `reverse-native` moduleを加える。Skillsはまとめて1回配布される。
ネイティブCTFでも `reverse-native` と必要なデバッガをプロジェクト内で組み合わせる。
