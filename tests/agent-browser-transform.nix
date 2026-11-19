{ configuration }:
let
  inherit (configuration) config pkgs;
  inherit (pkgs) lib;
  source = config.programs.agent-skills.sources.agent-browser;
  original = builtins.readFile "${source.path}/${source.subdir}/agent-browser/SKILL.md";
  transform = config.programs.agent-skills.skills.explicit.agent-browser.transform;
  bin = builtins.unsafeDiscardStringContext (lib.getExe pkgs.llm-agents.agent-browser);
  transformed = transform { inherit original; };
  legacy = transform {
    original =
      builtins.replaceStrings
        [ "allowed-tools: Bash(agent-browser:*)" ]
        [ "allowed-tools: Bash(agent-browser:*), Bash(npx agent-browser:*)" ]
        original;
  };
in
assert lib.hasInfix "allowed-tools: Bash(${bin}:*)" transformed;
assert lib.hasInfix "allowed-tools: Bash(${bin}:*)" legacy;
assert !(lib.hasInfix "Bash(npx agent-browser:*)" legacy);
assert lib.hasInfix "${bin} skills get core" transformed;
assert !(lib.hasInfix "npm i -g" transformed);
true
