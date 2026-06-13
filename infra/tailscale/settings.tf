resource "tailscale_tailnet_settings" "main" {
  devices_auto_updates_on                     = true
  devices_key_duration_days                   = 180
  https_enabled                               = true
  network_flow_logging_on                     = false
  regional_routing_on                         = false
  posture_identity_collection_on              = false
  devices_approval_on                         = false
  users_approval_on                           = false
  users_role_allowed_to_join_external_tailnet = "admin"
}
