{ ... }:

{
  imports = [
    ../../home/coding-agents/agent-browser
    ../../home/coding-agents/agent-skills
    ../../home/coding-agents/claude-code
    ../../home/coding-agents/codex
    ../../home/coding-agents/continues
    ../../home/coding-agents/copilot-cli
    ../../home/coding-agents/cursor-agent
    ../../home/coding-agents/entire
    ../../home/coding-agents/grok
    ../../home/coding-agents/opencode
    ../../home/coding-agents/spec-kit
    ../../../applications/gh
    ../../../applications/jj
  ];

  my.programs.agent-browser.enable = true;
  my.programs.agent-skills.enable = true;
  my.programs.claude-code.enable = true;
  my.programs.codex.enable = true;
  my.programs.continues.enable = true;
  my.programs.copilot-cli.enable = true;
  my.programs.cursor-agent.enable = true;
  my.programs.entire.enable = true;
  my.programs.grok.enable = true;
  my.programs.opencode.enable = true;
  my.programs.spec-kit.enable = true;
}
