# Mobile development template

Androidの開発・解析ツールはホストの共通パッケージから分離し、
`templates/mobile` の開発shellで提供する。

公開後は、新規プロジェクトのディレクトリで初期化する。

```bash
nix flake init -t github:yutakobayashidev/dotnix#mobile
git add flake.nix flake.lock nix scripts registry .envrc .gitignore AGENTS.md README.md
nix develop
mobile doctor
```

未公開のローカル変更は、空ディレクトリで次のように試せる。

```bash
nix flake init -t path:/home/yuta/ghq/github.com/yutakobayashidev/dotnix#mobile
nix develop
```

独立したflakeとソースロックをコピーするため、作成したプロジェクトはdotnixの
ホスト設定に依存しない。Android CLI・SDK・JDKを固定し、公式Android Skillsは
agent-skills-nixでプロジェクト内へ配備する。

実行手順と構成の変更方法は [テンプレートのREADME](../templates/mobile/README.md) を参照。
ホスト側にはKVMとUSB権限を残す。`android-tools` の共通profile / X870への直接追加は
削除した。実行中のホストからの削除は次回のHome Manager / システム反映時に行われる。
