# Build against the actual Home Manager graph; only its file-linking phases run.
{ configuration }:
let
  inherit (configuration) config pkgs;
  inherit (pkgs) lib;
  targets = config.programs.agent-skills.targets;
  enabledTargets = lib.filterAttrs (_: target: target.enable) targets;
in
assert
  builtins.attrNames enabledTargets == [
    "claude"
    "codex"
    "pi"
  ];
assert builtins.all (target: target.structure == "link") (builtins.attrValues enabledTargets);
assert !(config.home.activation ? agent-skills);
assert config.home.fileActivator == "legacy";
pkgs.runCommand "grok-bot-skills-reapplication-test"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.findutils
      pkgs.gettext
      pkgs.diffutils
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" "$TMPDIR/generation"
    export newGenPath="$TMPDIR/generation"
    ln -s ${config.home-files} "$newGenPath/home-files"
    ${config.lib.bash.initHomeManagerLib}

    # Reproduce the already managed Claude plugin and an unrelated local skill.
    mkdir -p "$HOME/.config/claude/skills/local-skill"
    printf 'keep local skill\n' > "$HOME/.config/claude/skills/local-skill/SKILL.md"
    ln -s ${config.home-files}/.config/claude/skills/claude-code-home-manager \
      "$HOME/.config/claude/skills/claude-code-home-manager"
    test ! -e "$HOME/.config/claude/skills/.agent-skills-managed.json"
    for directory in .claude/skills .codex/skills .cursor/skills .agents/skills; do
      mkdir -p "$HOME/$directory"
      printf 'keep shared files\n' > "$HOME/$directory/sentinel"
    done

    apply_files() {
      ${config.home.activation.checkLinkTargets.data}
      ${config.home.activation.linkGeneration.data}
    }

    check_skills() {
      for directory in .config/claude/skills .config/codex/skills .pi/agent/skills; do
        test -r "$HOME/$directory/writing-for-agents/SKILL.md"
      done
      test -r "$HOME/.config/claude/skills/claude-code-home-manager/.claude-plugin/plugin.json"
      test "$(cat "$HOME/.config/claude/skills/local-skill/SKILL.md")" = 'keep local skill'
      for directory in .claude/skills .codex/skills .cursor/skills .agents/skills; do
        test "$(cat "$HOME/$directory/sentinel")" = 'keep shared files'
        test "$(find "$HOME/$directory" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1
      done
    }

    unset CLAUDE_CONFIG_DIR CODEX_HOME AGENT_SKILLS_FORCE
    apply_files
    check_skills

    export oldGenPath="$newGenPath"
    export CLAUDE_CONFIG_DIR="$HOME/.config/claude"
    export CODEX_HOME="$HOME/.config/codex"
    apply_files
    check_skills
    touch "$out"
  ''
