# Session Context

## User Prompts

### Prompt 1

extensions = [
      inputs.gh-graph.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]; これ追加されてる？調べて

### Prompt 2

extensionsとして追加しないと

### Prompt 3

yuta@nixos  ~/ghq/github.com/yutakobayashidev/dotnix   main ✚  sudo nixos-rebuild switch --flake /home/yuta/ghq/github.com/yutakobayashidev/dotnix#nixos
[sudo] yuta のパスワード:
warning: Git tree '/home/yuta/ghq/github.com/yutakobayashidev/dotnix' is dirty
building the system configuration...
warning: Git tree '/home/yuta/ghq/github.com/yutakobayashidev/dotnix' is dirty
error:
       … while calling the 'head' builtin
         at REDACTED...

### Prompt 4

[Request interrupted by user]

### Prompt 5

yuta@nixos  ~/ghq/github.com/yutakobayashidev/dotnix   main ✚  sudo nixos-rebuild switch --flake /home/yuta/ghq/github.com/yutakobayashidev/dotnix#nixos
warning: Git tree '/home/yuta/ghq/github.com/yutakobayashidev/dotnix' is dirty
building the system configuration...
warning: Git tree '/home/yuta/ghq/github.com/yutakobayashidev/dotnix' is dirty
Checking switch inhibitors... done
activating the configuration...
setting up /etc...
reloading user units for yuta...
restarting sysinit-...

