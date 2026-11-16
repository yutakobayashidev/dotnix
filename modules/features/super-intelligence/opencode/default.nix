_:

{
  flake.modules.homeManager."opencode" =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.my.programs.opencode;
      opencode = pkgs.writeShellScriptBin "opencode" ''
        exec ${lib.getExe pkgs.llm-agents.opencode2} "$@"
      '';

      # Adapted from nyanshiba/harness-bonsai at 6e32b7673495966de274a2fb5fb7bd7defc92e8e.
      # Plugin paths and the example Linkding MCP endpoint require separate setup.
      opencodeConfig = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        update = "disable";
        websearch = {
          provider = "parallel";
        };
        default_agent = "plan";
        experimental = {
          subagent_depth = 1;
        };
        agents = {
          plan = {
            permissions = [
              {
                action = "edit";
                resource = "~/.opencode/plan/*";
                effect = "allow";
              }
              {
                action = "webfetch";
                resource = "*";
                effect = "allow";
              }
              {
                action = "websearch";
                resource = "*";
                effect = "allow";
              }
              {
                action = "linkding_*";
                resource = "*";
                effect = "allow";
              }
            ];
          };
          build = {
            mode = "all";
            permissions = [
              {
                action = "shell";
                resource = "*";
                effect = "ask";
              }
              {
                action = "subagent";
                resource = "build";
                effect = "allow";
              }
              {
                action = "external_directory";
                resource = "*";
                effect = "ask";
              }
              {
                action = "external_directory";
                resource = "~/.opencode/plan/**";
                effect = "allow";
              }
              {
                action = "external_directory";
                resource = "/tmp/**";
                effect = "allow";
              }
              {
                action = "edit";
                resource = "*";
                effect = "allow";
              }
            ];
          };
          build-auto = {
            mode = "all";
            permissions = [
              {
                action = "external_directory";
                resource = "*";
                effect = "ask";
              }
              {
                action = "external_directory";
                resource = "/tmp/**";
                effect = "allow";
              }
              {
                action = "read";
                resource = "*.env";
                effect = "allow";
              }
              {
                action = "read";
                resource = "*.env.*";
                effect = "allow";
              }
              {
                action = "subagent";
                resource = "build-auto";
                effect = "allow";
              }
              {
                action = "edit";
                resource = "*";
                effect = "allow";
              }
              {
                action = "shell";
                resource = "*";
                effect = "allow";
              }
            ];
          };
          general = {
            disabled = true;
          };
          explorer = {
            disabled = true;
          };
          websearch-researcher = {
            permissions = [
              {
                action = "webfetch";
                resource = "*";
                effect = "allow";
              }
              {
                action = "websearch";
                resource = "*";
                effect = "allow";
              }
            ];
          };
          linkding-researcher = {
            permissions = [
              {
                action = "webfetch";
                resource = "*";
                effect = "allow";
              }
              {
                action = "websearch";
                resource = "*";
                effect = "allow";
              }
              {
                action = "linkding_*";
                resource = "*";
                effect = "allow";
              }
            ];
          };
          feed-triage = {
            permissions = [
              {
                action = "edit";
                resource = "feed/replies/*";
                effect = "allow";
              }
              {
                action = "webfetch";
                resource = "*";
                effect = "allow";
              }
              {
                action = "websearch";
                resource = "*";
                effect = "allow";
              }
            ];
          };
        };
        providers = {
          ollama.settings.baseURL = "http://x870-stell-legend.tail29d068.ts.net:11434/v1";
          openrouter = {
            env = [
              "OPENROUTER_API_KEY"
            ];
            settings = {
              apiKey = "{env:OPENROUTER_API_KEY}";
            };
          };
          google = {
            name = "Google";
            env = [
              "GEMINI_API_KEY"
            ];
            package = "@opencode-ai/ai/providers/google";
            settings = {
              apiKey = "{env:GEMINI_API_KEY}";
            };
            models = {
              gemma-4-26b-a4b-it = {
                modelID = "gemma-4-26b-a4b-it";
                name = "Gemma 4 26B A4B IT";
              };
              gemma-4-31b-it = {
                modelID = "gemma-4-31b-it";
                name = "Gemma 4 31B IT";
              };
              "gemini-3.5-flash-lite" = {
                modelID = "gemini-3.5-flash-lite";
                name = "Gemini 3.5 Flash Lite";
              };
              "gemini-3.8-flash" = {
                modelID = "gemini-3.8-flash";
                name = "Gemini 3.8 Flash";
              };
            };
          };
          nous = {
            name = "Nous Research";
            env = [
              "NOUS_API_KEY"
            ];
            package = "@opencode-ai/ai/providers/openai-compatible";
            settings = {
              baseURL = "https://inference-api.nousresearch.com/v1";
              apiKey = "{env:NOUS_API_KEY}";
            };
            models = {
              "longcat-2.0" = {
                modelID = "meituan/longcat-2.0:free";
                name = "LongCat 2.0";
              };
            };
          };
          nvidia = {
            name = "NVIDIA NIM";
            env = [
              "NVIDIA_API_KEY"
            ];
            package = "@opencode-ai/ai/providers/openai-compatible";
            settings = {
              baseURL = "https://integrate.api.nvidia.com/v1";
              apiKey = "{env:NVIDIA_API_KEY}";
              setCacheKey = false;
            };
          };
          bai = {
            name = "b.ai";
            env = [
              "BAI_API_KEY"
            ];
            package = "@opencode-ai/ai/providers/openai-compatible";
            settings = {
              baseURL = "https://api.b.ai/v1";
              apiKey = "{env:BAI_API_KEY}";
            };
            models = {
              deepseek-v4-flash = {
                modelID = "deepseek-v4-flash";
                name = "DeepSeek V4 Flash";
                compatibility = {
                  reasoningField = "reasoning_content";
                };
                variants = [
                  {
                    id = "low";
                    settings = {
                      reasoningEffort = "low";
                    };
                  }
                  {
                    id = "high";
                    settings = {
                      reasoningEffort = "high";
                    };
                  }
                  {
                    id = "max";
                    settings = {
                      reasoningEffort = "max";
                    };
                  }
                ];
              };
              "deepseek-v4.1-flash" = {
                modelID = "deepseek-v4.1-flash";
                name = "DeepSeek V4.1 Flash";
                compatibility = {
                  reasoningField = "reasoning_content";
                };
                variants = [
                  {
                    id = "low";
                    settings = {
                      reasoningEffort = "low";
                    };
                  }
                  {
                    id = "high";
                    settings = {
                      reasoningEffort = "high";
                    };
                  }
                  {
                    id = "max";
                    settings = {
                      reasoningEffort = "max";
                    };
                  }
                ];
              };
            };
          };
          cline = {
            name = "Cline";
            env = [
              "CLINE_API_KEY"
            ];
            package = "@opencode-ai/ai/providers/openai-compatible";
            settings = {
              baseURL = "https://api.cline.bot/api/v1";
              apiKey = "{env:CLINE_API_KEY}";
            };
            models = {
              "glm-5.3-flash" = {
                modelID = "z-ai/glm-5.3-flash";
                name = "GLM-5.3-Flash";
                variants = [
                  {
                    id = "low";
                    settings = {
                      reasoningEffort = "low";
                    };
                  }
                  {
                    id = "high";
                    settings = {
                      reasoningEffort = "high";
                    };
                  }
                  {
                    id = "max";
                    settings = {
                      reasoningEffort = "max";
                    };
                  }
                ];
              };
              "laguna-s-2.1" = {
                modelID = "poolside/laguna-s-2.1";
                name = "Laguna S 2.1";
              };
              "minimax-m2.5" = {
                modelID = "minimax/minimax-m2.5";
                name = "MiniMax M2.5";
              };
            };
          };
          empero = {
            name = "Empero";
            package = "@opencode-ai/ai/providers/openai-compatible";
            settings = {
              baseURL = "https://free.empero.org/v1";
            };
          };
          novita = {
            name = "Novita";
            env = [
              "NOVITA_API_KEY"
            ];
            package = "@opencode-ai/ai/providers/openai-compatible";
            settings = {
              baseURL = "https://novita.helicone.ai/v3/openai";
              apiKey = "{env:NOVITA_API_KEY}";
            };
          };
          tokenrouter = {
            name = "TokenRouter";
            env = [
              "TOKENROUTER_API_KEY"
            ];
            package = "@opencode-ai/ai/providers/openai-compatible";
            settings = {
              baseURL = "https://api.tokenrouter.com/v1";
              apiKey = "{env:TOKENROUTER_API_KEY}";
            };
          };
          agnes = {
            name = "Agnes";
            env = [
              "AGNES_API_KEY"
            ];
            package = "@opencode-ai/ai/providers/openai-compatible";
            settings = {
              baseURL = "https://apihub.agnes-ai.com/v1";
              apiKey = "{env:AGNES_API_KEY}";
            };
            models = {
              "agnes-2.5-flash" = {
                modelID = "agnes-2.5-flash";
                name = "Agnes 2.5 Flash";
              };
              "agnes-3.0-flash" = {
                modelID = "agnes-3.0-flash";
                name = "Agnes 3.0 Flash";
              };
            };
          };
        };
        permissions = [
          {
            action = "external_directory";
            resource = "*";
            effect = "deny";
          }
          {
            action = "external_directory";
            resource = "/tmp/opencode/**";
            effect = "allow";
          }
          {
            action = "external_directory";
            resource = "~/.agents/skills/**";
            effect = "allow";
          }
          {
            action = "external_directory";
            resource = "~/*/.agents/skills/**";
            effect = "allow";
          }
          {
            action = "external_directory";
            resource = "~/.opencode/plan/**";
            effect = "allow";
          }
          {
            action = "external_directory";
            resource = "~/.opencode/build/**";
            effect = "allow";
          }
          {
            action = "read";
            resource = "~/.config";
            effect = "deny";
          }
          {
            action = "read";
            resource = "~/.local";
            effect = "deny";
          }
          {
            action = "read";
            resource = "~/.ssh/*";
            effect = "deny";
          }
          {
            action = "skill";
            resource = "README";
            effect = "deny";
          }
          {
            action = "edit";
            resource = "*";
            effect = "deny";
          }
          {
            action = "shell";
            resource = "*";
            effect = "deny";
          }
          {
            action = "shell";
            resource = "pwd";
            effect = "ask";
          }
          {
            action = "linkding_*";
            resource = "*";
            effect = "deny";
          }
          {
            action = "webfetch";
            resource = "*";
            effect = "deny";
          }
          {
            action = "websearch";
            resource = "*";
            effect = "deny";
          }
          {
            action = "subagent";
            resource = "*";
            effect = "deny";
          }
          {
            action = "subagent";
            resource = "*-researcher";
            effect = "allow";
          }
          {
            action = "subagent";
            resource = "bulk-reader";
            effect = "allow";
          }
        ];
      };
    in
    {
      options.my.programs.opencode = {
        enable = lib.mkEnableOption "OpenCode";
        web = {
          enable = lib.mkEnableOption "OpenCode Web";
          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 4096;
          };
          environmentFile = lib.mkOption {
            type = lib.types.str;
            description = "Runtime environment file containing OPENCODE_SERVER_PASSWORD; never a Nix store path.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        # Keep the usual command name while llm-agents packages V2 as opencode2.
        home.packages = lib.mkAfter [
          pkgs.llm-agents.opencode2
          opencode
        ];

        systemd.user.services.opencode-web = lib.mkIf cfg.web.enable {
          Unit.Description = "OpenCode Web";
          Install.WantedBy = [ "default.target" ];
          Service = {
            ExecStart = lib.getExe (
              pkgs.writeShellScriptBin "opencode-web-start" ''
                if [ -z "''${OPENCODE_SERVER_PASSWORD:-}" ]; then
                  echo "OPENCODE_SERVER_PASSWORD must not be empty" >&2
                  exit 1
                fi
                exec ${lib.getExe pkgs.llm-agents.opencode2} serve --hostname ${lib.escapeShellArg cfg.web.host} --port ${toString cfg.web.port}
              ''
            );
            WorkingDirectory = config.home.homeDirectory;
            EnvironmentFile = cfg.web.environmentFile;
            # The headless service does not need a desktop session.
            UnsetEnvironment = [
              "DISPLAY"
              "WAYLAND_DISPLAY"
              "XDG_CURRENT_DESKTOP"
            ];
            Environment = [
              "HOME=${config.home.homeDirectory}"
              "PATH=${
                lib.concatStringsSep ":" (
                  config.home.sessionPath
                  ++ [
                    "${config.home.profileDirectory}/bin"
                    "/run/wrappers/bin"
                    "/run/current-system/sw/bin"
                  ]
                )
              }"
              "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
              "BROWSER=${pkgs.coreutils}/bin/true"
            ];
            Restart = "on-failure";
            RestartSec = 5;
            UMask = "0077";
          };
        };

        # Generate opencode.json
        xdg.configFile."opencode/opencode.json" = {
          text = opencodeConfig;
        };
      };
    };
}
