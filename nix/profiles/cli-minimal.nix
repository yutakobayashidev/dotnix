{ ... }:
{
  imports = [
    ./../ssh.nix
    ./../fonts.nix
  ];

  home-manager.users.yuta.imports = [
    ./../modules/home/programs/git.nix
    ./../modules/home/programs/zsh.nix
  ];
}
