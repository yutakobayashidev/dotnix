{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "similarity-ts";
  version = "0.4.2";

  src = fetchFromGitHub {
    owner = "mizchi";
    repo = "similarity";
    rev = "v${version}";
    hash = "sha256-/rvLl2SaeB0AHEbjkT/XTvVZHHoRaau44SteImRWguE=";
  };

  cargoHash = "sha256-d2PZ65uudYPZv1ZtILF+7Zt+sv4LcZKUkeFLQkk7uPA=";

  buildAndTestSubdir = "crates/similarity-ts";

  doCheck = false;

  meta = with lib; {
    description = "CLI tool for detecting code duplication in TypeScript/JavaScript projects";
    homepage = "https://github.com/mizchi/similarity";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "similarity-ts";
  };
}
