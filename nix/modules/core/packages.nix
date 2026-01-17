# システムレベルのパッケージ
{ pkgs, ... }:

{
  # システムパッケージ
  environment.systemPackages = with pkgs; [
    wofi
  ];

  # プログラム設定
  programs.firefox.enable = true;
  programs.zsh.enable = true;

  # nh - Nix helper
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/yuta/ghq/github.com/yutakobayashidev/dotnix";
  };

  # nix-ld - Run dynamically linked executables
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
