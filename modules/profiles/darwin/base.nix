{
  imports = [
    ../../shared/nix
  ];

  my.nix.enable = true;
  services.tailscale.enable = true;
}
