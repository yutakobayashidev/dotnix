# GhidraMCP

The ThinkPad's pentest profile installs Ghidra 11.3.2 with the GhidraMCP 1.4
extension and registers its stdio bridge with Home Manager's MCP registry.
The Niri session enables Java's non-reparenting window-manager mode so Ghidra
and other Java GUI applications render correctly.

## First-time setup

1. Start Ghidra and open a CodeBrowser tool.
2. Enable `GhidraMCPPlugin` under `File -> Configure -> Developer`.
3. Set `Edit -> Tool Options -> GhidraMCP HTTP Server -> Server Port` to
   `38473`.
4. Reload the plugin or restart Ghidra, then open the program to analyze.
5. Start an MCP client. Home Manager supplies the bridge command and its
   `http://127.0.0.1:38473` endpoint.

The bridge starts on demand, but tool calls require Ghidra to be running with
the plugin enabled and a program open.
