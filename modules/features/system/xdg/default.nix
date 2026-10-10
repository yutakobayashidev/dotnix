_:

{
  flake.modules.homeManager.xdg =
    { config, lib, ... }:
    let
      cfg = config.ext.xdg;
    in
    {
      options.ext.xdg = {
        enable = lib.mkEnableOption "XDG desktop integration";
        aws-cli.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        cuda.enable = lib.mkOption {
          type = lib.types.bool;
          default = config.nixpkgs.config.cudaSupport or false;
        };
        nodejs.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        python.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        rust.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        home = {
          sessionVariables = lib.mkMerge [
            (lib.mkIf cfg.aws-cli.enable {
              AWS_CONFIG_FILE = "${config.xdg.configHome}/aws/config";
              AWS_SHARED_CREDENTIALS_FILE = "${config.xdg.configHome}/aws/credentials";
            })
            (lib.mkIf cfg.cuda.enable {
              CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
            })
            (lib.mkIf cfg.nodejs.enable {
              NODE_REPL_HISTORY = "${config.xdg.dataHome}/node_repl_history";
              NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
            })
            (lib.mkIf cfg.python.enable {
              PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonstartup";
              JUPYTER_PLATFORM_DIRS = 1;
            })
            (lib.mkIf cfg.rust.enable {
              CARGO_HOME = "${config.xdg.dataHome}/cargo";
              RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
            })
          ];

          sessionVariablesExtra = lib.mkIf cfg.python.enable ''
            [ ! -f ${config.xdg.cacheHome}/python/history ] && mkdir -p ${config.xdg.cacheHome}/python && touch ${config.xdg.cacheHome}/python/history
          '';
        };

        xdg.configFile = lib.mkMerge [
          (lib.mkIf cfg.nodejs.enable {
            "npm/npmrc".source = ./npmrc;
          })
          (lib.mkIf cfg.python.enable {
            "python/pythonstartup".source = ./pythonstartup;
          })
        ];

        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "text/html" = "firefox.desktop";
            "x-scheme-handler/http" = "firefox.desktop";
            "x-scheme-handler/https" = "firefox.desktop";
            "x-scheme-handler/about" = "firefox.desktop";
            "x-scheme-handler/unknown" = "firefox.desktop";
          };
        };
      };
    };
}
