{ pkgs, ... }:

{
  imports = [
    ../../../applications/atuin
    ../../../applications/bat
    ../../../applications/git
    ../../../applications/neovim
    ../../../applications/tmux
  ];

  home.packages = with pkgs; [
    curl
    eza
    fzf
    glow
    gum
    jq
    ripgrep
    roots
    sshpass
    wget
    xh
    zoxide
  ];
}
