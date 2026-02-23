final: prev: {
  entire = final.buildGo126Module rec {
    pname = "entire";
    version = "0.4.5";

    src = final.fetchFromGitHub {
      owner = "entireio";
      repo = "cli";
      rev = "v${version}";
      hash = "sha256-BDke84xQ6t7W+BONQn7r8ZBENNr8oGv8mtJ5unyv0lA=";
    };

    vendorHash = "sha256-zgVdh80aNnvC1oMp/CS0nx4b1y9b0jwVKFotil6kQZ0=";

    subPackages = [ "cmd/entire" ];

    ldflags = [
      "-s"
      "-w"
      "-X=main.version=${version}"
    ];

    meta = with final.lib; {
      description = "Capture AI agent sessions on every push - git hooks integration for Claude Code and other AI agents";
      homepage = "https://github.com/entireio/cli";
      license = licenses.mit;
      maintainers = [ ];
      mainProgram = "entire";
    };
  };
}
