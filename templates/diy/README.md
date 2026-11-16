# DIY development

電子工作、CAD、基板設計、3Dプリントをプロジェクト単位で使うNix flake。
Linux x86_64とApple Silicon macOSを対象にします。`pcb`・`full`はLinux限定です。
固定中のnixpkgsのKiCadがDarwinでbroken指定のため、macOSには公開しません。

```bash
nix develop                   # Arduino CLI + PlatformIO
nix develop .#electronics     # 上記 + Arduino IDE
nix develop .#cad             # FreeCAD + OpenSCAD
nix develop .#pcb             # KiCad（安定版）
nix develop .#printing        # PrusaSlicer
nix develop .#full            # 全部
```

`default`はGUIツールを取得しません。各shellは必要なパッケージだけを取得します。
CLIを固定するのは `flake.lock`、ボード定義・SDK・ライブラリを固定するのは
Arduinoの `sketch.yaml` または PlatformIOの `platformio.ini` です。

## 組み合わせ

`nix/profiles.nix` に使う機能を列挙します。例えば筐体付きの電子工作なら：

```nix
enclosure = [ "firmware" "cad" ];
```

`nix develop .#enclosure` で入れます。機能ごとのパッケージは `nix/shell.nix`
にあります。LinuxのFreeCADは、元のdotnixと同じstable入力から取得します。
KiCadも元の `stable = true` を保持しています。

direnvの `.envrc` は初期状態では `default` を使います。用途を固定する場合は
`use flake .#cad` などへ変更し、`direnv allow` を実行してください。

## プロジェクトの保存場所

shellには常にプロジェクトルートから入ります。

| 保存場所                      | 用途                                        | Git管理 |
| ----------------------------- | ------------------------------------------- | ------- |
| `firmware/`                   | スケッチ、ソース、ボード・依存の設定        | する    |
| `cad/`                        | FreeCAD / OpenSCADの編集可能な原本          | する    |
| `pcb/`                        | KiCadプロジェクト、回路図、基板、ライブラリ | する    |
| `printing/`                   | 3MFプロジェクトやプリンタ・材料プロファイル | する    |
| `.diy/`、`build/`、`exports/` | SDKキャッシュ、ビルド・製造用出力           | しない  |

Arduino CLIのデータ・ダウンロード先とPlatformIO Coreの保存先は `.diy/` です。
Arduinoのユーザースケッチ領域は `firmware/arduino` を指します。必要な設計用
ディレクトリだけ作成してください。GUIのユーザー設定までは隔離しません。
Arduino IDEが既存設定を使う場合は、CLIの `config dump` と設定先を比較してください。

## 電子工作

```bash
arduino-cli version
arduino-cli config dump
arduino-cli board list
pio --version
```

NixOSではArduino CLI・PlatformIOにnixpkgsのFHSラッパーを使います。
ボード用のコンパイラを後から取得しても実行できる構成ですが、ユーザー名前空間を
禁止したコンテナではラッパーが起動できません。ホストのターミナルで実行してください。
macOSはネイティブCLIを使います。

ボードが決まったら、Arduinoの `sketch.yaml` にFQBN、coreとライブラリのバージョンを
記録し、`arduino-cli compile --profile <profile> <sketch-directory>` でビルドします。
PlatformIOの場合は `platformio.ini` にplatformの正確なバージョン、board、framework、
`lib_deps` を記録し、そのディレクトリで `pio run` を実行します。
初回のSDKや依存取得にはネット接続が必要です。

アップロード前に対象ポートを確認します。Linuxでは `/dev/serial/by-id/` が利用できる
場合はそれを優先します。shell起動時にアップロードやデバイス初期化は実行しません。

## GUIの起動

Linuxではshell内で `arduino-ide`、`FreeCAD`、`openscad`、`kicad`、`prusa-slicer`
を実行します。ウィンドウは既存のWayland / X11セッションへ表示します。
非NixOSのLinuxではホストのGPUドライバとの互換性を別途確認してください。

macOSのArduino IDE・FreeCAD・PrusaSlicerは、既存設定と同じbrew-nix方式のアプリをNix Storeへ
取得します。shellでは `/Applications` へリンクしないため、付属ランチャーを使います。

```bash
nix develop .#electronics --command diy-arduino-ide
nix develop .#cad --command diy-freecad
nix develop .#printing --command diy-prusa-slicer
```

macOSのOpenSCADはnixpkgsのパッケージを使います。cad shell内で `openscad` を実行します。

## Agent Skills

`agent-skills-nix` が `skills/diy-workflow/SKILL.md` を、shell起動時に
`.agents/skills`、`.codex/skills`、`.claude/skills`、`.opencode/skills` へ配備します。
Piは `.agents/skills` を共用します。Agentはshellへ入った後で起動してください。
生成先を編集せず、`skills/` の原本を編集します。このスキルはテンプレート付属で、
外部の公式スキルを名乗るものではありません。

## USB・シリアル権限

権限やudevルールはdev shellでは変更できません。NixOSで必要なホストにだけ設定します。

```nix
{ pkgs, ... }: {
  users.users.yuta.extraGroups = [ "dialout" ];
  services.udev.packages = [ pkgs.platformio-core.udev ];
}
```

ユーザー名は置き換え、反映後に再ログインします。既存のUSBルールやグループは維持します。
macOSではボードによってUSBシリアルドライバが別途必要です。

## 更新・検証

```bash
nix flake update
nix flake check
```

flake checkはshell定義とスキルの配備を検査します。ファームウェアのコンパイル、
実機への書き込み、CADの形状、KiCadのERC/DRC、スライス結果は各プロジェクトで確認します。
CAD / PCBのネイティブ形式を残し、STL・STEP・Gerber・G-codeは派生出力として扱います。

参考: [Arduino設定](https://docs.arduino.cc/arduino-cli/configuration/)、
[Arduino build profiles](https://arduino.github.io/arduino-cli/latest/sketch-project-file/)、
[PlatformIOの環境変数](https://docs.platformio.org/en/latest/envvars.html)。
