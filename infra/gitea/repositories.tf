resource "gitea_repository" "kaikei" {
  username    = "yuta"
  name        = "kaikei"
  description = "確定申告・請求書管理"
  private     = true
  auto_init   = false
}

resource "gitea_repository" "course_cli" {
  username    = "yuta"
  name        = "course-cli"
  description = "Course CLI"
  private     = true
  auto_init   = false
}

resource "gitea_repository" "twitter_archive" {
  username    = "yuta"
  name        = "twitter-archive"
  description = "Twitter archive"
  private     = true
  auto_init   = false
}

resource "gitea_repository" "twitter_lite" {
  username    = "yuta"
  name        = "twitter-lite"
  description = "Twitter Lite"
  private     = false
  auto_init   = false
}

resource "gitea_repository" "discord_archive" {
  username    = "yuta"
  name        = "discord-archive"
  description = "Discord archive"
  private     = true
  auto_init   = false
}

resource "gitea_repository_key" "discord_archive_hermes_discrawl" {
  repository = gitea_repository.discord_archive.id
  title      = "hermes-discrawl-archive-readonly"
  key        = file("${path.module}/deploy-keys/hermes-discrawl-archive.pub")
  read_only  = true
}

resource "gitea_repository" "llm_wiki" {
  username    = "yuta"
  name        = "llm-wiki"
  description = "LLM Wiki"
  private     = false
  auto_init   = false
}

resource "gitea_repository" "nnn" {
  username  = "yuta"
  name      = "nnn"
  private   = true
  auto_init = false
}
