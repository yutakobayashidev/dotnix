resource "random_password" "moons_14" {
  length  = 24
  special = true
}

resource "random_password" "akazdayo" {
  length  = 24
  special = true
}

resource "random_password" "nakasyou" {
  length  = 24
  special = true
}

resource "random_password" "tak0m0" {
  length  = 24
  special = true
}

resource "random_password" "ka1ut" {
  length  = 24
  special = true
}

resource "random_password" "fa0311" {
  length  = 24
  special = true
}

resource "random_password" "yuta" {
  length  = 24
  special = true
}

resource "random_password" "tokuzou0829" {
  length  = 24
  special = true
}

resource "random_password" "t4ko0522" {
  length  = 24
  special = true
}

resource "gitea_user" "moons_14" {
  username             = "moons-14"
  login_name           = "moons-14"
  email                = "moons@moons14.com"
  password             = random_password.moons_14.result
  must_change_password = true
  send_notification    = true
}

resource "gitea_user" "akazdayo" {
  username             = "akazdayo"
  login_name           = "akazdayo"
  email                = "me@odango.app"
  password             = random_password.akazdayo.result
  must_change_password = true
  send_notification    = true
}

resource "gitea_user" "nakasyou" {
  username             = "nakasyou"
  login_name           = "nakasyou"
  email                = "how@nakasyou.how"
  password             = random_password.nakasyou.result
  must_change_password = true
  send_notification    = true
}

resource "gitea_user" "tak0m0" {
  username             = "tak0m0"
  login_name           = "tak0m0"
  email                = "taku.mabuchi@idealike.net"
  password             = random_password.tak0m0.result
  must_change_password = true
  send_notification    = true
}

resource "gitea_user" "ka1ut" {
  username             = "ka1ut"
  login_name           = "ka1ut"
  email                = "tka1utjp@gmail.com"
  password             = random_password.ka1ut.result
  must_change_password = true
  send_notification    = true
}

resource "gitea_user" "fa0311" {
  username             = "fa0311"
  login_name           = "fa0311"
  email                = "yuki@yuki0311.com"
  password             = random_password.fa0311.result
  must_change_password = true
  send_notification    = true
}

resource "gitea_user" "yuta" {
  username                  = "yuta"
  login_name                = "yuta"
  email                     = "hi@yutakobayashi.com"
  password                  = random_password.yuta.result
  active                    = true
  admin                     = true
  allow_create_organization = true
  allow_git_hook            = true
  allow_import_local        = true
  max_repo_creation         = -1
  must_change_password      = false
  send_notification         = false
  force_password_change     = false
}

resource "gitea_user" "tokuzou0829" {
  username                  = "tokuzou0829"
  login_name                = "tokuzou0829"
  email                     = "hi@tokuzou.me"
  password                  = random_password.tokuzou0829.result
  active                    = true
  allow_create_organization = true
  allow_git_hook            = true
  allow_import_local        = true
  max_repo_creation         = -1
  must_change_password      = false
  send_notification         = false
  force_password_change     = false
}

resource "gitea_user" "t4ko0522" {
  username             = "t4ko0522"
  login_name           = "t4ko0522"
  email                = "tako.work.contact@gmail.com"
  password             = random_password.t4ko0522.result
  must_change_password = true
  send_notification    = true
}

output "moons_14_password" {
  value     = random_password.moons_14.result
  sensitive = true
}

output "akazdayo_password" {
  value     = random_password.akazdayo.result
  sensitive = true
}

output "nakasyou_password" {
  value     = random_password.nakasyou.result
  sensitive = true
}

output "tak0m0_password" {
  value     = random_password.tak0m0.result
  sensitive = true
}

output "ka1ut_password" {
  value     = random_password.ka1ut.result
  sensitive = true
}

output "fa0311_password" {
  value     = random_password.fa0311.result
  sensitive = true
}

output "t4ko0522_password" {
  value     = random_password.t4ko0522.result
  sensitive = true
}
