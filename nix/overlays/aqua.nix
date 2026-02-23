{
  sources,
  final,
  prev,
}:
{
  aqua = final.buildGoModule rec {
    inherit (sources.aqua) pname version src;

    vendorHash = sources.aqua.vendorHash;

    # Skip tests that require /bin/date and network access
    doCheck = false;

    ldflags = [
      "-s"
      "-w"
      "-X=github.com/aquaproj/aqua/v2/pkg/domain.version=${final.lib.removePrefix "v" version}"
    ];

    meta = with final.lib; {
      description = "Declarative CLI Version manager written in Go";
      homepage = "https://aquaproj.github.io/";
      license = licenses.mit;
      mainProgram = "aqua";
    };
  };
}
