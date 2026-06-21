_: {
  perSystem =
    { pkgs, ... }:
    let
      sgconfig = (pkgs.formats.yaml { }).generate "sgconfig.yml" {
        ruleDirs = [ ../../../.config/rules ];
        testConfigs = [
          {
            testDir = ../../../.config/rule-tests;
          }
        ];
        customLanguages = {
          fennel = {
            libraryPath = "${pkgs.vimPlugins.nvim-treesitter-parsers.fennel}/parser/fennel.so";
            extensions = [ "fnl" ];
          };
          gleam = {
            extensions = [ "gleam" ];
            libraryPath = "${pkgs.vimPlugins.nvim-treesitter-parsers.gleam}/parser/gleam.so";
          };
        };
      };
    in
    {
      _module.args.sgconfig = sgconfig;

      treefmt.settings.formatter.ast-grep = {
        command = "${pkgs.ast-grep}/bin/ast-grep";
        options = [
          "scan"
          "--error"
          "--config"
          "${sgconfig}"
        ];
        includes = [ "*.fnl" ];
      };
    };
}
