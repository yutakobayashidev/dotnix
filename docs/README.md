# Documentation

### System Installation Guides

- [installer-iso.md](installer-iso.md) - Build and write the custom NixOS installer ISO
- [systems/B450M-Pro4.md](systems/B450M-Pro4.md) - NixOS installation guide
- [systems/UM790Pro.md](systems/UM790Pro.md) - NixOS installation guide
- [systems/ThinkPad-X1-Carbon-Gen13.md](systems/ThinkPad-X1-Carbon-Gen13.md) - NixOS dual-boot installation guide
- [systems/X870-Steel-Legend-WiFi.md](systems/X870-Steel-Legend-WiFi.md) - NixOS-WSL installation guide
- [systems/Pi5.md](systems/Pi5.md) - NixOS installation guide for Raspberry Pi 5
- [systems/M2-MacBook-Air.md](systems/M2-MacBook-Air.md) - nix-darwin installation guide for macOS
- [systems/Galaxy-S23FE.md](systems/Galaxy-S23FE.md) - nix-on-droid installation guide for Android

### Operations

- [remote-build.md](remote-build.md) - Build B450M and ThinkPad packages on UM790 over Tailscale
- [B450M-Pro4-HDD-service-storage.md](B450M-Pro4-HDD-service-storage.md) - B450M-Pro4 HDD service storage setup
- [B450M-Pro4-s3s.md](B450M-Pro4-s3s.md) - s3s (Splatoon 3 stats uploader) workflow
- [hermes-agent-discord.md](hermes-agent-discord.md) - Discord setup for the UM790-Pro Hermes Agent microVM

### Other

- [ctf-tools.md](ctf-tools.md) - CTF toolkit, workflows, and reference resources
- [music-workflow.md](music-workflow.md) - CD ripping and music library management

### Configuration and development

- [Configuration reference](configuration.md) — hosts, modules, and managed tools
- [Firefox](firefox.md) — bookmarks, search engines, and Parfait
- [Agent skills](agent-skills.md) — source maintenance and local development
- [Beeper Server](beeper-server.md)
- [GitHub authentication](ghtkn.md)
- [GhidraMCP](ghidra-mcp.md)
- [Local MCP tunnel](local-mcp-tunnel.md)

## Network topology

- [Main topology](topology/main.svg)
- [Network overview](topology/network.svg)

Generate the diagrams with [nix-topology](https://github.com/oddlama/nix-topology):

```sh
nix build .#topology.x86_64-linux.config.output --out-link result
```
