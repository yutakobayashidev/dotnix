{
  sources,
  final,
  prev,
}:
{
  jj-desc = final.rustPlatform.buildRustPackage {
    inherit (sources.jj-desc) pname version src;

    cargoLock = sources.jj-desc.cargoLock."Cargo.lock";

    # Skip tests that require API keys
    doCheck = false;

    meta = with final.lib; {
      description = "Generate meaningful commit descriptions from diffs using LLM";
      homepage = "https://github.com/tumf/jj-desc";
      license = licenses.mit;
      mainProgram = "jj-desc";
    };
  };
}
