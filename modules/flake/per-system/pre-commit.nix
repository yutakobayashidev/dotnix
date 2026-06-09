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
          yamllint = {
            enable = true;
            excludes = [
              "secrets/default.yaml"
              "secrets.yaml"
            ];
            settings.configData = "{rules: {document-start: {present: false}}}";
          };

          treefmt = {
            enable = true;
            package = config.treefmt.build.wrapper;
          };
        };
      };
    };
}
