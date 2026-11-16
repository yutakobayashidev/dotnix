# DIY development template

共通development profileのArduino IDE・FreeCAD・KiCadと、macOS desktopの
Arduino IDEを `templates/diy` へ移した。ホストには直接インストールせず、
プロジェクトごとに必要な機能を選ぶ。

公開後、新しいプロジェクトで初期化する。

```bash
nix flake init -t github:yutakobayashidev/dotnix#diy
git add flake.nix flake.lock nix skills .envrc .gitignore AGENTS.md README.md
nix develop
```

未公開のローカル変更は、空のプロジェクトディレクトリで試せる。

```bash
nix flake init -t path:/home/yuta/ghq/github.com/yutakobayashidev/dotnix#diy
nix develop .#cad
```

用途別shell、依存の固定、デバイス権限、Agent Skillsの配備については
[テンプレートのREADME](../templates/diy/README.md)を参照。

既存のホスト設定からのパッケージ削除は、次回のHome Manager / システム反映時に
適用される。シリアル権限・udevルールはホスト側に残し、必要なものだけ設定する。
