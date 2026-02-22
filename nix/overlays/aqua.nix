final: prev: {
  aqua = final.buildGoModule rec {
    pname = "aqua";
    version = "2.55.3";

    src = final.fetchFromGitHub {
      owner = "aquaproj";
      repo = "aqua";
      rev = "v${version}";
      hash = "sha256-7m7lDMUeN4m3yUMelwVZyC+cWhwD20/FUbbb7YfNWfw=";
    };

    vendorHash = "sha256-YdbHccVVWJ/1eVzTaXSV+PeDQNiZhOnJGd+dtOtmKac=";

    # Skip tests that require /bin/date and network access
    doCheck = false;

    ldflags = [
      "-s"
      "-w"
      "-X=github.com/aquaproj/aqua/v2/pkg/domain.version=${version}"
    ];

    meta = with final.lib; {
      description = "Declarative CLI Version manager written in Go";
      homepage = "https://aquaproj.github.io/";
      license = licenses.mit;
      maintainers = [ ];
      mainProgram = "aqua";
    };
  };
}
