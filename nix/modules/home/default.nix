{ ... }:

{
  imports = [
    ./dotfiles.nix
    ./agent-skills.nix
    ./programs/cage.nix
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/git.nix
    ./programs/jj.nix
    ./programs/zsh.nix
  ];

  # nix-index for command-not-found and comma
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;

  home.username = "yuta";

  home.stateVersion = "25.11";
}
