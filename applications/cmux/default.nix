{ pkgs, ... }:
let
  jsonFormat = pkgs.formats.json { };

  cmuxSettings = {
    "$schema" = "https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json";
    schemaVersion = 1;
    terminal = {
      showTextBoxOnNewTerminals = true;
      focusTextBoxOnNewTerminals = false;
      textBoxMaxLines = 10;
    };
  };
in
{
  xdg.configFile."cmux/cmux.json" = {
    source = jsonFormat.generate "cmux.json" cmuxSettings;
    force = true;
  };
}
