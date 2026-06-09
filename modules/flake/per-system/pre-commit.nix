{ inputs, ... }:
{
  imports = [ inputs.git-hooks.flakeModule ];

  perSystem =
    { config, ... }:
    {
      pre-commit = {
        check.enable = false;
        settings.hooks = {
          actionlint.enable = true;
          convco.enable = true;
          shellcheck = {
            enable = true;
            args = [ "-x" ];
            excludes = [
              "\\.zsh$"
              "^\\.envrc$"
            ];
          };

          treefmt = {
            enable = true;
            package = config.treefmt.build.wrapper;
          };
        };
      };
    };
}
