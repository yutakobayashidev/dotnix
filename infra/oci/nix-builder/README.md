# OCI Nix Builder

Terraform stack for the `oci-a1` NixOS machine in OCI Tokyo.

## Local files

Create `terraform.tfvars` from `terraform.tfvars.example`. Keep the SSH ingress
CIDR restricted to the deployment machine where possible.

Create a SOPS-encrypted `oci_secrets.yaml` containing the OCI API private key:

```yaml
private_key: |
  -----BEGIN PRIVATE KEY-----
  ...
  -----END PRIVATE KEY-----
```

The Terraform SOPS provider decrypts this file during `plan` and `apply`.
Neither local file should be committed.
