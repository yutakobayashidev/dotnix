{
  sources,
  final,
  prev,
}:
{
  keifu = final.rustPlatform.buildRustPackage {
    inherit (sources.keifu) pname version src;

    cargoLock = sources.keifu.cargoLock."Cargo.lock";

    nativeBuildInputs = [
      final.pkg-config
      final.perl
    ];

    buildInputs = [
      final.openssl
    ];

    meta = with final.lib; {
      description = "A TUI tool for visualizing Git commit graphs";
      homepage = "https://github.com/trasta298/keifu";
      license = licenses.mit;
      mainProgram = "keifu";
    };
  };
}
