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
        home.sessionVariables = {
          GHTKN_ENABLE_DEVICE_FLOW = "false";
        };

        programs.gh = {
          enable = true;
          gitCredentialHelper.enable = false;
          extensions = [
            pkgs.gh-graph
            pkgs.gh-nippou
            pkgs.gh-dash
            pkgs.gh-poi
            pkgs.gh-notify
            pkgs.gh-do
          ];
        };

        home.packages = with pkgs; [
          ghq
          tea
          ghtkn
        ];
      };
    };
}
