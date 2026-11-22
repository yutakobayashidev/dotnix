terraform {
  encryption {
    key_provider "pbkdf2" "state_key" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "state_method" {
      keys = key_provider.pbkdf2.state_key
    }

    state {
      method   = method.aes_gcm.state_method
      enforced = true
    }

    plan {
      method   = method.aes_gcm.state_method
      enforced = true
    }
  }

  required_providers {
    vultr = {
      source = "vultr/vultr"
    }
    sops = {
      source = "carlpett/sops"
    }
  }
}

data "sops_file" "vultr_secret" {
  source_file = "${path.module}/vultr_secrets.yaml"
}

provider "vultr" {
  api_key = data.sops_file.vultr_secret.data["api_key"]
}

resource "vultr_ssh_key" "install" {
  name    = "vultr-fedi-install"
  ssh_key = var.ssh_public_key
}

resource "vultr_instance" "fedi" {
  label            = "vultr-fedi"
  hostname         = "vultr-fedi"
  region           = var.region
  plan             = var.plan
  os_id            = var.os_id
  enable_ipv6      = true
  backups          = "disabled"
  activation_email = false
  ssh_key_ids      = [vultr_ssh_key.install.id]
}

module "deploy" {
  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one?ref=0416d53"

  nixos_system_attr      = "${path.module}/../../..#nixosConfigurations.vultr-fedi.config.system.build.toplevel"
  nixos_partitioner_attr = "${path.module}/../../..#nixosConfigurations.vultr-fedi.config.system.build.diskoScript"
  target_host            = vultr_instance.fedi.main_ip
  instance_id            = vultr_instance.fedi.id
  install_user           = "root"
  extra_files_script     = "${path.module}/decrypt-ssh-secret.sh"
}

output "ip-address" {
  value = vultr_instance.fedi.main_ip
}
