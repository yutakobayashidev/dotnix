_: {
  imports = [
    ../applications/atuin
    ../applications/bat
    ../applications/btop
    ../applications/fastfetch
    ../applications/git
    ../applications/misc
    ../applications/neovim
    ../applications/tmux
  ];

  programs.home-manager.enable = true;
  home.stateVersion = "25.11";
  home.preferXdgDirectories = true;
}
