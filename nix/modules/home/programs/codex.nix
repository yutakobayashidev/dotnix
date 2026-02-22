{
  config,
  pkgs,
  dotfilesDir,
  ...
}:

let
  codexDotfilesDir = "${dotfilesDir}/codex";
  tomlFormat = pkgs.formats.toml { };

  settings = {
    model = "gpt-5.3-codex";
    approval_policy = "on-request";
    model_reasoning_effort = "high";
    web_search_request = true;
    project_doc_fallback_filenames = [ "CLAUDE.md" ];
  };
in
{
  home.packages = [ pkgs.codex ];

  home.file.".codex/config.toml".source = tomlFormat.generate "codex-config.toml" settings;

  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/AGENTS.md";
}
