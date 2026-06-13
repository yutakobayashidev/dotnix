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

resource "random_password" "yuta" {
  length  = 24
  special = true
}

resource "random_password" "tokuzou0829" {
  length  = 24
  special = true
}

resource "gitea_user" "moons_14" {
  username             = "moons-14"
  login_name           = "moons-14"
  email                = "moons@moons14.com"
  password             = random_password.moons_14.result
  must_change_password = true
}

resource "gitea_user" "akazdayo" {
  username             = "akazdayo"
  login_name           = "akazdayo"
  email                = "me@odango.app"
  password             = random_password.akazdayo.result
  must_change_password = true
}

resource "gitea_user" "nakasyou" {
  username             = "nakasyou"
  login_name           = "nakasyou"
  email                = "how@nakasyou.how"
  password             = random_password.nakasyou.result
  must_change_password = true
}

resource "gitea_user" "tak0m0" {
  username             = "tak0m0"
  login_name           = "tak0m0"
  email                = "taku.mabuchi@idealike.net"
  password             = random_password.tak0m0.result
  must_change_password = true
}

resource "gitea_user" "yuta" {
  username              = "yuta"
  login_name            = ""
  email                 = "hi@yutakobayashi.com"
  password              = random_password.yuta.result
  active                = false
  must_change_password  = false
  send_notification     = false
  force_password_change = false

  lifecycle {
    ignore_changes = [password]
  }
}

resource "gitea_user" "tokuzou0829" {
  username              = "tokuzou0829"
  login_name            = ""
  email                 = "hi@tokuzou.me"
  password              = random_password.tokuzou0829.result
  active                = false
  must_change_password  = false
  send_notification     = false
  force_password_change = false

  lifecycle {
    ignore_changes = [password]
  }
}

import {
  to = gitea_user.yuta
  id = "1"
}

import {
  to = gitea_user.tokuzou0829
  id = "2"
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
