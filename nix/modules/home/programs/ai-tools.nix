{ pkgs, ... }:
{
  home.packages =
    (with pkgs.llm-agents; [
      claude-code
      ccusage
      copilot-cli
      opencode
      rtk
      vibe-kanban
      cursor-agent
      agent-browser
      entire
    ])
    ++ (with pkgs; [
      continues
    ]);
}
