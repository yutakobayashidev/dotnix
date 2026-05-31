# Gitea Repositories

OpenTofu manages repositories on `https://git.home.yutakobayashi.com`.

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
