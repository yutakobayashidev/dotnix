{ inputs }:

{
  ax = final: _prev: {
    ax = inputs.ax.packages.${final.stdenv.hostPlatform.system}.default;
  };

  llm-agents = final: _prev: {
    llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};
  };

  stable = _final: prev: {
    stable = import inputs.nixpkgs-stable {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
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

  };
}
