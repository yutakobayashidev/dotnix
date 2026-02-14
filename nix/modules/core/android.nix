# Android開発環境設定
{ pkgs, ... }:

{
  # Android SDK EULA承認
  nixpkgs.config.android_sdk.accept_license = true;

  # systemd 258+は自動でuaccessルールを処理するため、android-udev-rulesは不要
}
