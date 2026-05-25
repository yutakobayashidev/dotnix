locals {
  ipv4 = "10.42.0.42"
}

module "deploy" {
  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one?ref=0416d53"

  nixos_system_attr      = ".#nixosConfigurations.B450M-Pro4.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.B450M-Pro4.config.system.build.diskoScript"

  target_host = local.ipv4
  instance_id = local.ipv4

  disk_encryption_key_scripts = [{
    path   = "/tmp/luks-password"
    script = "${path.module}/luks-key.sh"
  }]

  install_user = "nixos"
  target_user  = "yuta"
}

output "result" {
  value = module.deploy.result
}
