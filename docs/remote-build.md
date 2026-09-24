# Remote builds on UM790-Pro

B450M-Pro4 and ThinkPad-X1-Carbon-Gen13 offload ordinary `x86_64-linux` builds to
UM790-Pro. Evaluation and activation stay on the requesting host. Existing
`nix run .#build`, `nix run .#switch`, and B450M's comin deployment use the Nix
daemon's builder configuration without separate deployment commands.

## Configuration

`modules/features/remote-build.nix` defines two opt-in features:

- `my.nix.remoteBuild.builder.enable`: enabled on UM790-Pro.
- `my.nix.remoteBuild.client.enable`: enabled on B450M-Pro4 and the ThinkPad.

The clients use `ssh-ng://nix-ssh@um790-builder`. The system SSH configuration
resolves this alias to `um790-pro.tail29d068.ts.net:2223` and pins UM790's OpenSSH
Ed25519 host key. Port 2222 is already occupied. Port 22 remains available for
existing SSH access, including Tailscale SSH; the added port is allowed through
the firewall only on `tailscale0`.

NixOS's `nix.sshServe` supplies the `nix-ssh` account, forces
`nix-daemon --stdio`, and disables interactive terminals and SSH forwarding. The
account is allowed and trusted by Nix; treat its keys as privileged builder
credentials. The SSH alias uses IPv4, and each client's authorized key is restricted
to that client's Tailscale IPv4 address. Re-enrolling a client with a different
address requires updating its key restriction.

UM790 uses `max-jobs = 4` and `cores = 4`. Each client advertises two remote jobs,
leaving room for the other client. These settings are scheduling limits/hints,
not a machine-wide CPU or memory quota across all Nix connections. Observe memory
usage during concurrent builds before increasing them; UM790 also hosts VMs and
has no swap.

Both clients use `max-jobs = 0` and `builders-use-substitutes = true`. Existing
binary caches are still used, and UM790 can fetch dependencies from its caches.
Derivations marked `preferLocalBuild` still run locally. ARM and macOS builds are
not provided by this builder.

## Keys and recovery

Each client has its own key in `secrets/remote-build-<hostname>.yaml`. SOPS grants
decryption to that client and UM790 for recovery. The private key is installed
as `/run/secrets/remote-build-key`, owned by root with mode `0400`; no user SSH
agent, interactive passphrase, or Home Manager SSH configuration is required.
The existing persistent SOPS identities restore it after reboot.

The initial keys were generated on UM790 under
`/home/yuta/.local/state/dotnix/remote-build/<hostname>/id_ed25519` (directories
`0700`, private keys `0600`). The encrypted repository files are the deployment
source of truth. Do not place plaintext keys in the repository, Nix store, or
`/tmp`.

For rotation, generate a replacement in that same persistent directory under a
new filename, encrypt it using the matching rule in `.sops.yaml`, and update the
public key in the feature module. Install the new public key on UM790 before
switching the client key, then remove the old public key after a successful
connection. To recover a key, decrypt the corresponding SOPS entry directly to
its final protected location with `umask 077`; do not print it to the terminal.

## Initial rollout

Apply UM790 before enabling clients in a running generation. UM790 and B450M
both run comin: do not rely on the order in which they notice a Git push. Prepare
and verify the builder using the local checkout before publishing client
enablement. The first client build uses the old daemon configuration; the new
builder and secret become available after activation.

1. On UM790, build and activate the checkout locally:

   ```sh
   sudo nixos-rebuild switch --flake .#UM790-Pro --builders '' --max-jobs 2 --cores 4
   ```

2. Ensure the Tailnet network policy permits B450M and the ThinkPad to reach
   UM790 on TCP 2223. This connection uses ordinary OpenSSH over Tailscale, not
   Tailscale SSH authentication. Existing Tailscale SSH permissions for managing
   the hosts are separate.

3. Activate the ThinkPad, then B450M, using a local bootstrap build if necessary:

   ```sh
   sudo nixos-rebuild switch --flake .#ThinkPad-X1-Carbon-Gen13 --builders '' --max-jobs 2 --cores 4
   # Run on B450M:
   sudo nixos-rebuild switch --flake .#B450M-Pro4 --builders '' --max-jobs 2 --cores 4
   ```

4. On each client, verify the noninteractive root connection:

   ```sh
   sudo nix store info --store ssh-ng://nix-ssh@um790-builder
   ```

   Build a package that is not already in the store/cache and verify the log
   says it is building on `ssh-ng://nix-ssh@um790-builder`. A cached system build
   alone does not prove offloading works. Then check normal system builds,
   B450M's `journalctl -u comin`, and secret availability after the next reboot.

B450M had only about 5.7 GiB available on its system filesystem when this was
introduced. Remote building still copies completed outputs into its local Nix
store, so ensure sufficient space before deployment. This feature does not
delete existing generations or data.

## ThinkPad away from home

The same configuration works away from home while both machines are connected
to the Tailnet and UM790 is awake. Large source uploads and build-output downloads
can make a slow connection the bottleneck.

When UM790 or the network is unavailable, installed applications continue to
work, and cached outputs remain usable. Uncached ordinary builds fail instead
of automatically using the laptop. SSH connection attempts time out after five
seconds; keepalives also detect a lost connection during a build. An interrupted
build is retried by rerunning the command after connectivity is restored.

To explicitly build on the ThinkPad for one invocation:

```sh
nix build .#nixosConfigurations.ThinkPad-X1-Carbon-Gen13.config.system.build.toplevel \
  --builders '' --max-jobs 2 --cores 4

sudo nixos-rebuild switch --flake .#ThinkPad-X1-Carbon-Gen13 \
  --builders '' --max-jobs 2 --cores 4
```

These overrides do not change the persistent remote-build configuration. They
also do not make missing sources or flake inputs available offline. Use the
underlying commands shown above: the existing `.#build` / `.#switch` wrappers do
not forward build flags.

To permanently return a client to local builds, remove its
`my.nix.remoteBuild.client.enable = true` setting and activate with the same
local override. Do that before disabling the builder on UM790.

## Automated verification

```sh
nix build .#checks.x86_64-linux.remote-build
```

The two-node NixOS VM test exercises the actual feature module: the firewall
boundary, forced SSH daemon access, an uncached remote build, rejection of an
unknown key, failure without an available builder, and an explicit local build.
Test keys are generated inside the disposable VMs. SOPS decryption, real Tailnet
ACLs, and the clients' persistent machine identities are checked separately
during deployment.

## Reference

- [natsukium/dotfiles distributed builds](https://github.com/natsukium/dotfiles/blob/053f07dbb9b4d0bbd354a1ed707ab637ce7a1559/modules/features/nix/distributed-builds.nix)
- [Nix remote builds](https://nix.dev/manual/nix/2.34/advanced-topics/distributed-builds.html)
