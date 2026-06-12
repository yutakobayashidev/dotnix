resource "random_password" "moons_14" {
  length  = 24
  special = true
}

resource "random_password" "akazdayo" {
  length  = 24
  special = true
}

resource "gitea_user" "moons_14" {
  username            = "moons-14"
  email               = "moons@moons14.com"
  password            = random_password.moons_14.result
  must_change_password = true
}

resource "gitea_user" "akazdayo" {
  username            = "akazdayo"
  email               = "me@odango.app"
  password            = random_password.akazdayo.result
  must_change_password = true
}

output "moons_14_password" {
  value     = random_password.moons_14.result
  sensitive = true
}

output "akazdayo_password" {
  value     = random_password.akazdayo.result
  sensitive = true
}
