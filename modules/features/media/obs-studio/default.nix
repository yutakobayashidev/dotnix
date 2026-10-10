_:

{
  flake.modules.homeManager.obs-studio =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      isLinux = pkgs.stdenv.isLinux;
    in
    {
      options.my.programs.obs-studio.enable = lib.mkEnableOption "obs-studio";

      config = lib.mkIf (config.my.programs.obs-studio.enable && isLinux) {
        programs.obs-studio = {
          enable = true;
          plugins = with pkgs.obs-studio-plugins; [
            droidcam-obs
            obs-backgroundremoval
            obs-gstreamer
            obs-pipewire-audio-capture
            wlrobs
          ];
        };
      };
    };
}
