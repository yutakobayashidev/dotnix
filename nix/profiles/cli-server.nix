{ ... }:
{
  imports = [
    ./cli-minimal.nix
    ./../modules/linux/docker.nix
    # Tailscaleは含めない
  ];

  home-manager.users.yuta.imports = [
    ./../modules/home/programs/common-cli.nix
    ./../modules/linux/home-packages.nix
  ];
}
