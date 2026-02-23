{
  sources,
  final,
  prev,
}:
{
  similarity-ts = final.rustPlatform.buildRustPackage {
    inherit (sources.similarity-ts) pname version src;

    cargoLock = sources.similarity-ts.cargoLock."Cargo.lock";

    buildAndTestSubdir = "crates/similarity-ts";

    doCheck = false;

    meta = with final.lib; {
      description = "CLI tool for detecting code duplication in TypeScript/JavaScript projects";
      homepage = "https://github.com/mizchi/similarity";
      license = licenses.mit;
      mainProgram = "similarity-ts";
    };
  };
}
