# NixOS desktop settings shared by graphical hosts.
{ pkgs, ... }:

{
  imports = [
    ./fonts.nix
    ./input-method.nix
  ];

  programs.niri = {
    enable = true;
  };

  programs.obs-studio.enableVirtualCamera = true;
  programs.xwayland.enable = true;

  environment.systemPackages = with pkgs; [
    wofi
  ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.printing.enable = true;

  services.greetd.enable = true;
  programs.regreet.enable = true;

  ext.security.yubikey.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

}
