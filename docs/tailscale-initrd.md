# Tailscale initrd unlock: deployment preparation

PR [#2532](https://github.com/yutakobayashidev/dotnix/pull/2532) adds an
opt-in systemd initrd feature. No host enables it. B450M-Pro4 still needs wired
networking and an on-site recovery path before its first unlock trial.

The feature uses NixOS OpenSSH, not Tailscale SSH. Its Tailscale state is in
memory, so each boot enrolls a new node; shutdown runs `tailscale logout`.
The VM test uses Headscale and does not establish Tailnet Lock compatibility.
The 2026-11-21 verification attempt stopped before VM execution because the
ThinkPad ran out of space while receiving build outputs. The original PR
reports a successful earlier VM test; that result was not reproduced here.

## ACL policy

Reference: [darkrain42/tailscale-initramfs README at ad789820](https://github.com/darkrain42/tailscale-initramfs/blob/ad789820af435713e93110216f6bfbf7dd308397/README.md).
Its example gives the initramfs a dedicated tag, grants members inbound access,
and tests that the tagged node cannot initiate connections. It does not limit
inbound network access to TCP 22. Its `ssh` rules govern Tailscale SSH and
must not be copied as authentication rules for our OpenSSH daemon.

Use `tag:initrd` alone for this host's boot environment. Do not also assign
`tag:server` or `tag:ci`: both are allowed to initiate arbitrary connections
by [our policy](../infra/tailscale/acl.tf). Add the tag owner through that
OpenTofu-managed policy, not an independent console edit.

The current policy's `autogroup:member`, `tag:server`, and `tag:ci` sources
already have `dst: ["*"]`. A node tagged only `tag:initrd` matches none of
those source identities. Therefore the reference's outbound isolation can
be implemented without removing existing broad destination grants. Replies
to allowed inbound connections remain possible.

Restricting *inbound* access to designated operators on TCP 22 is a separate
change: replace the broad destination grants with explicit destinations that
exclude initrd, then grant operator access to initrd. Adding a narrower grant
does not override an existing broad grant. Preserve current server, CI,
subnet, and user-device access with regression tests before applying that change.
See [grants syntax](https://tailscale.com/docs/reference/syntax/grants) and
[tag identities](https://tailscale.com/docs/features/tags).

Required policy tests for the implementation PR:

- Deny new connections from `tag:initrd` to B450M-Pro4, UM790-Pro, operator
  devices and routed LAN destinations on representative TCP/UDP ports.
- Allow the selected operator to reach `tag:initrd:22`.
- If inbound restriction is chosen, deny non-operators and other destination
  ports, including sources tagged `tag:ci` and `tag:server`.
- Keep existing CI and administrative connectivity tests passing.

Policy `tests` assertions detect mistakes; they are not deny rules. These
constraints cover tailnet traffic, not direct LAN traffic or the outbound
Internet connectivity needed to enroll. The current initrd sshd has no
Tailscale-only listen restriction. Decide separately whether LAN SSH is wanted
for recovery; if not, implement and test an initrd firewall before deployment.

## Enrollment keys and Tailnet Lock

Auth keys expire after at most 90 days. Disabling a tagged device's node-key
expiry does not extend its enrollment key. Because this feature forgets state,
an expired auth key prevents the next boot from joining the tailnet.
See [auth-key lifetimes](https://tailscale.com/docs/features/access-control/auth-keys).

Keep the provider API credential, initrd enrollment key, Tailnet Lock signing
key, SSH host key and operator SSH key separate. Existing CI enrollment keys
and the stage-2 NixOS key must not be reused for initrd.

[Tailnet Lock](https://tailscale.com/docs/features/tailnet-lock) needs a
signature for each newly enrolled node. There are two deployment choices:

| Choice | Boot operation | Secret stored in initrd |
| --- | --- | --- |
| Sign each new node from a trusted operator machine | Verify the new node's identity and sign it before SSH | Unsigned enrollment key |
| Use a pre-signed enrollment key | Automatic enrollment with no per-boot operator signature | Enrollment key containing a trusted signing private key |

For manual signing, establish how the operator will obtain and verify the new
node key while that node is blocked. Do not blindly sign by a reused hostname.
This workflow needs a real locked-tailnet trial before being called ready.

Pre-signing embeds a private signing key; an ACL tag does not constrain that
key's signing authority. Tailscale recommends against signed auth keys on
security grounds. Expiring or revoking the enrollment key does not remove
its trusted signing key. Record that signing-key ID separately and remove it
when retiring the credential. See [lock sign](https://tailscale.com/docs/reference/tailscale-cli/lock).

The existing [CI key workflow](tailnet-lock.md) provides a useful provisioning
pattern: OpenTofu creates an unsigned key, exports ciphertext using age, and a
trusted operator signs locally when required. Its current `tailscale-ci` target
and `ci_auth_keys` output only cover CI; they do not provision initrd keys.
A future implementation should add a dedicated initrd resource, sensitive
output and scoped workflow target, rather than trigger unrelated key rotation.
Signed keys must stay out of Terraform state, logs and Git.

### Proposed rotation procedure

This is an operational proposal, not an installed timer or implemented exporter.
Start rotation 30 days before expiry, alert again at 14 and 7 days, and mark it
complete only after deployment verification. These intervals are local policy.

1. Provision a replacement reusable, ephemeral key tagged only `tag:initrd`.
   Keep the previous key valid during the trial; use separate key resources
   for overlap rather than assuming replacement preserves the old credential.
2. Apply the selected signing method. Store plaintext only in private persistent
   storage, then install it on B450M-Pro4 at
   `/persist/etc/secrets/initrd/tailscale-authkey` (root-owned, mode 0600).
   Never stage keys in `/tmp` or paste them into a shell command or PR.
3. Regenerate and install the boot artifacts through the host's normal NixOS
   deployment. Replacing the source file alone does not update an installed
   initrd. Verify the boot entry intended for the next boot was refreshed.
4. With local recovery available, boot and confirm tailnet enrollment, SSH
   host identity, LUKS unlock and removal of the ephemeral node. Keep a record
   of the deployed generation and the new key's expiry, without the key value.
5. Revoke the previous enrollment key and, when applicable, remove its dedicated
   trusted signing key. Older boot entries contain the old credential and lose
   remote enrollment after revocation; document local unlock as their fallback.

A scheduled key replacement alone is insufficient: generation, optional signing,
secret delivery and boot-artifact installation must succeed as one operation.
No automatic rotation is deployed by this documentation PR.

## SSH keys

The server identity is the initrd SSH host key. Generate it once **on B450M-Pro4**
at its final persistent destination; do not reuse the stage-2 host key or
regenerate it each boot. First check whether it already exists:

```sh
sudo test -e /persist/etc/ssh/initrd_ssh_host_ed25519_key
```

Only if absent, create it:

```sh
sudo install -d -m 0700 /persist/etc/ssh
sudo ssh-keygen -t ed25519 -N '' -f /persist/etc/ssh/initrd_ssh_host_ed25519_key
sudo chmod 0600 /persist/etc/ssh/initrd_ssh_host_ed25519_key
sudo ssh-keygen -lf /persist/etc/ssh/initrd_ssh_host_ed25519_key.pub
```

Record the fingerprint through the existing trusted host connection and pin
that identity on the operator machine. Keep a distinct known-hosts entry for
`B450M-Pro4-initrd`; `ssh-keyscan` over an untrusted path is not identity
verification. A dedicated `HostKeyAlias` can preserve the pinned identity when
the ephemeral node's IP changes. Never bypass host checking to enter a LUKS
passphrase. An exposed host key can enable server impersonation.

`my.services.tailscale.initrd.authorizedKeys` contains the **operator's public
key**, not the server public key. Keep the operator private key on the client
(or hardware token). The option requires a nonempty list. NixOS also supports
`boot.initrd.network.ssh.authorizedKeyFiles`, which can inherit root's key files;
review the effective authorized-key set rather than assuming the wrapper's
list is the entire set. Inspect generated sshd configuration before rollout.

For operator-key rotation, deploy both public keys, verify the new key, then
remove the old one and rebuild. For host-key rotation, generate a new dedicated
key, verify its fingerprint through a trusted path, update client pins in
coordination with the new boot entry, and preserve verified recovery access.
SSH keys do not share the auth key's 90-day expiry schedule.

The [NixOS SSH module](https://github.com/NixOS/nixpkgs/blob/1c89083e451e891152365b799595cf7790a43325/nixos/modules/system/boot/initrd-ssh.nix)
embeds host keys via `boot.initrd.secrets`. They are needed before LUKS unlock,
so boot artifacts expose them even when the root filesystem is encrypted.
Secure Boot authenticates those artifacts; it does not encrypt their contents.

## Before enabling B450M-Pro4

Choose the inbound policy and Tailnet Lock enrollment method, implement their
provisioning and rotation, and verify wired NIC support. Run the existing VM
test on UM790-Pro without copying large outputs back to the full ThinkPad.
Then test the chosen enrollment method against the actual locked tailnet and
perform the first hardware reboot with local console recovery available.
