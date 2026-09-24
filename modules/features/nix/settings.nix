_:

let
  module =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.my.nix;
    in
    {
      options.my.nix = {
        enable = lib.mkEnableOption "Nix configuration";
        enableFlakes = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to enable flakes.";
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          (lib.mkIf cfg.enableFlakes {
            nix = {
              settings.experimental-features = [
                "nix-command"
                "flakes"
              ];
              channel.enable = false;
            };
          })
          {
            nix = {
              optimise.automatic = true;

              gc = {
                automatic = true;
                options = "--delete-older-than 7d";
              };

              settings = {
                accept-flake-config = true;
                auto-optimise-store = pkgs.stdenv.hostPlatform.isLinux;
                warn-dirty = false;
                sandbox = if pkgs.stdenv.hostPlatform.isDarwin then "relaxed" else true;
                trusted-users = [
                  "root"
                  "@wheel"
                ]
                ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin "@admin";
                substituters = [
                  "https://cache.nixos.org"
                  "https://cache.numtide.com"
                  "https://nix-cache.yutakobayashi.com"
                  "https://yuta.cachix.org"
                  "https://devenv.cachix.org"
                  "https://nix-community.cachix.org"
                  "https://codex-desktop-linux.cachix.org"
                  "https://ghostty.cachix.org"
                  "https://niri.cachix.org"
                  "https://cuda-maintainers.cachix.org"
                  "https://cache.nixos-cuda.org"
                ];
                trusted-public-keys = [
                  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                  "niks3-1:Ay1+L/bEpRLOvfcAspotbB8TgNHIkMF1gX28uUcYwhM="
                  "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
                  "yuta.cachix.org-1:VGiC7m0kQjut7lp+RG/9pCRHFpzf11ELQrM2Nc2QCCk="
                  "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                  "codex-desktop-linux.cachix.org-1:nX/xy6AdK9hQE24A8ALGjkCKj2ObFmcnemiL5Cid4nk="
                  "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
                  "niri.cachix.org-1:Wv0UzwLBOfMIiQRtEPf50VzM2g0R0u1uJj59y/v68cM="
                  "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
                  "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
                ];
              };

              extraOptions = ''
                max-silent-time = 3600
              '';
            };
          }
        ]
      );
    };
in
{
  flake.modules = {
    nixos.nix = module;
    darwin.nix = module;

    homeManager.nix =
      {
        config,
        lib,
        ...
      }:
      let
        cfg = config.my.nix;
      in
      {
        options.my.nix.enable = lib.mkEnableOption "nix";

        config = lib.mkIf cfg.enable {
          nix.settings.use-xdg-base-directories = config.xdg.enable;

          programs.git.ignores = [ "result" ];
        };
      };
  };
}
