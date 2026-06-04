_final: prev: {
  python313Packages = prev.python313Packages.overrideScope (
    _pyFinal: pyPrev: {
      speechrecognition = pyPrev.speechrecognition.overridePythonAttrs {
        doCheck = false;
      };
    }
  );
}
