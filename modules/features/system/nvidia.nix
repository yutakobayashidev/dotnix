_: {
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

        # The loaded kernel module cannot follow a live userspace driver upgrade.
        # Comin schedules changed versions for boot; manual switches refuse them.
        system.switch.inhibitors.nvidia = config.hardware.nvidia.package.version;
      };
    };
}
