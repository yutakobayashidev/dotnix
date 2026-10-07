{
  lib,
  neovim-unwrapped,
  wrapNeovimUnstable,
  vimPlugins,

  # Runtime dependencies
  astro-language-server,
  cucumber-language-server,
  elmPackages,
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
  languageServers = [
    # Elm
    elmPackages.elm-language-server

    # Fennel
    fennel-ls

    # JavaScript / TypeScript
    vtsls

    # Node.js-based language servers
    astro-language-server
    cucumber-language-server
    emmet-language-server
    gh-actions-language-server
    prisma-language-server
    stylelint
    svelte-language-server
    tailwindcss-language-server
    vscode-langservers-extracted
    vue-language-server
    yaml-language-server

    # MoonBit
    moonbit-lsp

    # Version files
    version-lsp
  ];

  tools = [
    eslint_d
    gcc
    git
    gnumake
    luaPackages.fennel
    prettierd
    pretty-ts-errors-markdown

    # Elm
    elmPackages.elm
    elmPackages.elm-format
    elmPackages.elm-review
    elmPackages.elm-test

    # Rust
    rustowl
  ];

  pluginPaths = {
    DOTNIX_NVIM_LAZY = vimPlugins.lazy-nvim;
    DOTNIX_NVIM_NFNL = vimPlugins.nfnl;
    RUSTOWL_NVIM = rustowl-nvim;
    TELESCOPE_FZF_NATIVE = vimPlugins.telescope-fzf-native-nvim;
    TREESITTER_GRAMMARS = vimPlugins.nvim-treesitter.withAllGrammars;
    TREESITTER_MOONBIT = tree-sitter-moonbit-grammar;
  };

  wrapperEnv = pluginPaths // {
    PRETTY_TS_ERRORS_BIN = "${pretty-ts-errors-markdown}/bin/pretty-ts-errors-markdown";
  };

  extraWrapperArgs = [
    "--suffix"
    "PATH"
    ":"
    (lib.makeBinPath (languageServers ++ tools))
  ]
  ++ lib.flatten (
    lib.mapAttrsToList (name: value: [
      "--set"
      name
      (toString value)
    ]) wrapperEnv
  );
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

  wrapperArgs = extraWrapperArgs;
}
