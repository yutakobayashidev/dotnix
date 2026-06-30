{
  imports = [
    ../../shared/nix
    ../../shared/nixpkgs
  ];

  my.nix.enable = true;
  my.nixpkgs = {
    enable = true;
    permittedInsecurePackages = [
      "python3.13-ecdsa-0.19.2"
    ];
  };
  my.services.tailscale.enable = true;

  nixpkgs.config.android_sdk.accept_license = true;
}
