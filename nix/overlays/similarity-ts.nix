final: prev: {
  similarity-ts = final.rustPlatform.buildRustPackage rec {
    pname = "similarity-ts";
    version = "0.5.0";

    src = final.fetchFromGitHub {
      owner = "mizchi";
      repo = "similarity";
      rev = "v${version}";
      hash = "sha256-xYA1o4nmZLo0TY56KOtm2eTR9xL4/uEVTKmFaQT+kCQ=";
    };

    cargoHash = "sha256-r/9Yq1h8i7OWMicK9z36TzUTQRDOk6cND+5RvL045yA=";

    buildAndTestSubdir = "crates/similarity-ts";

    doCheck = false;

    meta = with final.lib; {
      description = "CLI tool for detecting code duplication in TypeScript/JavaScript projects";
      homepage = "https://github.com/mizchi/similarity";
      license = licenses.mit;
      maintainers = [ ];
      mainProgram = "similarity-ts";
    };
  };
}
