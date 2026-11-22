{ inputs }:

{
  ax = final: _prev: {
    ax = inputs.ax.packages.${final.stdenv.hostPlatform.system}.default;
  };

  llm-agents = final: _prev: {
    llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};
  };

  # Built with rustowl-flake's own nixpkgs, matching nix-community.cachix.org.
  rustowl = final: _prev: {
    inherit (inputs.rustowl-flake.packages.${final.stdenv.hostPlatform.system}) rustowl rustowl-nvim;
  };

  stable = _final: prev: {
    stable = import inputs.nixpkgs-stable {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };

  patches = final: prev: {
    # keifu 0.3.0 pins libgit2 1.8 in Cargo.lock. The new Cargo setup hook
    # disables vendoring, but nixpkgs supplies a newer incompatible libgit2.
    keifu = prev.keifu.overrideAttrs (old: {
      preBuild = (old.preBuild or "") + ''
        export LIBGIT2_NO_VENDOR=0
      '';
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
