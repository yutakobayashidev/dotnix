{ inputs }:

{
  llm-agents = final: _prev: {
    llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};
  };

  stable = _final: prev: {
    stable = import inputs.nixpkgs-stable {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };

  temporary-fix = _final: prev: {
    python313Packages = prev.python313Packages.overrideScope (
      _pyFinal: pyPrev: {
        speechrecognition = pyPrev.speechrecognition.overridePythonAttrs {
          doCheck = false;
        };
      }
    );

    whipper = prev.whipper.overridePythonAttrs (old: {
      propagatedBuildInputs =
        (prev.lib.remove prev.python3Packages.setuptools old.propagatedBuildInputs)
        ++ [ prev.python3Packages.setuptools_80 ];
    });
  };

  patches = final: prev: {
    gh = final.writeShellApplication {
      name = "gh";
      text = ''
        if [ -z "''${GH_TOKEN:-}" ] && [ -z "''${GITHUB_TOKEN:-}" ]; then
          GH_TOKEN="$(${final.lib.getExe final.ghtkn} get)"
          export GH_TOKEN
        fi

        exec ${final.lib.getExe prev.gh} "$@"
      '';
    };

    session-tts-codex =
      let
        python = prev.python3;
      in
      python.pkgs.buildPythonApplication {
        pname = "session-tts-codex";
        version = "0.1.0";
        src = ../codex/session-tts/python;
        format = "pyproject";
        nativeBuildInputs = with python.pkgs; [
          setuptools
        ];
        propagatedBuildInputs = with python.pkgs; [
          httpx
        ];
        doCheck = false;
      };

    tree-sitter-moonbit-grammar = prev.stdenv.mkDerivation {
      pname = "tree-sitter-moonbit-grammar";
      version = "0-unstable";
      src = prev._tree-sitter-moonbit;
      buildInputs = [ prev.tree-sitter ];
      buildPhase = ''
        cd src
        $CC -shared -fPIC -o parser.so parser.c scanner.c -I .
      '';
      installPhase = ''
        mkdir -p $out/parser
        cp parser.so $out/parser/moonbit.so
        cd ..
        if [ -d queries ]; then
          mkdir -p $out/queries/moonbit
          cp queries/*.scm $out/queries/moonbit/
        fi
      '';
    };
  };
}
