_:
{
  flake.modules.nixos.nvidia =
    { config, lib, ... }:
    {
      options.my.devices.nvidia.enable = lib.mkEnableOption "the NVIDIA driver";

      config = lib.mkIf config.my.devices.nvidia.enable {
        services.xserver.videoDrivers = [ "nvidia" ];
        hardware = {
          nvidia.open = true;
          graphics = {
            enable = true;
            extraPackages = [ config.hardware.nvidia.package ];
          };
          nvidia-container-toolkit.enable = true;
        };
      };
    };
}
