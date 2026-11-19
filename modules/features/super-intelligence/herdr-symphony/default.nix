_:

{
  flake.modules.homeManager.herdr-symphony =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.herdr-symphony;
      settingsFormat = pkgs.formats.json { };
      workflowType = lib.types.submodule {
        options = {
          source = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Complete WORKFLOW.md, copied unchanged into the Nix store. Mutually exclusive with settings and prompt inputs.";
          };
          settings = lib.mkOption {
            type = lib.types.attrsOf settingsFormat.type;
            default = { };
            description = "Workflow frontmatter using Symphony's native configuration keys. Do not put secrets here.";
          };
          prompt = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Liquid prompt body. Mutually exclusive with promptFile.";
          };
          promptFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "File containing only the Liquid prompt body, without YAML frontmatter.";
          };
        };
      };
      targetFor =
        name:
        if name == "default" then "herdr-symphony/WORKFLOW.md" else "herdr-symphony/workflows/${name}.md";
      workflowFiles = lib.mapAttrs (
        name: workflow:
        if workflow.source != null then
          workflow.source
        else
          let
            frontmatter = settingsFormat.generate "herdr-symphony-${name}.json" workflow.settings;
            prompt =
              if workflow.promptFile != null then
                workflow.promptFile
              else
                pkgs.writeText "herdr-symphony-${name}-prompt.md" workflow.prompt;
          in
          pkgs.runCommand "herdr-symphony-${name}-WORKFLOW.md" { } ''
            printf '%s\n' '---' > "$out"
            cat ${frontmatter} >> "$out"
            printf '\n%s\n\n' '---' >> "$out"
            cat ${prompt} >> "$out"
          ''
      ) cfg.workflows;
      workflowPaths = lib.mapAttrsToList (
        name: _: "${config.xdg.configHome}/${targetFor name}"
      ) cfg.workflows;
      start = pkgs.writeShellScript "herdr-symphony-start" ''
        set -eu
        ${pkgs.coreutils}/bin/install -d -m 700 ${lib.escapeShellArg cfg.stateDirectory}
        cd ${lib.escapeShellArg cfg.stateDirectory}
        exec ${lib.escapeShellArgs ([ (lib.getExe cfg.package) ] ++ workflowPaths)}
      '';

    in
    {
      options.my.services.herdr-symphony = {
        enable = lib.mkEnableOption "Herdr Symphony orchestration via a systemd user service";
        package = lib.mkPackageOption pkgs "herdr-symphony" { };
        workflows = lib.mkOption {
          type = lib.types.attrsOf workflowType;
          default = { };
          description = "Named workflows sharing one process and claim registry. Keep names stable to preserve workflow identity. Concurrency limits apply per workflow.";
        };
        path = lib.mkOption {
          type = lib.types.listOf (lib.types.either lib.types.package lib.types.str);
          default = [
            pkgs.git
            pkgs.gh
            pkgs.coreutils
          ];
          description = "Packages or profile roots whose bin directories are added to the service PATH. Include the selected runner and agent.";
        };
        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Non-secret environment variables. PATH defaults to the package and path options.";
        };
        environmentFiles = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Absolute runtime paths to systemd EnvironmentFiles, including secrets if needed. Use strings, not Nix path literals. These files are not read into the store. They affect Symphony; forwarding variables to agents is configured separately in the workflow.";
        };
        stateDirectory = lib.mkOption {
          type = lib.types.str;
          default = "${config.xdg.stateHome}/herdr-symphony";
          defaultText = lib.literalExpression "config.xdg.stateHome + \"/herdr-symphony\"";
          description = "Absolute writable state directory. Symphony stores its .workaholic database here.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = pkgs.stdenv.hostPlatform.isLinux;
            message = "herdr-symphony requires Linux systemd user services.";
          }
          {
            assertion = cfg.workflows != { };
            message = "herdr-symphony requires at least one workflow.";
          }
          {
            assertion = lib.hasPrefix "/" cfg.stateDirectory;
            message = "herdr-symphony.stateDirectory must be absolute.";
          }
          {
            assertion = lib.all (p: lib.hasPrefix "/" p) cfg.environmentFiles;
            message = "herdr-symphony.environmentFiles must use absolute runtime paths.";
          }
        ]
        ++ lib.concatLists (
          lib.mapAttrsToList (name: workflow: [
            {
              assertion = builtins.match "[A-Za-z0-9_-]+" name != null;
              message = "herdr-symphony workflow names must contain only letters, digits, underscores and hyphens.";
            }
            {
              assertion =
                workflow.source == null
                || (workflow.settings == { } && workflow.prompt == "" && workflow.promptFile == null);
              message = "herdr-symphony.workflows.${name}: source cannot be combined with settings or prompt inputs.";
            }
            {
              assertion = workflow.promptFile == null || workflow.prompt == "";
              message = "herdr-symphony.workflows.${name}: choose prompt or promptFile.";
            }
          ]) cfg.workflows
        );
        my.services.herdr-symphony.environment.PATH = lib.mkDefault (
          lib.makeBinPath ([ cfg.package ] ++ cfg.path)
        );
        home.packages = [ cfg.package ];
        xdg.configFile = lib.mapAttrs' (
          name: source: lib.nameValuePair (targetFor name) { inherit source; }
        ) workflowFiles;
        systemd.user.services.herdr-symphony = {
          Unit = {
            Description = "Dispatch issues through Herdr Symphony";
            X-Restart-Triggers = map (file: "${file}") (builtins.attrValues workflowFiles);
          };
          Service = {
            ExecStart = toString start;
            Environment = lib.mapAttrsToList (
              name: value: builtins.toJSON (lib.replaceStrings [ "%" ] [ "%%" ] "${name}=${value}")
            ) cfg.environment;
            EnvironmentFile = map (
              file: builtins.toJSON (lib.replaceStrings [ "%" ] [ "%%" ] file)
            ) cfg.environmentFiles;
            UnsetEnvironment = [
              "HC_TERMINAL_ID"
              "HC_SESSION"
              "HC_SOCKET"
            ];
            Restart = "on-failure";
            RestartSec = 10;
            UMask = "0077";
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
