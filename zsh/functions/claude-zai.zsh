#!/usr/bin/env zsh

# claude-zai: Z.AI API経由でClaude Codeを実行
function claude-zai() {
  # Z.AI API Configuration
  export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
  export ANTHROPIC_AUTH_TOKEN="${ANTHROPIC_AUTH_TOKEN:-xxxx}"
  export API_TIMEOUT_MS="3000000"

  # Model mappings (GLM models)
  export ANTHROPIC_DEFAULT_OPUS_MODEL="GLM-5"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="GLM-5"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="GLM-4.7"

  claude -w "$@"
}
