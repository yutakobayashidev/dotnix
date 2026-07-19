_:

let
  mkNeovim = pkgs: pkgs.callPackage ./package.nix { };
in

{
  flake.homeManagerModules.neovim =
    {
      config,
      lib,
      pkgs,
      helpers,
      dotfilesDir,
      ...
    }:

    let
      nvimDotfilesDir = "${dotfilesDir}/modules/flake/features/neovim";
      nvimConfigDir = "${config.xdg.configHome}/nvim";
      neovim = mkNeovim pkgs { configRoot = nvimConfigDir; };
    in
    {
      options.my.programs.neovim.enable = lib.mkEnableOption "neovim";

      config = lib.mkIf config.my.programs.neovim.enable {
        home = {
          packages = [ neovim ];
          sessionVariables.EDITOR = "nvim";
        };

        home.activation = {
          prepareNvimConfig = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
            $DRY_RUN_CMD rm -rf "${nvimConfigDir}"
          '';

          linkNvimConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
            ${helpers.activation.mkLinkForce}
            link_force "${nvimDotfilesDir}" "${nvimConfigDir}"
          '';
        };
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.neovim = mkNeovim pkgs { };
    };
}
