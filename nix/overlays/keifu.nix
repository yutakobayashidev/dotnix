final: prev: {
  keifu = final.rustPlatform.buildRustPackage rec {
    pname = "keifu";
    version = "0.3.0";

    src = final.fetchFromGitHub {
      owner = "trasta298";
      repo = "keifu";
      rev = "v${version}";
      hash = "sha256-Srw71Rswafu70kKI36dY1PtB4BQhpTYYzqbrWJuvaUM=";
    };

    cargoHash = "sha256-Ga405TV1uDSZbADrV+3aAeLDRfdPFHzdxxTEDu+f+b4=";

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
      maintainers = [ ];
      mainProgram = "keifu";
    };
  };
}
