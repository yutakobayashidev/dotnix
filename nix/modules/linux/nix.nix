{ ... }:

{
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 4d";
  };

  nix.optimise.automatic = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    accept-flake-config = true;
    keep-outputs = true;
    keep-derivations = true;
    connect-timeout = 5;
    substituters = [
      "https://cache.nixos.org"
      "https://cache.numtide.com"
      "https://yuta.cachix.org"
      "https://devenv.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "yuta.cachix.org-1:VGiC7m0kQjut7lp+RG/9pCRHFpzf11ELQrM2Nc2QCCk="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
