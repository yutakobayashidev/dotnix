# Agent skills configuration for Claude Code
# https://github.com/Kyure-A/agent-skills-nix
#
# All skills (local and external) are managed here via agent-skills-nix.
# Skills are deployed to ~/.agents (standard location) and ~/.config/claude/skills
{
  pkgs,
  local-skills,
  anthropic-skills,
  vercel-skills,
  ui-ux-pro-max-skill,
  ...
}:
{
  programs.agent-skills = {
    enable = true;

    # Skill sources
    sources = {
      # Local: skills from this dotfiles repo
      local = {
        path = local-skills;
        subdir = "agents/skills";
      };
      # Anthropic: official skills from anthropics/skills
      anthropic = {
        path = anthropic-skills;
        subdir = "skills";
      };
      # Vercel: skills from vercel-labs/skills
      vercel = {
        path = vercel-skills;
        subdir = "skills";
      };
      # nextlevelbuilder: UI/UX Pro Max skill
      nextlevelbuilder = {
        path = ui-ux-pro-max-skill;
        subdir = ".claude/skills";
      };
    };

    # Enable all local skills
    skills.enableAll = [ "local" ];

    # Enable specific Anthropic skills
    skills.explicit = {
      # Document skills
      docx = {
        from = "anthropic";
        path = "docx";
      };
      pdf = {
        from = "anthropic";
        path = "pdf";
      };
      pptx = {
        from = "anthropic";
        path = "pptx";
      };
      xlsx = {
        from = "anthropic";
        path = "xlsx";
      };
      # Example skills
      frontend-design = {
        from = "anthropic";
        path = "frontend-design";
      };
      skill-creator = {
        from = "anthropic";
        path = "skill-creator";
      };
      webapp-testing = {
        from = "anthropic";
        path = "webapp-testing";
      };
      # Vercel skills
      find-skills = {
        from = "vercel";
        path = "find-skills";
      };
      # nextlevelbuilder skills
      ui-ux-pro-max = {
        from = "nextlevelbuilder";
        path = "ui-ux-pro-max";
      };
    };

    # Deploy to standard skills directories
    targets = {
      # Standard ~/.agents/skills directory
      agents = {
        dest = ".agents/skills";
        structure = "link";
      };
      # Claude Code user config
      claude = {
        dest = ".config/claude/skills";
        structure = "link";
      };
    };
  };
}
