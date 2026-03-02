{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    ignores = [
      # Environment
      ".venv"
      ".direnv"

      # macOS
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "Icon"
      "._*"
      ".DocumentRevisions-V100"
      ".fseventsd"
      ".Spotlight-V100"
      ".TemporaryItems"
      ".Trashes"
      ".VolumeIcon.icns"
      ".com.apple.timemachine.donotpresent"
      ".AppleDB"
      ".AppleDesktop"
      "Network Trash Folder"
      "Temporary Items"
      ".apdisk"

      # Python
      "__pycache__/"
      "*.py[cod]"
      "*$py.class"
      "*.so"
      ".Python"
      "build/"
      "develop-eggs/"
      "dist/"
      "downloads/"
      "eggs/"
      ".eggs/"
      "lib64/"
      "parts/"
      "sdist/"
      "var/"
      "wheels/"
      "pip-wheel-metadata/"
      "share/python-wheels/"
      "*.egg-info/"
      ".installed.cfg"
      "*.egg"
      "MANIFEST"
      "*.manifest"
      "*.spec"
      "pip-log.txt"
      "pip-delete-this-directory.txt"
      "htmlcov/"
      ".tox/"
      ".nox/"
      ".coverage"
      ".coverage.*"
      ".cache"
      "nosetests.xml"
      "coverage.xml"
      "*.cover"
      "*.py,cover"
      ".hypothesis/"
      ".pytest_cache/"
      "*.mo"
      "*.pot"
      "*.log"
      "local_settings.py"
      "db.sqlite3"
      "db.sqlite3-journal"
      "instance/"
      ".webassets-cache"
      ".scrapy"
      "docs/_build/"
      "target/"
      ".ipynb_checkpoints"
      "profile_default/"
      "ipython_config.py"
      ".python-version"
      "__pypackages__/"
      "celerybeat-schedule"
      "celerybeat.pid"
      "*.sage.py"
      ".env"
      "env/"
      "venv/"
      "ENV/"
      "env.bak/"
      "venv.bak/"
      ".spyderproject"
      ".spyproject"
      ".ropeproject"
      "/site"
      ".mypy_cache/"
      ".dmypy.json"
      "dmypy.json"
      ".pyre/"

      # Claude Code
      "**/.claude/settings.local.json"
      "**/CLAUDE.local.md"

      # Continues
      ".continues-handoff.md"
    ];
    settings = {
      alias = {
        clone = "clone --recursive";
        logg = "log --graph --abbrev-commit --pretty=format:\"%C(yellow)%h%C(reset) - %C(cyan)%ad%C(reset) %C(green)(%ar)%C(reset)%C(auto)%d%C(reset)%n          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%n\"";
        swor = ''!f() { local -r ref=$(git branch -r | fzf); git sw "''${1:-''${ref#*/}}" $ref; }; f'';
        swf = "!git branch -a | fzf | xargs git switch";
        sms = "submodule foreach \"git status\"";
        root = "rev-parse --show-toplevel";
        uncommit = "reset HEAD^";
        recommit = "commit -c ORIG_HEAD";
      };
      user = {
        name = "yutakobayashidev";
        email = "hi@yutakobayashi.com";
      };
      push = {
        default = "simple";
        autoSetupRemote = true;
        useForceIfIncludes = true;
      };
      commit.verbose = true;
      rebase = {
        autoStash = true;
        autoSquash = true;
        updateRefs = true;
      };
      merge = {
        ff = false;
        conflictstyle = "zdiff3";
      };
      fetch = {
        writeCommitGraph = true;
        prune = true;
        pruneTags = true;
        all = true;
      };
      pull.rebase = true;
      init.defaultBranch = "main";
      column.ui = "auto";
      branch.sort = "-committerdate";
      help.autocorrect = "prompt";
      rerere = {
        enabled = true;
        autoupdate = true;
      };
      wt.basedir = ".git/worktree";
      wt.remover = "trash";
    };
  };
}
