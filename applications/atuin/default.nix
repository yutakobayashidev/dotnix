_:

{
  programs.atuin = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = false;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = true;
      update_check = false;
      sync_address = "http://B450M-Pro4:8890";
    };
  };
}
