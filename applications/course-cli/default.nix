{
  config,
  lib,
  pkgs,
  ...
}:

let
  course-cli = pkgs.writeShellApplication {
    name = "course-cli";
    text = ''
      secret_file=${lib.escapeShellArg config.sops.secrets.course-session.path}

      if [[ ! -r "$secret_file" ]]; then
        echo "Course CLI session secret is unavailable: $secret_file" >&2
        exit 1
      fi

      COURSE_SESSION="$(<"$secret_file")"
      export COURSE_SESSION
      exec ${lib.getExe pkgs.course-cli} "$@"
    '';
  };
in

{
  home.packages = [ course-cli ];

  sops.secrets.course-session.sopsFile = ../../secrets/default.yaml;

  home.sessionVariables = {
    COURSE_API_URL = "https://api.nnn.ed.nico/";
    COURSE_PAPI_URL = "https://papi.nnn.ed.nico/";
    COURSE_WEB_URL = "https://www.nnn.ed.nico/";
    COURSE_COOKIE_NAME = "_zane_session";
  };
}
