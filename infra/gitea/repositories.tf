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

resource "gitea_repository" "discord_archive" {
  username    = "yuta"
  name        = "discord-archive"
  description = "Discord archive"
  private     = true
  auto_init   = false
}
