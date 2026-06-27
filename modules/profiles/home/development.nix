{ ... }:

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
    ../../../applications/gh
    ../../../applications/jj
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
    opencode.enable = true;
    pi.enable = true;
    spec-kit.enable = true;
  };
}
