resource "tailscale_device_authorization" "b450m_pro4" {
  device_id  = "nWu8AHoCP811CNTRL"
  authorized = true
}

resource "tailscale_device_key" "b450m_pro4" {
  device_id           = "nWu8AHoCP811CNTRL"
  key_expiry_disabled = false
}

resource "tailscale_device_authorization" "m2_macbook_air" {
  device_id  = "nVwa2cS4tJ11CNTRL"
  authorized = true
}

resource "tailscale_device_key" "m2_macbook_air" {
  device_id           = "nVwa2cS4tJ11CNTRL"
  key_expiry_disabled = false
}

resource "tailscale_device_authorization" "macbook_air_3" {
  device_id  = "n8U9dSjJWU11CNTRL"
  authorized = true
}

resource "tailscale_device_key" "macbook_air_3" {
  device_id           = "n8U9dSjJWU11CNTRL"
  key_expiry_disabled = false
}

resource "tailscale_device_authorization" "pixel_8a" {
  device_id  = "nWFWaEhHoM11CNTRL"
  authorized = true
}

resource "tailscale_device_key" "pixel_8a" {
  device_id           = "nWFWaEhHoM11CNTRL"
  key_expiry_disabled = false
}

resource "tailscale_device_authorization" "s23_fe" {
  device_id  = "n2UKCjM5e321CNTRL"
  authorized = true
}

resource "tailscale_device_key" "s23_fe" {
  device_id           = "n2UKCjM5e321CNTRL"
  key_expiry_disabled = false
}

resource "tailscale_device_authorization" "tokuo_pc" {
  device_id  = "nMHsjWhnB711CNTRL"
  authorized = true
}

resource "tailscale_device_key" "tokuo_pc" {
  device_id           = "nMHsjWhnB711CNTRL"
  key_expiry_disabled = false
}

resource "tailscale_device_authorization" "um790_pro" {
  device_id  = "n1ACQ1LDqz11CNTRL"
  authorized = true
}

resource "tailscale_device_key" "um790_pro" {
  device_id           = "n1ACQ1LDqz11CNTRL"
  key_expiry_disabled = false
}

resource "tailscale_device_authorization" "x870_steel_legend" {
  device_id  = "nxDBJ83LM811CNTRL"
  authorized = true
}

resource "tailscale_device_key" "x870_steel_legend" {
  device_id           = "nxDBJ83LM811CNTRL"
  key_expiry_disabled = false
}

resource "tailscale_device_tags" "b450m_pro4" {
  device_id = "nWu8AHoCP811CNTRL"
  tags      = ["tag:server"]
}

resource "tailscale_device_tags" "um790_pro" {
  device_id = "n1ACQ1LDqz11CNTRL"
  tags      = ["tag:server"]
}

resource "tailscale_device_tags" "x870_steel_legend" {
  device_id = "nxDBJ83LM811CNTRL"
  tags      = ["tag:server"]
}

