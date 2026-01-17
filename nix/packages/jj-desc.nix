{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "jj-desc";
  version = "0.4.3";

  src = fetchFromGitHub {
    owner = "tumf";
    repo = "jj-desc";
    rev = "v${version}";
    hash = "sha256-ptenxz97I17xgfSzDKrF/ieOCe7u25i1bZz45nsPExw=";
  };

  cargoHash = "sha256-jhyxSU2FiLQ/uorCVRJxx5nElp7h9nTA4tOiH0msUIw=";

  meta = with lib; {
    description = "Generate meaningful commit descriptions from diffs using LLM";
    homepage = "https://github.com/tumf/jj-desc";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "jj-desc";
  };
}
