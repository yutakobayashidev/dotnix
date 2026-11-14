resource "tailscale_dns_configuration" "main" {
  magic_dns          = true
  override_local_dns = true

  # CoreDNS owns public resolution and the Quad9 -> Cloudflare failover policy.
  # Do not add public resolvers here: Tailscale does not treat them as fallbacks.
  nameservers {
    address = "100.111.109.43"
  }

  split_dns {
    domain = "home.yutakobayashi.com"
    nameservers {
      address = "100.111.109.43"
    }
  }
}
