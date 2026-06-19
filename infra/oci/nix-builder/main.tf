terraform {
  encryption {
    key_provider "pbkdf2" "state_key" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "state_method" {
      keys = key_provider.pbkdf2.state_key
    }

    state {
      method    = method.aes_gcm.state_method
      enforced  = true
    }

    plan {
      method    = method.aes_gcm.state_method
      enforced  = true
    }
  }

  required_providers {
    oci = {
      source = "oracle/oci"
    }
    sops = {
      source = "carlpett/sops"
    }
  }
}

data "sops_file" "oci_secret" {
  source_file = "${path.module}/oci_secrets.yaml"
}

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  private_key  = data.sops_file.oci_secret.data["private_key"]
  fingerprint  = var.fingerprint
  region       = var.region
}

resource "oci_identity_compartment" "nix_builder" {
  description    = "The compartment for nix-builder"
  compartment_id = var.tenancy_ocid
  name           = "nix-builder"
}

resource "oci_core_vcn" "nix_builder" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = oci_identity_compartment.nix_builder.id
  display_name   = "nix-builder"
}

resource "oci_core_subnet" "nix_builder" {
  cidr_block     = "10.0.0.0/24"
  compartment_id = oci_identity_compartment.nix_builder.id
  vcn_id         = oci_core_vcn.nix_builder.id
  route_table_id = oci_core_route_table.nix_builder.id
}

resource "oci_core_internet_gateway" "nix_builder" {
  compartment_id = oci_identity_compartment.nix_builder.id
  vcn_id         = oci_core_vcn.nix_builder.id
  enabled        = true
}

resource "oci_core_route_table" "nix_builder" {
  compartment_id = oci_identity_compartment.nix_builder.id
  route_rules {
    network_entity_id = oci_core_internet_gateway.nix_builder.id
    destination       = "0.0.0.0/0"
  }
  vcn_id = oci_core_vcn.nix_builder.id
}

resource "oci_core_instance" "nix_builder" {
  availability_domain = var.availability_domain
  compartment_id      = oci_identity_compartment.nix_builder.id
  shape               = "VM.Standard.A1.Flex"
  shape_config {
    memory_in_gbs = 24
    ocpus         = 4
  }
  display_name = "nix-builder"

  create_vnic_details {
    assign_ipv6ip             = false
    assign_private_dns_record = true
    assign_public_ip          = true
    subnet_id                 = oci_core_subnet.nix_builder.id
  }

  source_details {
    boot_volume_size_in_gbs = 200
    boot_volume_vpus_per_gb = 10
    source_id               = var.image_id
    source_type             = "image"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

module "deploy" {
  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one?ref=0416d53"

  nixos_system_attr      = "${path.module}/../../..#nixosConfigurations.oci-a1.config.system.build.toplevel"
  nixos_partitioner_attr = "${path.module}/../../..#nixosConfigurations.oci-a1.config.system.build.diskoScript"
  target_host            = oci_core_instance.nix_builder.public_ip
  instance_id            = oci_core_instance.nix_builder.public_ip
  install_user           = "ubuntu"
  extra_files_script     = "${path.module}/decrypt-ssh-secret.sh"
}

output "ip-address" {
  value = oci_core_instance.nix_builder.public_ip
}
