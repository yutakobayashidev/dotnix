#!/usr/bin/env bash
# Run from a dotnix checkout on the Grok Bot cloud computer, as box.
set -euo pipefail
grok_home=${HOME:?HOME must be set}

fail() {
  printf 'bootstrap-grok-bot: %s\n' "$*" >&2
  exit 1
}

preflight() {
  [[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || fail 'Expected x86_64 Linux.'
  [[ $(id -un) == box && $(id -u) != 0 ]] || fail 'Run as the existing box user, not with sudo.'
  [[ ! -e /etc/NIXOS ]] || fail 'This bootstrap is for the Grok Bot guest, not a NixOS host.'
  [[ $grok_home == /home/box ]] || fail 'Expected HOME=/home/box. Confirm the guest home and update the host configuration before proceeding.'
  [[ ! -d /nix || -O /nix ]] || fail 'Expected a single-user /nix owned by box. Do not use this script with a multi-user installation.'
}

load_nix_profile() {
  local script
  for script in nix.sh hm-session-vars.sh; do
    [[ -f $grok_home/.nix-profile/etc/profile.d/$script ]] || continue
    # The upstream profile scripts are not guaranteed to support nounset.
    set +u
    # shellcheck disable=SC1090,SC1091
    source "$grok_home/.nix-profile/etc/profile.d/$script"
    set -u
  done
}

has_nix_store() {
  [[ -e /nix/store ]]
}

install_nix() {
  local installer=$1/install-nix
  sudo -n true || fail 'Passwordless sudo is required to create /nix.'
  # Pinned official installer; it also verifies its platform tarball hash.
  curl --fail --show-error --location --proto '=https' --tlsv1.2 \
    https://releases.nixos.org/nix/nix-2.34.9/install -o "$installer"
  printf '%s  %s\n' a03ce2e9eaf4ea1560260b9a93e311dbaf589d28fb5c9318f8d9e768ee6339d8 "$installer" | sha256sum --check --status
  sh "$installer" --no-daemon
}

check_tools() {
  local profile=$grok_home/.nix-profile tool
  [[ $(readlink -f -- "$profile") == /nix/store/* ]] || fail 'The managed Nix profile is missing or broken.'
  for tool in nix git jq rg home-manager; do
    [[ -x $profile/bin/$tool ]] || fail "Managed tool $tool is missing from $profile/bin."
    "$profile/bin/$tool" --version || fail "Managed tool $tool failed its health check."
  done
}

backup_dotfiles() {
  # These shared activation hooks replace targets directly, bypassing HM backups.
  local relative target backup_dir=''
  for relative in .zshenv .zshrc .config/zsh .config/nvim; do
    target=$grok_home/$relative
    [[ -e $target || -L $target ]] || continue
    if [[ -L $target && $(readlink -m -- "$target") == /nix/store/* ]]; then
      continue
    fi
    if [[ -z $backup_dir ]]; then
      mkdir -p "$grok_home/.local/state/dotnix/backups"
      backup_dir=$(mktemp -d "$grok_home/.local/state/dotnix/backups/grok-bot.XXXXXXXX")
      printf 'Preserving existing dotfiles in %s\n' "$backup_dir"
    fi
    mkdir -p "$backup_dir/$(dirname -- "$relative")"
    mv -- "$target" "$backup_dir/$relative"
  done
}

main() {
  local mode=${1:-apply}
  [[ $# -le 1 && ($mode == apply || $mode == --check) ]] || fail 'Usage: bootstrap-grok-bot.sh [--check]'
  preflight
  export NIX_REMOTE=local
  load_nix_profile

  if [[ $mode == --check ]]; then
    check_tools
    return
  fi

  local repo_dir work_dir
  repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
  work_dir=$(mktemp -d)
  # Capture the local path now; it is out of scope when the EXIT trap runs.
  # shellcheck disable=SC2064
  trap "rm -rf -- $(printf '%q' "$work_dir")" EXIT

  if ! command -v nix >/dev/null || ! nix --version >/dev/null 2>&1; then
    if has_nix_store; then
      fail 'An existing /nix/store is present but Nix is unavailable. Repair its profile or installation; this script will not delete it.'
    fi
    install_nix "$work_dir"
    load_nix_profile
    nix --version
  fi

  local -a nix_flags=(--extra-experimental-features 'nix-command flakes' --accept-flake-config)
  local configured_home
  configured_home=$(nix "${nix_flags[@]}" eval --raw --no-write-lock-file \
    "path:$repo_dir#homeConfigurations.grok-bot.config.home.homeDirectory")
  [[ $configured_home == "$grok_home" ]] || fail "Configuration targets $configured_home, but HOME is $grok_home."

  nix "${nix_flags[@]}" build --no-write-lock-file \
    "path:$repo_dir#homeConfigurations.grok-bot.activationPackage" --out-link "$work_dir/home-manager"
  backup_dotfiles
  HOME_MANAGER_BACKUP_EXT=hm-bak "$work_dir/home-manager/activate"
  load_nix_profile
  check_tools
  # Print a command for the caller's next shell, not this process's HOME.
  # shellcheck disable=SC2016
  printf '\nGrok Bot environment applied. In each new shell, run:\n  . "$HOME/.nix-profile/etc/profile.d/nix.sh"\n  . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"\n'
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
