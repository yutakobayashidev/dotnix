{ lib, inputs, ... }:
let
  withEmacsOverlay = pkgs: pkgs.extend inputs.emacs-overlay.overlays.default;

  emacsUnwrapped =
    pkgs:
    let
      epkgs = withEmacsOverlay pkgs;
    in
    if pkgs.stdenv.hostPlatform.isDarwin then epkgs.emacs-macport else epkgs.emacs-pgtk;

  tangle =
    pkgs:
    {
      name,
      org,
    }:
    pkgs.runCommand name { nativeBuildInputs = [ (emacsUnwrapped pkgs) ]; } ''
      emacs -Q --batch --eval \
        "(progn
          (require 'ob-tangle)
          (org-babel-tangle-file \"${org}\" \"$out\"))"
    '';

  tangleEl =
    pkgs: org:
    let
      stem = name: lib.head (lib.splitString "." name);
    in
    tangle pkgs {
      name = "${stem (baseNameOf (toString org))}.el";
      inherit org;
    };

  mkEmacs =
    pkgs:
    let
      epkgs = withEmacsOverlay pkgs;
      emacs = emacsUnwrapped pkgs;
    in
    epkgs.emacsWithPackagesFromUsePackage {
      package = emacs;
      config = ./init.org;
      alwaysTangle = true;
      alwaysEnsure = true;
      defaultInitFile = tangle pkgs {
        name = "default.el";
        org = ./init.org;
      };
      extraEmacsPackages = epkgs': [
        epkgs'.treesit-grammars.with-all-grammars
        pkgs.beancount
        pkgs.beancount-language-server
      ];
    };
in
{
  flake.modules.homeManager.emacs =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.programs.emacs.enable = lib.mkEnableOption "emacs";

      config = lib.mkIf config.my.programs.emacs.enable {
        home.packages = [ pkgs.harper ];

        programs.emacs = {
          enable = true;
          package = mkEmacs pkgs;
        };

        services.emacs = {
          enable = true;
          client.enable = true;
        };

        xdg.configFile."emacs/init.el".source = tangleEl pkgs ./init.org;

        home.shellAliases = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          emacs = "${config.programs.emacs.package}/Applications/Emacs.app/Contents/MacOS/Emacs";
        };
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.emacs = mkEmacs pkgs;
    };
}
