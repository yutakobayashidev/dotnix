{ ... }:
{
  home-manager.users.yuta.imports = [
    ./../modules/home/packages.nix
    ./../modules/home/packages-darwin.nix
    ./../modules/home/programs/gh.nix
    ./../modules/home/programs/tmux
    ./../modules/home/programs/neovim.nix
    ./../modules/home/programs/bat.nix
    ./../modules/home/programs/btop.nix
    ./../modules/home/programs/fastfetch
    ./../modules/home/programs/vscode.nix
    ./../modules/home/programs/ghostty
  ];
}
