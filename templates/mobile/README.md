# Android mobile development

Linux x86_64 用の開発環境テンプレート。Android Studio を使わずに、Kotlin /
Compose アプリのビルド、端末操作、APK解析を Coding Agent から実行できます。
アプリのソースは含みません。既存のアプリを置くか、公式 Android CLI で生成します。

## 開始

```bash
nix develop
mobile doctor
mobile create --help
```

この flake は Android SDK ライセンスを `android_sdk.accept_license = true`
で受諾し、非自由な Android CLI / SDK を利用します。利用条件を確認してから
実行してください。初回は SDK とシステムイメージの取得に数GB必要です。
`flake.lock` と `registry/sources.lock.json` をプロジェクトで追跡してください。

既存アプリではアプリのディレクトリで `mobile gradle assembleDebug` を実行します。
新規アプリは `mobile create --help` の現在の構文に従い、サブディレクトリへ
作成します。例: `mobile create empty-activity --name="My App" --output=./app-project`。
生成時だけテンプレート取得用の書き込み可能な `.mobile/bootstrap-sdk` を使います。
この生成処理はオンラインで、取得したテンプレート自体はNixで固定されません。
生成したコードとWrapperをコミットし、ビルドにはNixのSDKを使います。
生成直後は `local.properties` の `sdk.dir` を `$ANDROID_HOME` の値へ変更します。
公式テンプレートのSDK要求が初期値と異なる場合は `nix/settings.nix` を合わせます。
`jvmToolchain(17)` を使うアプリでは、`nix/shell.nix` のJDKを17に揃えるか、
アプリ側で使用するtoolchainを21に変更してください。
Gradle Wrapper、Kotlin、AGP、Compose のバージョンはアプリ側で管理します。

| shell                    | 内容                                              | AVD / serial                  |
| ------------------------ | ------------------------------------------------- | ----------------------------- |
| `nix develop`            | JDK 21、SDK、Android CLI、ADB、Emulator、Maestro  | Google APIs / `emulator-5554` |
| `nix develop .#analysis` | 開発ツール＋JADX、Apktool、Frida tools、mitmproxy | AOSP / `emulator-5556`        |
| `nix develop .#full`     | analysis＋Ghidra                                  | analysis と同じ               |

解析ツールは開発 shell には入りません。`full` と `analysis` は同じ AVD を使うため、
同時に起動しないでください。他プロジェクトと同時に動かす場合もポートを分けます。

## SDK とホスト

`nix/settings.nix` で API / Build Tools のバージョンを変更します。
初期値は API 36 / Build Tools 36.0.0。アプリの `compileSdk` と
`buildToolsVersion` に合わせてください。SDK は Nix Store 内の読み取り専用です。
`android sdk install` や `sdkmanager` で変更せず、Nix の設定を変更します。
NixOS 用 `aapt2` の指定は shell が `GRADLE_OPTS` に追加します。
既存の `local.properties` の `sdk.dir` が別の SDK を指す場合は修正してください。

実機のみ、またはビルド専用CIでは `emulator = false` にするとイメージ取得を省けます。
NDK / CMake は初期状態では含めません。必要なプロジェクトでは `nix/shell.nix` の
SDK composition に、アプリが指定するバージョンを追加します。

KVMとUSB権限はホスト側の設定です。NixOSでは、例えば以下を設定して再ログインします。

```nix
{
  users.users.yuta.extraGroups = [ "kvm" "adbusers" ];
  services.udev.packages = [ pkgs.android-udev-rules ];
}
```

ユーザー名は置き換えてください。`mobile doctor` は `/dev/kvm` と
`emulator -accel-check` を検査します。VM内ではネストした仮想化が必要です。
非NixOSのLinuxでは、GPUドライバとの互換性をホストごとに確認してください。

## AVD と開発ループ

```bash
mobile avd-create
mobile avd-start
```

別ターミナルで同じプロジェクトの同じ shell に入り、続けます。

```bash
mobile wait 180
mobile gradle assembleDebug testDebugUnitTest lintDebug
adb -s emulator-5554 install -r app/build/outputs/apk/debug/app-debug.apk
mobile android screen --help
mobile android input --help
adb -s emulator-5554 logcat
```

Gradleタスク名・APKパスはアプリに合わせて変更してください。Android CLIも、
複数端末が接続されている場合は各コマンドのヘルプに従って対象端末を指定します。
ヘッドレス起動は `mobile avd-start -no-window -no-audio -gpu swiftshader_indirect`。
`mobile avd-start` はフォアグラウンドで起動し、スナップショットを読み書きしません。
ユーザーデータは保持します。`mobile wait` は期限を過ぎると終了コード124で失敗します。

AVD / Gradleキャッシュは shell に入ったディレクトリの `.mobile/` に保存します。
既存AVDを `avd-create` が上書きすることはありません。SDK更新後に古いStoreパスを
参照する場合は、必要なデータを退避してから `avdmanager delete avd -n "$MOBILE_AVD"`
で削除し、再作成してください。別ターミナルも同じテンプレートルートから入ります。

