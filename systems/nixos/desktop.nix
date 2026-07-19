# NixOS desktop settings shared by graphical hosts.
{ pkgs, ... }:

{
  imports = [
    ./fonts.nix
    ./input-method.nix
    ../../applications/wireshark
  ];

  programs = {
    gnome-disks.enable = true;
    niri.enable = true;
    obs-studio.enableVirtualCamera = true;
    xwayland.enable = true;
    regreet = {
      enable = true;
      font = {
        package = pkgs.inter;
        name = "Inter";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    wofi
  ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services = {
    blueman.enable = true;
    gvfs.enable = true;
    printing.enable = true;
    greetd.enable = true;
    gnome.gnome-keyring.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  ext.security.yubikey.enable = true;

  security = {
    pam.services = {
      login.enableGnomeKeyring = true;
      swaylock.enableGnomeKeyring = true;
    };
    rtkit.enable = true;
  };
}
