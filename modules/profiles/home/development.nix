{
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../home/coding-agents/agent-browser
    ../../home/coding-agents/claude-code
    ../../home/coding-agents/codex
    ../../home/coding-agents/common/agent-skills
    ../../home/coding-agents/common/mcp-servers.nix
    ../../home/coding-agents/continues
    ../../home/coding-agents/copilot-cli
    ../../home/coding-agents/cursor-agent
    ../../home/coding-agents/grok
    ../../home/coding-agents/herdr
    ../../home/coding-agents/opencode
    ../../home/coding-agents/pi
    ../../home/coding-agents/spec-kit
    ../../home/development/gh
    ../../home/development/jj
  ];

  my.programs = {
    agent-browser.enable = true;
    agent-skills.enable = true;
    claude-code.enable = true;
    codex.enable = true;
    mcp.enable = true;
    continues.enable = true;
    copilot-cli.enable = true;
    cursor-agent.enable = true;
    grok.enable = true;
    herdr.enable = true;
    gh.enable = true;
    jj.enable = true;
    opencode.enable = true;
    pi.enable = true;
    spec-kit.enable = true;
  };

  home.packages =
    with pkgs;
    [
      babashka
      before-and-after
      bumblebee
      cloc
      difit
      gctx
      gogcli
      insomnia
      jj-desc
      jujutsu
      llm-agents.hunk
      ni
      nil
      nix-init
      repiq
      ruff
      similarity-ts
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
      python313Packages.markitdown
    ];
}
