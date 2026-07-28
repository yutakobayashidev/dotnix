{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "development";

  home =
    {
      lib,
      pkgs,
      ...
    }:

    {
      my.programs = {
        agent-browser.enable = lib.mkDefault true;
        agent-skills.enable = lib.mkDefault true;
        ax.enable = lib.mkDefault true;
        babashka.enable = lib.mkDefault true;
        claude-code.enable = lib.mkDefault true;
        codex.enable = lib.mkDefault true;
        mcp.enable = lib.mkDefault true;
        continues.enable = lib.mkDefault true;
        copilot-cli.enable = lib.mkDefault true;
        cursor-agent.enable = lib.mkDefault true;
        gog.enable = lib.mkDefault true;
        grok.enable = lib.mkDefault true;
        herdr.enable = lib.mkDefault true;
        gh.enable = lib.mkDefault true;
        jj.enable = lib.mkDefault true;
        markitdown.enable = lib.mkDefault true;
        opencode.enable = lib.mkDefault true;
        oracle.enable = lib.mkDefault true;
        pi.enable = lib.mkDefault true;
        similarity-ts.enable = lib.mkDefault true;
        spec-kit.enable = lib.mkDefault true;
      };

      home.packages =
        with pkgs;
        [
          before-and-after
          bumblebee
          cloc
          difit
          gctx
          insomnia
          jj-desc
          jujutsu
          llm-agents.hunk
          ni
          nil
          nix-init
          repiq
          ruff
          taplo
          vhs
          vulnix
          wabt
          whichllm
        ]
        ++ lib.optionals (pkgs.stdenv.isx86_64 || pkgs.stdenv.isDarwin) [
          bit-vcs
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          android-studio
          android-tools
          arduino-ide
          stable.freecad
          (kicad.override { stable = true; })
          tableplus
        ];
    };
}