## MaestroによるE2Eテスト

Maestro CLIもflake.lockで固定しています。起動済みのAVDへAPKをインストールしてから、
YAMLのFlowを実行します。Android CLIは端末操作や調査、Maestroは繰り返し実行する
UIテストに使えます。

```bash
mobile wait
adb -s emulator-5554 install -r app/build/outputs/apk/debug/app-debug.apk
mkdir -p .mobile/reports
mobile test -e APP_ID=com.example.app -e READY_TEXT="Hello Android!" \
  --format JUNIT --output .mobile/reports/maestro.xml \
  --debug-output .mobile/maestro .maestro/smoke.yaml
```

`APP_ID`はアプリのapplicationId、`READY_TEXT`は起動後に表示される実際の文字列へ
変更してください。付属のsmoke Flowは起動と表示確認を行い、データの初期化はしません。
アプリに合わせてタップ・入力・表示検証を追加し、`.maestro/` をGit管理します。
出力先の `.mobile/` はGit管理しません。

`mobile test` は現在のshellのAVDを明示的に指定します。実機の場合は
`MOBILE_DEVICE=<adb-serial> mobile test ...` で指定します。
直接 `maestro --device emulator-5554 test ...` と実行することもできます。
端末の起動・APKのインストールはテストコマンドでは自動実行しません。

[公式CLIリファレンス](https://docs.maestro.dev/maestro-cli/maestro-cli-commands-and-options)

## Agent Skills

公式 [android/skills](https://github.com/android/skills) をソースレジストリで固定し、
`agent-skills-nix` が shell 起動時に次のプロジェクト内ディレクトリへ配備します。
`.agents/skills`（Pi共用）、`.codex/skills`、`.claude/skills`、`.opencode/skills`。
これらは生成物です。独自スキルの原本は別ディレクトリで管理してください。
Agentは shell に入った後、プロジェクトルートで起動します。
`android init` や `android skills add` による二重インストールは不要です。

```bash
# CLI・SDK・配備ライブラリの更新
nix flake update
# 公式スキルの更新（flake.lockとは別）
nix run .#skills-sources-lock
# 更新後の検証
nix flake check
nix develop
```

## APK解析

```bash
nix develop .#analysis
mobile analyze ./sample.apk ./report
mobile avd-create
mobile avd-start
```

`mobile analyze` は新規出力先にSHA-256・元ファイルパス・JADXとApktoolの出力を
保存します。元APKは変更せず、既存出力先には書き込みません。ツールが失敗した場合は
途中の成果物を残して非ゼロ終了します。出力先はGitに追加しないでください。
入手元・アプリバージョン・解析メモは別途記録します。

動的解析は別ターミナルの analysis shell から行います。

```bash
mobile wait
adb -s emulator-5556 root
adb -s emulator-5556 shell getprop ro.product.cpu.abi
frida --version
frida-ls-devices
```

Frida Serverは、ホストFridaと一致するバージョン・ゲストABIのものを
[公式リリース](https://github.com/frida/frida/releases)から用意し、解析AVD内で
起動してください。実機のARM専用アプリは x86_64 AVD で動かない場合があります。
サーバーの転送・起動やAPKインストールは自動実行しません。

AVD分離はデータの混在を防ぎますが、ネットワークやホストを隔離するものではありません。
信頼できないAPKの動的解析には、ネットワークを制限した専用VMなどを使います。
mitmproxyのCA導入やプロキシ設定も解析対象環境に限定します。

## MobSF（必要な場合）

MobSFはshell起動時には起動しません。ホストにDockerまたはPodmanを用意し、
[公式手順](https://mobsf.github.io/docs/)で選んだイメージをdigestで固定して使います。

```bash
# MOBSF_IMAGEには、レビューしたイメージ名@sha256:...を設定する
: "${MOBSF_IMAGE:?Set a reviewed MobSF image digest}"
docker run --rm -p 127.0.0.1:8000:8000 "$MOBSF_IMAGE"
```

動的解析用のAndroidバージョン・接続方法はMobSFの対応表で別途確認してください。
このテンプレートのAOSP API 36が対応していることは前提にしていません。

## 構成の拡張と検証

`nix/shell.nix` は共通設定に解析ツールなどを追加する関数です。追加ツールは
`mkMobileShell { extraPackages = [ pkgs.nodejs ]; }` のように組み合わせられます。
複数の完成済み `flake.nix` をコピーしてマージする必要はありません。

`nix flake check` はシェル評価、ShellCheck、端末指定・タイムアウト・既存データ
保護のテストを実行します。KVMを使う起動試験や実アプリのビルドは別途必要です。

参考: [Android CLI](https://developer.android.com/tools/agents/android-cli)、
[Nixpkgs Android](https://nixos.org/manual/nixpkgs/unstable/#android)、
[Frida Android](https://frida.re/docs/android/)。
