{ ... }:

{
  imports = [
    ./dotfiles.nix
    ./agent-skills.nix
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/git.nix
    ./programs/jj.nix
    ./programs/zsh.nix
  ];

  home.username = "yuta";

  home.stateVersion = "25.11";
}
