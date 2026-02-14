{
  lib,
  buildGo126Module,
  fetchFromGitHub,
}:

buildGo126Module rec {
  pname = "entire";
  version = "0.4.4";

  src = fetchFromGitHub {
    owner = "entireio";
    repo = "cli";
    rev = "v${version}";
    hash = "sha256-6/TsSmJ0z72Ta5ZihO06uV4Mik+fFpm8eCa7d5zlq24=";
  };

  vendorHash = "sha256-rh2VhdwNT5XJYCVjj8tnoY7cacEhc/kcxi0NHYFPYO8=";

  subPackages = [ "cmd/entire" ];

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${version}"
  ];

  meta = with lib; {
    description = "Capture AI agent sessions on every push - git hooks integration for Claude Code and other AI agents";
    homepage = "https://github.com/entireio/cli";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "entire";
  };
}
