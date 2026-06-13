resource "tailscale_dns_configuration" "main" {
  magic_dns = true

  split_dns {
    domain = "home.yutakobayashi.com"
    nameservers {
      address = "100.111.109.43"
    }
  }
}
