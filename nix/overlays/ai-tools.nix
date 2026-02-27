# AI / LLM agent ツール（llm-agents.nix由来）
final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
{
  inherit (prev._llm-agents.packages.${system})
    claude-code
    ccusage
    codex
    opencode
    vibe-kanban
    cursor-agent
    entire
    ;
  cage = prev._cage.packages.${system}.default;
}
