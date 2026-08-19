# NixOS desktop settings shared by graphical hosts.
{ pkgs, ... }:

{
  imports = [
    ./fonts.nix
    ./input-method.nix
  ];

  programs = {
    gnome-disks.enable = true;
    niri.enable = true;
    obs-studio.enableVirtualCamera = true;
    xwayland.enable = true;
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services = {
    blueman.enable = true;
    displayManager.regreet = {
      enable = true;
      font = {
        package = pkgs.inter;
        name = "Inter";
      };
    };
    gvfs.enable = true;
    printing.enable = true;
    greetd.enable = true;
    gnome.gnome-keyring.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
      pulse.enable = true;

      extraConfig.pipewire."90-echo-cancel.conf" = {
        "context.modules" = [
          {
            name = "libpipewire-module-echo-cancel";

            args = {
              # 現在のデフォルト実装でもあるWebRTC AECを明示
              "library.name" = "aec/libspa-aec-webrtc";

              # 仮想出力を作らず、デフォルト出力全体を参照信号にする
              # Discord以外のブラウザ・ゲーム・音楽も対象になる
              "monitor.mode" = true;

              "capture.props" = {
                "node.name" = "echo_cancel_capture";
                "node.description" = "Echo Cancel Capture";
              };

              "source.props" = {
                "node.name" = "echo_cancel_source";
                "node.description" = "Echo Cancelled Microphone";
              };
            };
          }
        ];
      };

      wireplumber.extraConfig."51-bluetooth-profile" = {
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = false;
        };

        "monitor.bluez.properties" = {
          "bluez5.roles" = [
            "a2dp_sink"
            "a2dp_source"
            "bap_sink"
            "bap_source"
          ];
        };
      };
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
