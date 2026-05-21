{ pkgs, ... }:

let
  inherit (pkgs) vscode-extensions vscode-utils;

  fileNestingSettings = builtins.fromJSON (
    builtins.readFile (pkgs.callPackage ./vscode-file-nesting-config { })
  );

  marketplaceExtensions = vscode-utils.extensionsFromVscodeMarketplace [
    {
      publisher = "dsznajder";
      name = "es7-react-js-snippets";
      version = "4.4.3";
      sha256 = "1xyhysvsf718vp2b36y1p02b6hy1y2nvv80chjnqcm3gk387jps0";
    }
    {
      publisher = "1YiB";
      name = "rust-bundle";
      version = "1.0.0";
      sha256 = "19d53vkmn08rvysg934xdhhxbiwd52ha1dwjfwhnaan1s9gwfsqv";
    }
    {
      publisher = "JuanBlanco";
      name = "solidity";
      version = "0.0.187";
      sha256 = "06qny9faj33vrwl4qqv3fa4i7swpz8r6c995p1mm5v3f40nlci9v";
    }
    {
      publisher = "mushan";
      name = "vscode-paste-image";
      version = "1.0.4";
      sha256 = "1wkplvrn31vly5gw35hlgpjpxgq3dzb16hz64xcf77bwcqfnpakb";
    }
    {
      publisher = "alfredbirk";
      name = "tailwind-documentation";
      version = "0.1.16";
      sha256 = "03yyranny5pjdnk0m3hh4qwi80flcz1gy7bf8ml76lc9f1d7ybl4";
    }
    {
      publisher = "dustypomerleau";
      name = "rust-syntax";
      version = "0.6.1";
      sha256 = "0rccp8njr13jzsbr2jl9hqn74w7ji7b2spfd4ml6r2i43hz9gn53";
    }
    {
      publisher = "rangav";
      name = "vscode-thunder-client";
      version = "2.39.8";
      sha256 = "1wwfk8jaxl6f8famg3q3lf9df78wabjrh1bifix4xxxjingx2j13";
    }
    {
      publisher = "moonbit";
      name = "moonbit-lang";
      version = "0.7.2026021303";
      sha256 = "1f4i57496f7vcf6cnc7ys3wxvf24fkqnqry0sydw84dwym1ida05";
    }
    {
      publisher = "figma";
      name = "figma-vscode-extension";
      version = "0.4.1";
      sha256 = "10h2mmmb39mbj0gxx2hss4ciyp9x2hhmpsi8v3w3alka2agqp2nr";
    }
    {
      publisher = "wayou";
      name = "vscode-todo-highlight";
      version = "1.0.5";
      sha256 = "1sg4zbr1jgj9adsj3rik5flcn6cbr4k2pzxi446rfzbzvcqns189";
    }
    {
      publisher = "zenn";
      name = "zenn-preview";
      version = "0.3.0";
      sha256 = "13bavmp7wnba3ma2q1kawp2j0s3fqv444baam49dkmazk0ss8q42";
    }
    {
      publisher = "oven";
      name = "bun-vscode";
      version = "0.0.32";
      sha256 = "1r8gc4m5ylyszr1vrhf8xp93siqcpaxdcmjmhlazrrw5g0wfwnjn";
    }
    {
      publisher = "artdiniz";
      name = "quitcontrol-vscode";
      version = "4.0.0";
      sha256 = "1932g6aqll0mjm2w2wjj726f99q25912mlkfqr9353c7xsz467r4";
    }
    {
      publisher = "janisdd";
      name = "vscode-edit-csv";
      version = "0.11.8";
      sha256 = "1jkrvfc7igc7qqr6zxbmd50vwb70gxq8wis6c1v8wz2c7qgz7gas";
    }
    {
      publisher = "unthrottled";
      name = "doki-theme";
      version = "88.1.18";
      sha256 = "1wv5w8y6c1jwb41lxs1qw7manxmh7ynac7wapxvspnyl7v1asf7c";
    }
    {
      publisher = "mosapride";
      name = "zenkaku";
      version = "0.0.3";
      sha256 = "0abbgg0mjgfy5495ah4iiqf2jck9wjbflvbfwhwll23g0wdazlr5";
    }
    {
      publisher = "satokaz";
      name = "vscode-bs-ctrlchar-remover";
      version = "0.0.7";
      sha256 = "1bgz9sd0bb2asn1py1njk3qbplqfkqdp50ilhswgkdgv96ag5qr3";
    }
    {
      publisher = "mquandalle";
      name = "graphql";
      version = "0.1.2";
      sha256 = "0z0y4b9n6f3mnk0baki8q18i4gq35zdgy00dlj24zjpz60f6s46j";
    }
    {
      publisher = "ms-playwright";
      name = "playwright";
      version = "1.1.19";
      sha256 = "1xppas4qla2bsppb89ks4mnrby2g3gra4irabnimkcmaz4m3wr9p";
    }
    {
      publisher = "ms-python";
      name = "vscode-python-envs";
      version = "1.30.0";
      sha256 = "0mpsn1bkcxnyf0kki4xfmvslgdpipn0bwf4xl45afwfxw25rp5l7";
    }
    {
      publisher = "oxc";
      name = "oxc-vscode";
      version = "1.55.0";
      sha256 = "1907iqdkcrypvlc7v2c40s925a9v333amnw633f4l05m0zsqs2s0";
    }
    {
      publisher = "SuhelMakkad";
      name = "shadcn-ui";
      version = "0.1.33";
      sha256 = "1a262v0h6xpqkg5kc85g8lbq6lzwkrhf0azpg15bbrq0dz4wpf3p";
    }
  ];

  # Not managed here because their current installed versions could not be fetched
  # from the public VS Code Marketplace during migration:
  #
  # - anysphere.cursorpyright 1.0.10: Cursor/AnySphere-managed extension.
  # - anysphere.pyright 1.1.327: Cursor/AnySphere-managed extension.
  # - anysphere.remote-containers 1.0.32: Cursor/AnySphere-managed extension.
  # - anysphere.remote-ssh 1.0.40: Cursor/AnySphere-managed extension.
  # - amazonwebservices.codewhisperer-for-command-line-companion 1.19.7: Marketplace returned Resource not found for this version.
  # - ygkn.storybook-opener 4.0.1: Marketplace returned Resource not found for this version.
  nixpkgsExtensions = [
    vscode-extensions."1Password".op-vscode
    vscode-extensions."42crunch".vscode-openapi
    vscode-extensions.alefragnani.project-manager
    vscode-extensions.anthropic.claude-code
    vscode-extensions.astro-build.astro-vscode
    vscode-extensions.biomejs.biome
    vscode-extensions.bradlc.vscode-tailwindcss
    vscode-extensions.christian-kohler.path-intellisense
    vscode-extensions.dart-code.dart-code
    vscode-extensions.dart-code.flutter
    vscode-extensions.dbaeumer.vscode-eslint
    vscode-extensions.denoland.vscode-deno
    vscode-extensions.editorconfig.editorconfig
    vscode-extensions.esbenp.prettier-vscode
    vscode-extensions.formulahendry.auto-close-tag
    vscode-extensions.github.copilot
    vscode-extensions.github.copilot-chat
    vscode-extensions.github.github-vscode-theme
    vscode-extensions.github.vscode-github-actions
    vscode-extensions.github.vscode-pull-request-github
    vscode-extensions.hashicorp.terraform
    vscode-extensions.humao.rest-client
    vscode-extensions.jnoortheen.nix-ide
    vscode-extensions.jock.svg
    vscode-extensions.mhutchie.git-graph
    vscode-extensions.ms-azuretools.vscode-docker
    vscode-extensions.ms-azuretools.vscode-containers
    vscode-extensions.ms-python.black-formatter
    vscode-extensions.ms-python.debugpy
    vscode-extensions.ms-python.python
    vscode-extensions.ms-python.vscode-pylance
    vscode-extensions.ms-toolsai.jupyter
    vscode-extensions.ms-toolsai.jupyter-keymap
    vscode-extensions.ms-toolsai.jupyter-renderers
    vscode-extensions.ms-toolsai.vscode-jupyter-cell-tags
    vscode-extensions.ms-toolsai.vscode-jupyter-slideshow
    vscode-extensions.ms-vscode-remote.remote-containers
    vscode-extensions.ms-vscode.hexeditor
    vscode-extensions.ms-vscode.live-server
    vscode-extensions.ms-vsliveshare.vsliveshare
    vscode-extensions.myriad-dreamin.tinymist
    vscode-extensions.pkief.material-icon-theme
    vscode-extensions.prisma.prisma
    vscode-extensions.redhat.vscode-yaml
    vscode-extensions.rust-lang.rust-analyzer
    vscode-extensions.saoudrizwan.claude-dev
    vscode-extensions.seatonjiang.gitmoji-vscode
    vscode-extensions.shopify.ruby-lsp
    vscode-extensions.shyykoserhiy.vscode-spotify
    vscode-extensions.spywhere.guides
    vscode-extensions.svelte.svelte-vscode
    vscode-extensions.streetsidesoftware.code-spell-checker
    vscode-extensions.tailscale.vscode-tailscale
    vscode-extensions.tamasfe.even-better-toml
    vscode-extensions.tomoki1207.pdf
    vscode-extensions.unifiedjs.vscode-mdx
    vscode-extensions.vitest.explorer
    vscode-extensions.vue.volar
    vscode-extensions.wakatime.vscode-wakatime
    vscode-extensions.wingrunr21.vscode-ruby
    vscode-extensions.wix.vscode-import-cost
    vscode-extensions.yoavbls.pretty-ts-errors
    vscode-extensions.ziglang.vscode-zig
  ];

in
{
  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;

    profiles.default = {
      userSettings = import ./settings.nix { inherit fileNestingSettings; };
      keybindings = import ./keybindings.nix;
      extensions = nixpkgsExtensions ++ marketplaceExtensions;
    };
  };
}
