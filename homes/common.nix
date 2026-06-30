_: {
  imports = [
    ../applications/atuin
    ../applications/bat
    ../applications/btop
    ../applications/fastfetch
    ../applications/git
    ../applications/misc
    ../applications/tmux
  ];

  programs.home-manager.enable = true;
  my.programs.neovim.enable = true;
  home.stateVersion = "25.11";
  home.preferXdgDirectories = true;
}
