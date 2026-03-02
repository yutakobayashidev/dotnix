# AI / LLM agent ツール（llm-agents.nix以外）
final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
{
  cage = prev._cage.packages.${system}.default;
}
