final: prev:
let
  # openssl-sys 0.9.61 is incompatible with OpenSSL 3.x
  openssl_1_1' = final.openssl_1_1.overrideAttrs (old: {
    meta = old.meta // {
      knownVulnerabilities = [ ];
    };
  });
in
{
  tunnelto = final.rustPlatform.buildRustPackage rec {
    pname = "tunnelto";
    version = "0.1.18";

    src = final.fetchFromGitHub {
      owner = "agrinman";
      repo = "tunnelto";
      rev = version;
      hash = "sha256-dCHl5EXjUagOKeHxqb3GlAoSDw0u3tQ4GKEtbFF8OSs=";
    };

    cargoHash = "sha256-Q2uRUekpjhe98Bgn8p8OEGlefe4gO/2qT5nzd5F2VNU=";

    nativeBuildInputs = [ final.pkg-config ];

    buildInputs = [ openssl_1_1' ];

    buildAndTestSubdir = "tunnelto";

    meta = with final.lib; {
      description = "Expose your local web server to the internet with a public URL";
      homepage = "https://github.com/agrinman/tunnelto";
      license = licenses.mit;
      mainProgram = "tunnelto";
    };
  };
}
