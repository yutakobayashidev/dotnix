{ ... }:
{
  imports = [
    ./cli-minimal.nix
    ./../modules/core/packages.nix
    ./../modules/core/docker.nix
    # Tailscaleは含めない
  ];

  home-manager.users.yuta.imports = [
    ./../modules/home/packages.nix
    ./../modules/home/programs/gh.nix
    ./../modules/home/programs/tmux.nix
    ./../modules/home/programs/neovim.nix
    ./../modules/home/programs/bat.nix
    ./../modules/home/programs/btop.nix
    ./../modules/home/programs/fastfetch
  ];
}
