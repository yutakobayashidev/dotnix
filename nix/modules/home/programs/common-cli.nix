# 共通CLIプログラムの集約モジュール
# cli.nix, cli-server.nix, darwin.nix で共通して使用
{ ... }:
{
  imports = [
    ../packages.nix
    ./gh.nix
    ./tmux
    ./neovim.nix
    ./bat.nix
    ./btop.nix
    ./fastfetch
  ];
}
