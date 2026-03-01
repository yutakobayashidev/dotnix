final: prev:
let
  version = "0.3.4";
  sources = {
    x86_64-linux = {
      url = "https://github.com/cordx56/rustowl/releases/download/v${version}/rustowl-x86_64-unknown-linux-gnu";
      hash = "sha256-27qnGsJ8BoczTyzUHpSbX5SIF0XYjpIn46dwuaZzGgM=";
    };
    aarch64-darwin = {
      url = "https://github.com/cordx56/rustowl/releases/download/v${version}/rustowl-aarch64-apple-darwin";
      hash = "sha256-QXpRFk6iuMKLNLSoIpeBPYafQRoJrnbTLUlZ8eIGVj4=";
    };
  };
  src =
    sources.${final.stdenv.hostPlatform.system}
      or (throw "rustowl: unsupported system ${final.stdenv.hostPlatform.system}");
in
{
  rustowl = final.stdenv.mkDerivation {
    pname = "rustowl";
    inherit version;

    src = final.fetchurl {
      inherit (src) url hash;
    };

    dontUnpack = true;

    nativeBuildInputs = final.lib.optionals final.stdenv.hostPlatform.isLinux [
      final.autoPatchelfHook
    ];

    installPhase = ''
      install -Dm755 $src $out/bin/rustowl
    '';

    meta = with final.lib; {
      description = "Visualize ownership and lifetimes in Rust";
      homepage = "https://github.com/cordx56/rustowl";
      license = licenses.mit;
      mainProgram = "rustowl";
      platforms = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    };
  };
}
