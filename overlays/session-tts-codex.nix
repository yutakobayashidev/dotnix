final: prev:
let
  python = prev.python3;
  pythonPackages = python.pkgs;
in
{
  session-tts-codex = pythonPackages.buildPythonApplication {
    pname = "session-tts-codex";
    version = "0.1.0";
    src = ../codex/session-tts/python;
    format = "pyproject";
    nativeBuildInputs = with pythonPackages; [
      setuptools
    ];
    propagatedBuildInputs = with pythonPackages; [
      httpx
    ];
    doCheck = false;
  };
}
