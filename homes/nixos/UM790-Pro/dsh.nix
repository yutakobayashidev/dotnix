{ inputs, lib, ... }:
let
  # Keep the server's model registry as the single source of truth.
  litellm = inputs.self.nixosConfigurations.B450M-Pro4.config.services.litellm.settings;
  mkRoute = api: mode: {
    inherit api;
    baseURL = "https://litellm.home.yutakobayashi.com/v1";
    apiKeyEnv = "LITELLM_API_KEY";
    models = map (
      model:
      {
        id = model.model_name;
      }
      // lib.optionalAttrs (model.model_info ? context) {
        contextWindow = model.model_info.context;
      }
    ) (builtins.filter (model: (model.model_info.mode or "chat") == mode) litellm.model_list);
  };
in
{
  my.programs.dsh.web.settings = {
    "llm-pi-ai".providers = {
      # Bundled pi-ai route; initial ChatGPT sign-in remains interactive.
      openai-codex = { };
      litellm-chat = mkRoute "openai-completions" "chat";
      litellm-responses = mkRoute "openai-responses" "responses";
    };
  };

  # Existing Tailnet gateway uses this non-secret shared key. Upstream provider
  # credentials and ChatGPT token refresh remain owned by LiteLLM on B450M.
  systemd.user.services.dsh-web.Service.Environment = [
    "LITELLM_API_KEY=${litellm.general_settings.master_key}"
  ];
}
