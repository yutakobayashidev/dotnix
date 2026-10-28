_:

{
  flake.modules.homeManager."gh" =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.my.programs.gh;
    in
    {
      options.my.programs.gh.enable = lib.mkEnableOption "GitHub CLI";

      config = lib.mkIf cfg.enable {
        programs.gh = {
          enable = true;
          gitCredentialHelper.enable = true;
          settings.expiring_credentials = "enabled";
          extensions = [
            pkgs.gh-graph
            pkgs.gh-nippou
            pkgs.gh-dash
            pkgs.gh-poi
            pkgs.gh-notify
            pkgs.gh-do
            pkgs.gh-stack
          ];
        };

        home.packages = with pkgs; [
          ghq
          tea
        ];
      };
    };
}
