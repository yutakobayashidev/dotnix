{
  lib,
  neovim-unwrapped,
  wrapNeovimUnstable,
  vimPlugins,

  # Runtime dependencies
  astro-language-server,
  cucumber-language-server,
  emmet-language-server,
  eslint_d,
  fennel-ls,
  gcc,
  gh-actions-language-server,
  git,
  gnumake,
  luaPackages,
  moonbit-lsp,
  prettierd,
  pretty-ts-errors-markdown,
  prisma-language-server,
  rustowl,
  rustowl-nvim,
  stylelint,
  stylelint-lsp,
  svelte-language-server,
  tailwindcss-language-server,
  tree-sitter-moonbit-grammar,
  version-lsp,
  vscode-langservers-extracted,
  vtsls,
  vue-language-server,
  yaml-language-server,
}:

{
  configRoot ? ./.,
}:

let
  treesitterGrammars = vimPlugins.nvim-treesitter.withAllGrammars;
  telescopeFzfNative = vimPlugins.telescope-fzf-native-nvim;

  runtimePackages = [
    prettierd
    eslint_d
    fennel-ls
    luaPackages.fennel
    git
    gcc
    gnumake
    vtsls
    pretty-ts-errors-markdown
    version-lsp
    moonbit-lsp

    # Rust
    rustowl

    # Node.js-based language servers
    astro-language-server
    cucumber-language-server
    emmet-language-server
    gh-actions-language-server
    prisma-language-server
    stylelint
    stylelint-lsp
    svelte-language-server
    tailwindcss-language-server
    vscode-langservers-extracted
    vue-language-server
    yaml-language-server
  ];
in
wrapNeovimUnstable neovim-unwrapped {
  extraName = "-dotnix";
  viAlias = true;
  vimAlias = true;
  withNodeJs = true;
  withRuby = false;
  withPython3 = false;

  luaRcContent = ''
    vim.opt.runtimepath:prepend('${configRoot}')
    dofile('${configRoot}/init.lua')
  '';

  wrapperArgs = [
    "--suffix"
    "PATH"
    ":"
    (lib.makeBinPath runtimePackages)
    "--set"
    "TREESITTER_GRAMMARS"
    "${treesitterGrammars}"
    "--set"
    "TELESCOPE_FZF_NATIVE"
    "${telescopeFzfNative}"
    "--set"
    "PRETTY_TS_ERRORS_BIN"
    "${pretty-ts-errors-markdown}/bin/pretty-ts-errors-markdown"
    "--set"
    "RUSTOWL_NVIM"
    "${rustowl-nvim}"
    "--set"
    "TREESITTER_MOONBIT"
    "${tree-sitter-moonbit-grammar}"
    "--set"
    "DOTNIX_NVIM_LAZY"
    "${vimPlugins.lazy-nvim}"
    "--set"
    "DOTNIX_NVIM_NFNL"
    "${vimPlugins.nfnl}"
  ];
}
