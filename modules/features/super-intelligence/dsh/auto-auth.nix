# Adapted from Kihara777/NixKits modules/dsh.nix, reverseProxy.autoAuth.
# Revision deea6012ec713b808ed97b920e75033d872fb332; see NixKits-LICENSE.
{
  config,
  lib,
  pkgs,
}:
let
  cfg = config.my.programs.dsh.web;
  lighttpd = pkgs.lighttpd.override { enableMagnet = true; };
  capture = pkgs.writeShellApplication {
    name = "dsh-web-token";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      for _ in $(seq 1 60); do
        token=$(grep -oPm1 'token=\K[A-Za-z0-9_-]+' "$RUNTIME_DIRECTORY/web.log" || true)
        if [ -n "$token" ]; then
          printf '%s\n' "$token" > "$RUNTIME_DIRECTORY/launch-token"
          exit 0
        fi
        sleep 1
      done
      echo "dsh did not print a launch token within 60 seconds" >&2
      exit 1
    '';
  };
  script = pkgs.writeText "dsh-auto-auth.lua" ''
    -- Adapted from NixKits reverseProxy.autoAuth (see NixKits-LICENSE).
    local cookie = lighty.request["Cookie"] or ""
    if string.find(cookie, "dsh-auth-", 1, true) then
      return nil
    end
    local uri = lighty.env["request.uri"] or "/"
    if string.find(uri, "token=", 1, true) then
      return nil
    end
    local path = string.match(uri, "^([^?]*)")
    if path == "/" or path == "/index.html" then
      local f = io.open(os.getenv("DSH_WEB_RUNTIME") .. "/launch-token", "r")
      if f then
        local token = f:read("*l")
        f:close()
        if token and token ~= "" then
          lighty.header["Location"] = "/?token=" .. token
          lighty.header["Cache-Control"] = "no-store"
          lighty.header["Referrer-Policy"] = "no-referrer"
          return 302
        end
      end
    end
    return nil
  '';
  proxyConfig = pkgs.writeText "dsh-web-lighttpd.conf" ''
    server.modules = ( "mod_magnet", "mod_proxy" )
    server.document-root = "${pkgs.emptyDirectory}"
    server.bind = "${cfg.host}"
    server.port = ${toString cfg.port}
    magnet.attract-raw-url-to = ( "${script}" )
    proxy.server = ( "" => (( "host" => "127.0.0.1", "port" => ${toString cfg.backendPort} )) )
    proxy.header = ( "upgrade" => "enable" )
  '';
in
{
  wrap =
    command:
    pkgs.writeShellScript "dsh-web-start" ''
      exec ${command} > "$RUNTIME_DIRECTORY/web.log"
    '';
  backendService = {
    RuntimeDirectory = "dsh-web";
    RuntimeDirectoryMode = "0700";
    ExecStartPre = "${pkgs.coreutils}/bin/rm -f %t/dsh-web/launch-token %t/dsh-web/web.log";
    ExecStartPost = lib.getExe capture;
  };
  service = {
    Unit = {
      Description = "DSH automatic browser sign-in (NixKits)";
      Wants = [ "dsh-web.service" ];
      After = [ "dsh-web.service" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${lighttpd}/bin/lighttpd -D -f ${proxyConfig}";
      Environment = [ "DSH_WEB_RUNTIME=%t/dsh-web" ];
      Restart = "on-failure";
      RestartSec = 5;
      UMask = "0077";
    };
  };
}
