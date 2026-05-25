{ pkgs, ... }:

{
  imports = [
    ../../../../applications/atuin
    ../../../../applications/bat
    ../../../../applications/git
    ../../../../applications/neovim
    ../../../../applications/tmux
  ];

  home.packages = with pkgs; [
    curl
    fzf
    glow
    gum
    jq
    lsd
    ripgrep
    sshpass
    tree
    wget
    xh
    zoxide
  ];
}
