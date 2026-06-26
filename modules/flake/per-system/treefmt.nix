{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          stylua = {
            enable = true;
            excludes = [
              "nvim/init.lua"
              "nvim/lua/rc/**"
            ];
          };
          shfmt.enable = true;
          taplo.enable = true;
          ruff-format.enable = true;
          oxfmt = {
            enable = true;
            excludes = [
              "nvim/template/**"
              "nvim/lazy-lock.json"
              "**/.npmrc"
            ];
          };
        };

        settings = {
          global.excludes = [
            ".git/**"
            "*.lock"
          ];

          formatter.gitleaks = {
            command = "${pkgs.gitleaks}/bin/gitleaks";
            options = [
              "detect"
              "--no-git"
              "--exit-code"
              "0"
            ];
            includes = [ "*" ];
            excludes = [
              "*.png"
              "*.jpg"
              "*.jpeg"
              "*.gif"
              "*.ico"
              "*.pdf"
              "*.woff"
              "*.woff2"
              "*.ttf"
              "*.eot"
              "node_modules/**"
              ".direnv/**"
            ];
          };
        };
      };
    };
}
