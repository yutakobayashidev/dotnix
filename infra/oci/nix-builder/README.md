# OCI Nix Builder

Terraform stack for the `oci-a1` NixOS machine in OCI Tokyo.

## Local files

Create `terraform.tfvars` from `terraform.tfvars.example`. Keep the SSH ingress
CIDR restricted to the deployment machine where possible.

Create a SOPS-encrypted `oci_secrets.yaml` containing the OCI API private key
and a pre-generated SSH host key:

```yaml
private_key: |
  -----BEGIN PRIVATE KEY-----
  ...
  -----END PRIVATE KEY-----
ssh_host_ed25519_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
```

The Terraform SOPS provider decrypts the OCI API key during `plan` and `apply`.
`decrypt-ssh-secret.sh` places the SSH host key into `/persist/etc/ssh` before
the first boot so that impermanence preserves the key and sops-nix has a stable
age identity.

Add the age recipient derived from `ssh_host_ed25519_key.pub` to any SOPS files
that `oci-a1` must decrypt during activation. Neither local file should be
committed.
