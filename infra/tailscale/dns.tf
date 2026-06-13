resource "tailscale_dns_configuration" "main" {
  magic_dns          = true
  override_local_dns = true

  nameservers {
    address = "2606:4700:4700::1111"
  }
  nameservers {
    address = "2606:4700:4700::1001"
  }
  nameservers {
    address = "1.1.1.1"
  }
  nameservers {
    address = "1.0.0.1"
  }
  nameservers {
    address = "8.8.8.8"
  }
  nameservers {
    address = "8.8.4.4"
  }
  nameservers {
    address = "2001:4860:4860::8888"
  }
  nameservers {
    address = "2001:4860:4860::8844"
  }
  nameservers {
    address = "9.9.9.9"
  }
  nameservers {
    address = "149.112.112.112"
  }
  nameservers {
    address = "2620:fe::fe"
  }
  nameservers {
    address = "2620:fe::9"
  }

  split_dns {
    domain = "home.yutakobayashi.com"
    nameservers {
      address = "100.111.109.43"
    }
  }
}
