{ config, ... }:
{
  services.ollama = {
    enable = true;
    syncModels = true;
    loadModels = [ ];
  };

  services.open-webui = {
    enable = false;
    host = "0.0.0.0";
    environment = {
      OLLAMA_API_BASE_URL = "http://${config.services.ollama.host}:${toString config.services.ollama.port}";
      WEBUI_AUTH = "False";
    };
  };
}
