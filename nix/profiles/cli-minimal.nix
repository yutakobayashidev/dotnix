{ ... }:
{
  imports = [
  ];

  home-manager.users.yuta.imports = [
    ./../modules/home/programs/git.nix
    ./../modules/home/programs/zsh.nix
  ];
}
