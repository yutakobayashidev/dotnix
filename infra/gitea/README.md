# Gitea Repositories

OpenTofu manages repositories on `https://git.yutakobayashi.com`.

The hostname is exposed through the shared Cloudflare Tunnel. Create a public
hostname route for `git.yutakobayashi.com` on tunnel
`3e1ff621-e8bf-47d1-b095-4b5c15eec63c` before applying the NixOS
configuration.

This route exposes HTTPS only. SSH clone requires a separate Cloudflare Tunnel
hostname and client configuration.

Create an API token in Gitea with these permissions:

- `repository`: Read and Write
- `organization`: Read and Write
- `user`: Read and Write

Then pass it through the environment:

```bash
cd infra
export GITEA_TOKEN="<token>"
nix develop --command tofu -chdir=gitea apply
unset GITEA_TOKEN
```

Do not commit the API token or write it to a temporary file.
