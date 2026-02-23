# システムレベルのパッケージ
{ pkgs, ... }:

{
  # システムパッケージ
  environment.systemPackages = with pkgs; [
    wofi
  ];

  # プログラム設定
  programs.zsh.enable = true;

  # nix-ld - Run dynamically linked executables
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
    ];
  };
}
