{ inputs, pkgs, ... }:

let
  # The upstream DMG URL is mutable and currently ahead of the flake's pins.
  # Replace only its closed-over fetchurl until codex-desktop-linux catches up.
  codexDesktop = inputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop;
  codexDmg = pkgs.fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/ChatGPT.dmg";
    hash = "sha256-ezci5PWGQgKx3Wnm5gYvL4xDiNIVCRUDxz4ZV7TL+Xo=";
  };
  codexDesktopPayload = codexDesktop.drvAttrs.src;
  oldInstallPhase = codexDesktopPayload.drvAttrs.installPhase;
  oldInstallPhaseText = builtins.unsafeDiscardStringContext oldInstallPhase;
  oldDmgPath =
    pkgs.lib.findFirst (value: pkgs.lib.hasSuffix "-ChatGPT.dmg" value)
      (throw "Could not find the upstream ChatGPT DMG in the Codex Desktop payload")
      (pkgs.lib.splitString " " oldInstallPhaseText);
  oldDmgDrv =
    pkgs.lib.findFirst (value: pkgs.lib.hasSuffix "-ChatGPT.dmg.drv" value)
      (throw "Could not find the upstream ChatGPT DMG derivation in the Codex Desktop payload")
      (builtins.attrNames (builtins.getContext oldInstallPhase));
  patchedInstallPhase =
    builtins.appendContext
      (builtins.replaceStrings [ oldDmgPath ] [ (builtins.unsafeDiscardStringContext "${codexDmg}") ]
        oldInstallPhaseText
      )
      (
        builtins.removeAttrs (builtins.getContext oldInstallPhase) [ oldDmgDrv ]
        // builtins.getContext "${codexDmg}"
      );
  patchedCodexDesktopPayload = codexDesktopPayload.overrideAttrs {
    version = "26.721.81911";
    __intentionallyOverridingVersion = true;
    installPhase = patchedInstallPhase;
  };
  patchedCodexDesktop = codexDesktop.overrideAttrs {
    version = "26.721.81911";
    src = patchedCodexDesktopPayload;
  };
in
{
  imports = [
    inputs.codex-desktop-linux.homeManagerModules.default
    inputs.nani-translate-linux.homeManagerModules.default
    ../../applications/niri
    ../../applications/waybar
    ../../applications/swayidle
    ../../applications/swaylock
    ../../applications/zaproxy
  ];

  my.programs = {
    emacs.enable = true;
    vicinae.enable = true;
  };
  programs.codexDesktopLinux = {
    enable = true;
    package = patchedCodexDesktop;
    cliPackage = pkgs.llm-agents.codex;
  };
  programs.naniTranslateLinux.enable = true;
  ext.xdg.enable = true;
  services.wallpaper.enable = true;

  # Unwrapped GTK 3 applications, including Tauri development builds, need
  # the file chooser schema on the desktop session search path.
  home.sessionVariables.XDG_DATA_DIRS = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";

  home.packages = with pkgs; [
    buzz
    file-roller
    mpvpaper
    pavucontrol
    rquickshare
    screenpipe-app
    screenpipe-cli
    sushi
    swappy
    turbowarp-desktop
    wl-clipboard
    zenity
    zoom-us
  ];
}
