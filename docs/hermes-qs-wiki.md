# Hermes Quantified Self wiki share

UM790-Pro shares the Quantified Self wiki directory with its `hermes-agent`
microVM using virtiofs, alongside the existing `llm-wiki` share.

| Location           | Path                                                             |
| ------------------ | ---------------------------------------------------------------- |
| UM790-Pro host     | `/home/yuta/ghq/git.yutakobayashi.com/yuta/quantified-self-wiki` |
| Hermes guest       | `/var/lib/hermes/quantified-self-wiki`                           |
| Hermes environment | `QS_WIKI_PATH=/var/lib/hermes/quantified-self-wiki`              |

Host tmpfiles creates the directory with mode `0750`, owned by `yuta` and the
user's primary group. Host `yuta` and guest `hermes` use UID 1000, allowing Hermes
to edit the shared files. Changes from either side affect the same files; wiki
content survives replacement of the VM's state disk. This is a writable share,
not a backup. The existing `WIKI_PATH` continues to select `llm-wiki`.

The configuration creates an empty directory if it is absent. It does not create
a remote Git repository, populate wiki content, or install a wiki web server.

After deploying the host configuration, restart the microVM through the normal
microVM deployment workflow so its virtiofs shares are refreshed. In the guest,
verify the mount and the Hermes user's access:

```sh
findmnt -T /var/lib/hermes/quantified-self-wiki
sudo -u hermes test -w /var/lib/hermes/quantified-self-wiki
```

Configuration lives in `systems/nixos/services/hermes-agent/default.nix`
(host directory and environment) and `guest.nix` (virtiofs share).
