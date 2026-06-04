{ username, pkgs, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} = {
    imports = [
      ../../../nix/modules/profiles/home/cli.nix
      ../../../nix/modules/profiles/home/development.nix
    ];
    home.homeDirectory = "/home/${username}";
    home.packages = [ pkgs.xdg-utils ];
    home.file.".local/share/applications/file-protocol-handler.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Version=1.0
      Name=File Protocol Handler
      NoDisplay=true
      MimeType=x-scheme-handler/http;x-scheme-handler/https;
      Exec=rundll32.exe url.dll,FileProtocolHandler %u
    '';
    xdg.configFile."mimeapps.list".text = ''
      [Default Applications]
      x-scheme-handler/http=file-protocol-handler.desktop
      x-scheme-handler/https=file-protocol-handler.desktop

      [Added Associations]
      x-scheme-handler/http=file-protocol-handler.desktop;
      x-scheme-handler/https=file-protocol-handler.desktop;
    '';
  };
}
