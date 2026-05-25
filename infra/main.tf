locals {
  ipv4        = "10.42.0.44"
  instance_id = "B450M-Pro4"
}

module "deploy" {
  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one?ref=0416d53"

  nixos_system_attr      = "github:yutakobayashidev/dotnix#nixosConfigurations.B450M-Pro4.config.system.build.toplevel"
  nixos_partitioner_attr = "github:yutakobayashidev/dotnix#nixosConfigurations.B450M-Pro4.config.system.build.diskoScript"

  target_host = local.ipv4
  instance_id = local.instance_id

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
