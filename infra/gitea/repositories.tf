resource "gitea_repository" "beancount" {
  username  = "yuta"
  name      = "beancount"
  private   = true
  auto_init = false
}
