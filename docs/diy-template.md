# Hardware development templates

ハードウェア関連の開発環境は [ashiba](https://github.com/yutakobayashidev/ashiba) で用途別に管理する。
dotnixにはホスト設定を残し、Arduino IDE・FreeCAD・KiCadを共通パッケージへ直接追加しない。

| テンプレート                                                              | 用途                                          |
| ------------------------------------------------------------------------- | --------------------------------------------- |
| [firmware](https://github.com/yutakobayashidev/ashiba/tree/main/firmware) | Arduino CLI・PlatformIO。IDEは追加shellで利用 |
| [cad](https://github.com/yutakobayashidev/ashiba/tree/main/cad)           | FreeCAD・OpenSCADによる形状設計               |
| [pcb](https://github.com/yutakobayashidev/ashiba/tree/main/pcb)           | KiCadによる回路図・基板設計（Linux）          |
| [printing](https://github.com/yutakobayashidev/ashiba/tree/main/printing) | PrusaSlicerによるスライス・印刷準備           |

新しいプロジェクトで用途を選んで初期化する。例えばファームウェア開発の場合：

```bash
nix flake init -t github:yutakobayashidev/ashiba#firmware
git add flake.nix flake.lock skills .envrc .gitignore AGENTS.md README.md
nix develop
```

各テンプレートはflake-partsを使い、設定を単一のflake.nixにまとめている。
用途をまたぐプロジェクトは、初期化後のshellへ必要なパッケージを追加する。
Skills配布・ツールの固定・検証手順は各READMEを参照。

ホスト側のデバイス権限は引き続きdotnixで管理する。パッケージ削除の実環境への適用は、
次回のHome Manager / システム反映時に行われる。
