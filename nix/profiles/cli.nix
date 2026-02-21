{ ... }:
{
  imports = [
    ./cli-minimal.nix
    ./../modules/core/docker.nix
    ./../modules/core/tailscale.nix
  ];

  home-manager.users.yuta.imports = [
    ./../modules/home/packages.nix
    ./../modules/home/programs/gh.nix
    ./../modules/home/programs/tmux
    ./../modules/home/programs/neovim.nix
    ./../modules/home/programs/bat.nix
    ./../modules/home/programs/btop.nix
    ./../modules/home/programs/fastfetch
  ];
}
