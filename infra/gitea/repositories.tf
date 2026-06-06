resource "gitea_repository" "kaikei" {
  username    = "yuta"
  name        = "kaikei"
  description = "確定申告・請求書管理"
  private     = true
  auto_init   = false
}
