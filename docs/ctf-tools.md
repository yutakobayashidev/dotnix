# CTF Tools and Resources

This repository provides an opt-in toolkit for CTFs, Hack The Box, reverse
engineering, and authorized security testing. Use these tools only against
systems you own or have explicit permission to test.

## Enable the toolkit

Enable the profile from a NixOS host configuration:

```nix
my.profiles.pentest.enable = true;
```

The system profile cascades into Home Manager. It is already enabled on the
ThinkPad. The profile also enables Wireshark packet capture and the existing
[GhidraMCP integration](ghidra-mcp.md).

## Installed toolkit

| Area                         | Tools                                                                                 | Primary use                                                                             |
| ---------------------------- | ------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Recon and OSINT              | `amass`, `nmap`, `arp-scan`                                                           | Discover domains, hosts, and exposed services                                           |
| Active Directory and Windows | `netexec` (`nxc`), Impacket                                                           | Enumerate and interact with Windows, SMB, LDAP, Kerberos, and related services          |
| Web                          | `ffuf`, `feroxbuster`, `nuclei`, `sqlmap`, `mitmproxy`, OWASP ZAP, `curl-impersonate` | Discover content, test known patterns, inspect HTTP traffic, and validate SQL injection |
| Pwn and reverse engineering  | Ghidra, `gef`, `pwntools`, ptrlib, `ROPgadget`, `checksec`, `binutils`, `wabt`        | Inspect, debug, and script against native and WebAssembly binaries                      |
| Password testing             | John the Ripper, THC Hydra                                                            | Analyze captured hashes and test authorized online authentication                       |
| Forensics and file analysis  | `binwalk`, `magika`, `yara`                                                           | Identify, extract, and classify files and firmware                                      |
| Mobile                       | `apktool`, `jadx`, `droidperm`                                                        | Inspect Android packages, resources, bytecode, and permissions                          |
| Vulnerability research       | `codex-security`, `vulnix`, `vt`                                                      | Review source, Nix packages, and known file intelligence                                |
| Traffic analysis             | Wireshark                                                                             | Capture and inspect network protocols                                                   |
| Wordlists                    | SecLists                                                                              | Supply discovery, fuzzing, username, and password lists                                 |

Impacket installs a suite of commands rather than one `impacket` executable.
Likewise, the Nix package named `ropgadget` provides the `ROPgadget` command.
Nuclei templates are maintained separately from the scanner itself.

## Recommended resources

### Reverse engineering and pwn

- [Ghidra](https://github.com/NationalSecurityAgency/ghidra) is a software
  reverse-engineering framework for static analysis and decompilation.
- [GEF](https://github.com/bata24/gef) adds CTF-oriented memory, register,
  stack, heap, and disassembly views to GDB.
- [ptrlib](https://github.com/ptr-yudai/ptrlib) is a Python library for writing
  CTF solvers involving processes, sockets, ELF files, packing, cryptography,
  and exploit primitives.

### Web and data analysis

- [CyberChef](https://gchq.github.io/CyberChef/) is a browser-based workbench
  for encoding, decoding, compression, cryptography, and data transformation.
- [PayloadsAllTheThings: SQL Injection](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/SQL%20Injection#union-based-injection)
  collects SQL injection techniques and reference payloads.
- [jq cheat sheet](https://qiita.com/tj2222/items/dd880b1cc5c476fa49bd)
  is a Japanese quick reference for querying and transforming JSON.

## A practical workflow

1. Identify unknown files with `magika`, `file`, `binwalk`, and `checksec`.
2. Use Ghidra, `jadx`, or `wabt` for static analysis based on the target format.
3. Use GDB with GEF for native dynamic analysis.
4. Automate interaction with `pwntools` or ptrlib.
5. For web targets, map the surface with `nmap`, `ffuf`, and `feroxbuster`,
   then use focused tools such as Nuclei, ZAP, mitmproxy, or sqlmap.
6. Record assumptions and results instead of treating scanner output as proof.

The host toolkit is intended for frequently used native tools. Specialized,
stateful, or dependency-heavy environments can be kept in a separate Kali or
lab VM rather than expanding the host profile indefinitely.
