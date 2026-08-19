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

| Area                         | Tools                                                                                                                                                               | Primary use                                                                           |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Recon and OSINT              | `amass`, `subfinder`, `dnsx`, `shuffledns`, `httpx`, `nmap`, `masscan`, `arp-scan`                                                                                  | Discover domains, hosts, and exposed services                                         |
| Active Directory and Windows | `netexec` (`nxc`), Impacket, `enum4linux-ng`, Evil-WinRM, Responder, Certipy, BloodHound Python                                                                     | Enumerate Windows, AD, LDAP, Kerberos, and AD CS configurations                       |
| Web                          | `ffuf`, `feroxbuster`, `katana`, `dalfox`, `nuclei`, `sqlmap`, `mitmproxy`, OWASP ZAP, `curl-impersonate`                                                           | Crawl applications, discover content, test XSS and SQL injection, and inspect traffic |
| Certificates and TLS         | Cert Spotter, `tlsx`, Certigo                                                                                                                                       | Monitor CT logs and collect, inspect, and validate TLS certificates                   |
| Pwn and reverse engineering  | Ghidra, GDB, `gef`, radare2, `pwntools`, ptrlib, Ropper, `ROPgadget`, `one_gadget`, `pwninit`, QEMU, `checksec`, `binutils`, `patchelf`, `strace`, `ltrace`, `wabt` | Inspect, emulate, debug, and script against native and WebAssembly binaries           |
| Password testing             | John the Ripper, Hashcat, THC Hydra                                                                                                                                 | Analyze captured hashes and test authorized online authentication                     |
| Forensics and file analysis  | `binwalk`, ExifTool, Sleuth Kit, Volatility 3, `magika`, `yara`, `foremost`, `steghide`, `stegseek`, `testdisk`, `zsteg`                                            | Identify, extract, recover, and classify files, disks, memory, and firmware           |
| Mobile                       | `apktool`, `jadx`, `droidperm`                                                                                                                                      | Inspect Android packages, resources, bytecode, and permissions                        |
| Cloud security               | Prowler, Scout Suite, CloudFox                                                                                                                                      | Assess cloud configurations and enumerate authorized cloud environments               |
| Kubernetes and containers    | `kubectl`, Helm, Kubescape, kube-bench, Grype, Trivy, Syft                                                                                                          | Inspect clusters, benchmark configurations, scan artifacts, and generate SBOMs        |
| Secrets                      | Gitleaks, TruffleHog                                                                                                                                                | Detect exposed credentials and secrets in repositories and files                      |
| Vulnerability research       | `codex-security`, `osv-scanner`, `vulnix`, `vt`                                                                                                                     | Review source, Nix packages, dependencies, and known file intelligence                |
| Exploit research             | ExploitDB (`searchsploit`)                                                                                                                                          | Search public exploit references for authorized vulnerability research                |
| Pivoting                     | Chisel, Ligolo-ng, Proxychains-NG, sshuttle                                                                                                                         | Reach segmented lab networks through authorized tunnels                               |
| Traffic analysis             | Wireshark, `tcpdump`, `socat`                                                                                                                                       | Capture, inspect, and relay network traffic                                           |
| Wordlists                    | SecLists                                                                                                                                                            | Supply discovery, fuzzing, username, and password lists                               |

Impacket installs a suite of commands rather than one `impacket` executable.
Likewise, the Nix package named `ropgadget` provides the `ROPgadget` command.
Nuclei templates are maintained separately from the scanner itself.
Masscan and tcpdump need root privileges or suitable packet-capture
capabilities. Hashcat needs a working vendor OpenCL, CUDA, or ROCm runtime for
GPU acceleration. Trivy downloads its vulnerability database at runtime.
Volatility 3 is distributed under the non-free Volatility Software License and
provides the `vol` and `volshell` commands.
Responder performs active name-resolution poisoning and needs appropriate
privileges; use it only on an authorized network. Cert Spotter requires a
watchlist before it can monitor domains continuously.
Cloud tools use the caller's configured credentials, while Kubernetes tools
use the active kubeconfig context. Installing QEMU provides emulation commands
but does not enable a system virtualization service or configure KVM access.
Pivoting tools create tunnels or proxy traffic and should only be used on
authorized lab networks. Certipy and BloodHound Python require valid AD access
and are intended for authorized directory assessments.

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

## Future tooling TODO

Evaluate package availability, platform support, closure size, licensing, and
whether each tool belongs on the host or in a Kali/lab VM before enabling it.
Tools already listed in the installed toolkit above are intentionally omitted.

### Highest-priority gaps

- [ ] Add SageMath and Z3 for number theory, finite fields, constraint solving,
      and Crypto CTF challenges.
- [ ] Add angr for symbolic execution and automated path exploration; use its
      Claripy dependency rather than packaging Claripy separately.
- [ ] Add Frida tools for dynamic mobile instrumentation.

### Mobile dynamic analysis

- [ ] Evaluate Frida, Objection, scrcpy, and apk-mitm.
- [ ] Decide whether ADB should remain supplied by the development profile or
      also be available when the pentest profile is enabled independently.

### Crypto and symbolic execution

- [ ] Evaluate Triton alongside angr and Z3.
- [ ] Build a focused Python environment with PyCryptodome, SymPy, and gmpy2.
- [ ] Evaluate RsaCtfTool for common RSA challenge workflows.

### Malware analysis

- [ ] Evaluate capa and FLOSS for executable capability and string analysis.
- [ ] Evaluate pefile, oletools, and Vivisect for PE, Office document, and
      program analysis workflows.

### Firmware and embedded systems

- [ ] Evaluate unblob and UBI Reader for recursive firmware extraction.
- [ ] Evaluate DTC, flashrom, OpenOCD, and minicom for device trees, flash
      access, hardware debugging, and serial consoles.

### Cloud and Kubernetes

- [ ] Evaluate Pacu and the AWS, Google Cloud, and Azure CLIs for isolated
      cloud assessment environments.
- [ ] Evaluate kube-hunter and Cosign to complement the installed Kubernetes
      audit and software supply-chain tools.

### Active Directory and web

- [ ] Evaluate the BloodHound GUI/backend separately from the installed Python
      ingestor.
- [ ] Evaluate ldapsearch and Kerbrute for focused LDAP and Kerberos work.
- [ ] Evaluate Burp Suite, jwt-tool, and Arjun for manual web and API testing;
      prefer Burp in a Kali/lab VM because it is stateful and heavyweight.

### Native reverse engineering

- [ ] Evaluate Rizin, Cutter, rr, Valgrind, and dwarfdump.
- [ ] Keep objdump and readelf supplied by the installed Binutils package.

References: [Frida](https://frida.re/docs/home/),
[angr](https://docs.angr.io/en/latest/),
[SageMath cryptography](https://doc.sagemath.org/html/en/reference/cryptography/index.html),
[capa](https://github.com/mandiant/capa), and
[unblob](https://github.com/onekey-sec/unblob).

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
