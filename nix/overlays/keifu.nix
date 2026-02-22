final: prev: {
  keifu = final.rustPlatform.buildRustPackage rec {
    pname = "keifu";
    version = "0.2.3";

    src = final.fetchFromGitHub {
      owner = "trasta298";
      repo = "keifu";
      rev = "v${version}";
      hash = "sha256-8fjR204Wa9LJa9JGQ1CRHDoiHei6P3J81RGgA0G77EA=";
    };

    cargoHash = "sha256-OhNT+IbR1A7QD03/I+ju2h1LArVPL47BnVmit3tNSOA=";

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
