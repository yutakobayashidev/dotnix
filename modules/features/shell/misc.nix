_:

{
  flake.modules.homeManager.misc =
    # Primitive CLI tools installed on every Home Manager host.
    { lib, pkgs, ... }:

    {
      home.packages =
        with pkgs;
        [
          aria2
          coreutils
          curl
          eza
          fzf
          glib
          glow
          gum
          jq
          jnv
          jolt-tui
          pueue
          qrcode
          ripgrep
          roots
          tokei
          unar
          unzip
          wget
          xh
          yazi
          zoxide
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          dmidecode
          kubo
          nvme-cli
          pciutils
          psmisc
          reptyr
          usbutils
        ];

      programs.nix-index.enable = true;
      programs.nix-index-database.comma.enable = true;
    };
}
