{
  fetchFromGitHub,
  nodejs,
  stdenvNoCC,
  ...
}:

stdenvNoCC.mkDerivation {
  pname = "vscode-file-nesting-config";
  version = "unstable-2026-01-30";

  src = fetchFromGitHub {
    owner = "antfu";
    repo = "vscode-file-nesting-config";
    rev = "e05f5f33a6011e80d177ca1b26f6012aed35f0e0";
    sha256 = "13cr8qjbnj3x6gapxh3256mcyabfaafb5ymzsmfdzz86if29ivpd";
  };

  buildInputs = [ nodejs ];

  dontConfigure = true;
  dontInstall = true;

  buildPhase = ''
    runHook preBuild
    node -e 'require("${./get-config.js}").main()' > "$out"
    runHook postBuild
  '';
}
