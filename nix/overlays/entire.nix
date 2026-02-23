{
  sources,
  final,
  prev,
}:
{
  entire = final.buildGo126Module rec {
    inherit (sources.entire) pname version src;

    vendorHash = sources.entire.vendorHash;

    subPackages = [ "cmd/entire" ];

    ldflags = [
      "-s"
      "-w"
      "-X=main.version=${final.lib.removePrefix "v" version}"
    ];

    meta = with final.lib; {
      description = "Capture AI agent sessions on every push - git hooks integration for Claude Code and other AI agents";
      homepage = "https://github.com/entireio/cli";
      license = licenses.mit;
      mainProgram = "entire";
    };
  };
}
