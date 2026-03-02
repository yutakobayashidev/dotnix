{ pkgs, ... }:
{
  home.packages =
    (with pkgs.llm-agents; [
      claude-code
      ccusage
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
