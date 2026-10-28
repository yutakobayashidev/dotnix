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
    # Native expiring credentials require gh >= 2.103.0.
    gh = prev.gh.overrideAttrs (_: {
      version = "2.103.2";
      src = final.fetchFromGitHub {
        owner = "cli";
        repo = "cli";
        tag = "v2.103.2";
        hash = "sha256-g79A0s6PZdALB9aWVZV12Om/2uKVE1Zac2aFkqwa7MQ=";
        postCheckout = ''
          git -C "$out" log -1 --pretty=%ct > $out/SOURCE_DATE_EPOCH
        '';
      };
      vendorHash = "sha256-e9E2iTwF8kYNgW7Vs5upQBD2VT2lJ4dZcUDUk+igq/Y=";
    });

    session-tts =
      let
        python = prev.python3;
      in
      python.pkgs.buildPythonApplication {
        pname = "session-tts";
        version = "0.1.0";
        src = ../codex/session-tts/python;
        format = "pyproject";
        nativeBuildInputs = with python.pkgs; [
          setuptools
        ];
        propagatedBuildInputs = with python.pkgs; [
          httpx
        ];
        makeWrapperArgs = [
          "--set"
          "SESSION_TTS_PLAYER"
          (
            if final.stdenv.hostPlatform.isDarwin then
              "/usr/bin/afplay"
            else
              final.lib.getExe' final.pipewire "pw-play"
          )
        ];
        doCheck = false;
      };

  };
}
