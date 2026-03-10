final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
  version = "0.28.0";
  target =
    {
      "x86_64-linux" = "linux-x64";
      "aarch64-darwin" = "darwin-arm64";
    }
    .${system};
  hash =
    {
      "x86_64-linux" = "sha256-Zl1hHocfLKoc5Qg1dBLPhlXHkVEaj2/5m8YfkkPS3SI=";
      "aarch64-darwin" = "sha256-NrOObFOtPWP5rZViugeoZaSjiSHtJpvNEQ/lAB46B6M=";
    }
    .${system};
in
{
  bit-vcs = prev.stdenv.mkDerivation {
    pname = "bit-vcs";
    inherit version;
    src = prev.fetchurl {
      url = "https://github.com/bit-vcs/bit/releases/download/v${version}/bit-${target}";
      inherit hash;
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/bit
      chmod +x $out/bin/bit
    '';
    meta = with prev.lib; {
      description = "A modern Git implementation in MoonBit";
      homepage = "https://github.com/bit-vcs/bit";
      license = licenses.asl20;
      mainProgram = "bit";
      platforms = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    };
  };
}
