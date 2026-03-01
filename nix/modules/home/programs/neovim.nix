{
  config,
  lib,
  pkgs,
  helpers,
  dotfilesDir,
  ...
}:

let
  treesitterGrammars = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
  telescopeFzfNative = pkgs.vimPlugins.telescope-fzf-native-nvim;
  nvimDotfilesDir = "${dotfilesDir}/nvim";
  nvimConfigDir = "${config.xdg.configHome}/nvim";
in
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    withNodeJs = true;

    extraPackages = with pkgs; [
      prettierd
      eslint_d
      git
      gcc
      gnumake
      vtsls
      pretty-ts-errors-markdown
      version-lsp

      # Rust
      rustowl

      # Node.js-based language servers
      astro-language-server
      emmet-language-server
      prisma-language-server
      stylelint
      stylelint-lsp
      svelte-language-server
      tailwindcss-language-server
      vscode-langservers-extracted
      vue-language-server
      yaml-language-server
    ];

    extraWrapperArgs = [
      "--set"
      "TREESITTER_GRAMMARS"
      "${treesitterGrammars}"
      "--set"
      "TELESCOPE_FZF_NATIVE"
      "${telescopeFzfNative}"
      "--set"
      "PRETTY_TS_ERRORS_BIN"
      "${pkgs.pretty-ts-errors-markdown}/bin/pretty-ts-errors-markdown"
    ];
  };

  home.activation.linkNvimConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${helpers.activation.mkLinkForce}
    link_force "${nvimDotfilesDir}" "${nvimConfigDir}"
  '';

  home.activation.restoreNeovimPlugins = lib.hm.dag.entryAfter [ "linkNvimConfig" ] ''
    LAZY_DIR="$HOME/.local/share/nvim/lazy"
    LAZY_LOCK="${nvimDotfilesDir}/lazy-lock.json"
    LAZY_LOCK_TIMESTAMP="$LAZY_DIR/.lazy-lock-timestamp"

    if [[ ! -f "$LAZY_LOCK_TIMESTAMP" ]] || [[ "$LAZY_LOCK" -nt "$LAZY_LOCK_TIMESTAMP" ]]; then
      ${pkgs.bash}/bin/bash \
        ${./check.sh} \
        "${nvimDotfilesDir}" \
        "$LAZY_DIR" \
        ${pkgs.neovim}/bin/nvim
    fi
  '';
}
