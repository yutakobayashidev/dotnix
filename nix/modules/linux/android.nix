# Android開発環境設定
# nixpkgs.config.android_sdk.accept_license は flake.nix の mkPkgs で設定
# （外部インスタンス使用時はモジュール内で nixpkgs.config を設定できないため）
# systemd 258+は自動でuaccessルールを処理するため、android-udev-rulesは不要
{ ... }:
{
}
