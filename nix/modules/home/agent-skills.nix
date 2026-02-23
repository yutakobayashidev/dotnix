# Agent skills configuration for Claude Code
# https://github.com/Kyure-A/agent-skills-nix
#
# All skills (local and external) are managed here via agent-skills-nix.
# Skills are deployed to ~/.agents (standard location) and ~/.config/claude/skills
{
  pkgs,
  inputs,
  local-skills,
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
        path = inputs.anthropic-skills;
        subdir = "skills";
      };
      # Vercel: skills from vercel-labs/skills
      vercel = {
        path = inputs.vercel-skills;
        subdir = "skills";
      };
      # nextlevelbuilder: UI/UX Pro Max skill
      nextlevelbuilder = {
        path = inputs.ui-ux-pro-max-skill;
        subdir = ".claude/skills";
      };
      # ast-grep: AST-based code search and transform skill
      ast-grep = {
        path = inputs.ast-grep-skill;
        subdir = "ast-grep/skills";
      };
      # Cloudflare: skills from cloudflare/skills
      cloudflare = {
        path = inputs.cloudflare-skills;
        subdir = "skills";
      };
      # HashiCorp: skills from hashicorp/agent-skills (terraform/, packer/ at root)
      hashicorp = {
        path = inputs.hashicorp-agent-skills;
        subdir = ".";
      };
      # Deno: skills from denoland/skills
      deno = {
        path = inputs.deno-skills;
        subdir = "skills";
      };
      # AWS: skills from itsmostafa/aws-agent-skills
      aws = {
        path = inputs.aws-agent-skills;
        subdir = "skills";
      };
      # Obsidian: skills from kepano/obsidian-skills
      obsidian = {
        path = inputs.obsidian-skills;
        subdir = "skills";
      };
    };

    # Enable all local skills
    skills.enableAll = [
      "local"
      "cloudflare"
      "hashicorp"
      "deno"
      "aws"
      "obsidian"
    ];

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
      # ast-grep skills
      ast-grep = {
        from = "ast-grep";
        path = "ast-grep";
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
      # Codex CLI user config (XDG: ~/.config/codex/skills)
      codex = {
        dest = ".config/codex/skills";
        structure = "link";
      };
    };
  };
}
