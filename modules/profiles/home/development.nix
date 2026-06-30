{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  bird = inputs.bird.packages.${pkgs.stdenv.hostPlatform.system}.bird;
  edcb-tools = inputs.edcb-tools.packages.${pkgs.stdenv.hostPlatform.system}.edcb-tools;
in
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
      bird
      bumblebee
      cloc
      defuddle
      difit
      discrawl
      edcb-tools
      gctx
      gogcli
      insomnia
      jj-desc
      jujutsu
      llm-agents.herdr
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
      python313Packages.markitdown
    ];
}
