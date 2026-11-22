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

# The all-in-one module would run nixos-rebuild over SSH to the public IP after
# installing, which the host's firewall blocks. comin deploys later changes, so
# the stack only installs the first system.
module "system_build" {
  source    = "github.com/nix-community/nixos-anywhere//terraform/nix-build?ref=0416d53"
  attribute = "${path.module}/../../..#nixosConfigurations.vultr-fedi.config.system.build.toplevel"
}

module "partitioner_build" {
  source    = "github.com/nix-community/nixos-anywhere//terraform/nix-build?ref=0416d53"
  attribute = "${path.module}/../../..#nixosConfigurations.vultr-fedi.config.system.build.diskoScript"
}

module "install" {
  source = "github.com/nix-community/nixos-anywhere//terraform/install?ref=0416d53"

  nixos_system       = module.system_build.result.out
  nixos_partitioner  = module.partitioner_build.result.out
  target_host        = vultr_instance.fedi.main_ip
  instance_id        = vultr_instance.fedi.id
  extra_files_script = "${path.module}/decrypt-ssh-secret.sh"
}

output "ip-address" {
  value = vultr_instance.fedi.main_ip
}
