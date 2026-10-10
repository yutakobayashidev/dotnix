_:

{
  flake.modules.homeManager.zed-editor =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.zed-editor;
    in
    {
      options.my.programs.zed-editor.enable = lib.mkEnableOption "Zed editor";

      config = lib.mkIf cfg.enable {
        home.packages = [
          pkgs.zed-editor
        ];
      };
    };
}
