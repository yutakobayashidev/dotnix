#!/usr/bin/env bash
# Exercise recovery and activation ordering without touching a real Nix store.
# The sourced main calls the mocked functions indirectly.
# shellcheck disable=SC2329
set -euo pipefail
test_repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT

run_case() (
  local scenario=$1
  # shellcheck disable=SC1091
  source "$test_repo_dir/scripts/bootstrap-grok-bot.sh"
  grok_home="$test_dir/$scenario"
  mkdir -p "$grok_home"
  if [[ $scenario == existing-files ]]; then
    printf 'original shell config\n' >"$grok_home/.zshrc"
    mkdir -p "$grok_home/.config/nvim"
    printf 'original editor config\n' >"$grok_home/.config/nvim/init.lua"
    ln -s /nix/store/old-managed-zshenv "$grok_home/.zshenv"
  fi
  local log=$grok_home/actions
  : >"$log"
  local installed=false
  [[ $scenario == fresh || $scenario == broken-store ]] || installed=true

  # Only the platform, filesystem and installer boundaries are mocked.
  preflight() { :; }
  load_nix_profile() { printf 'profile\n' >>"$log"; }
  has_nix_store() { [[ $scenario == broken-store ]]; }
  install_nix() {
    printf 'install\n' >>"$log"
    installed=true
  }
  check_tools() {
    nix --version >/dev/null
    printf 'check\n' >>"$log"
  }
  nix() {
    case " $* " in
    *' --version '*) [[ $installed == true ]] ;;
    *' eval '*)
      if [[ $scenario == wrong-home ]]; then printf /wrong-home; else printf '%s' "$grok_home"; fi
      ;;
    *' build '*)
      printf 'build\n' >>"$log"
      [[ $scenario != failed-build ]] || return 1
      local output=${!#}
      mkdir -p "$output"
      cat >"$output/activate" <<EOF
#!/usr/bin/env bash
[[ \$HOME_MANAGER_BACKUP_EXT == hm-bak ]] || exit 1
printf 'activate\\n' >> '$log'
EOF
      chmod +x "$output/activate"
      ;;
    *)
      printf 'Unexpected nix command: %s\n' "$*" >&2
      return 1
      ;;
    esac
  }

  if [[ $scenario == check ]]; then main --check; else main; fi
)

run_case fresh
diff -u <(printf 'profile\ninstall\nprofile\nbuild\nactivate\nprofile\ncheck\n') "$test_dir/fresh/actions"
run_case existing
diff -u <(printf 'profile\nbuild\nactivate\nprofile\ncheck\n') "$test_dir/existing/actions"
run_case check
diff -u <(printf 'profile\ncheck\n') "$test_dir/check/actions"
run_case existing-files
backup_dirs=("$test_dir/existing-files/.local/state/dotnix/backups/"*)
[[ ${#backup_dirs[@]} == 1 ]]
diff -u <(printf 'original shell config\n') "${backup_dirs[0]}/.zshrc"
diff -u <(printf 'original editor config\n') "${backup_dirs[0]}/.config/nvim/init.lua"
[[ -L $test_dir/existing-files/.zshenv ]]
[[ ! -e $test_dir/existing-files/.zshrc && ! -e $test_dir/existing-files/.config/nvim ]]

for scenario in broken-store wrong-home failed-build; do
  # Run in a separate shell so errexit remains enabled inside the test case.
  export test_repo_dir test_dir
  export -f run_case
  if bash -c 'run_case "$1"' _ "$scenario" >"$test_dir/$scenario.out" 2>&1; then
    printf 'Expected %s to fail\n' "$scenario" >&2
    exit 1
  fi
  if rg -q '^(install|activate)$' "$test_dir/$scenario/actions"; then
    printf 'Unexpected mutation in %s\n' "$scenario" >&2
    exit 1
  fi
done

check_managed_profile() (
  # shellcheck disable=SC1091
  source "$test_repo_dir/scripts/bootstrap-grok-bot.sh"
  grok_home=$test_dir/health
  # Simulate profile resolution while keeping all fixture binaries outside /nix.
  readlink() { printf '/nix/store/test-profile\n'; }
  check_tools
)
mkdir -p "$test_dir/health/.nix-profile/bin"
for tool in nix git jq rg home-manager; do
  printf '#!/usr/bin/env bash\nexit 0\n' >"$test_dir/health/.nix-profile/bin/$tool"
  chmod +x "$test_dir/health/.nix-profile/bin/$tool"
done
check_managed_profile
rm "$test_dir/health/.nix-profile/bin/rg"
export -f check_managed_profile
if bash -c check_managed_profile >"$test_dir/health.out" 2>&1; then
  printf 'Missing managed rg must fail even when rg exists on PATH\n' >&2
  exit 1
fi

(
  # shellcheck disable=SC1091
  source "$test_repo_dir/scripts/bootstrap-grok-bot.sh"
  grok_home=$test_dir/session
  grok_test_hm_loaded=false
  mkdir -p "$grok_home/.nix-profile/etc/profile.d"
  printf 'grok_test_nix_loaded=true\n' >"$grok_home/.nix-profile/etc/profile.d/nix.sh"
  # Expand the variable when the generated profile is sourced, not when written.
  # shellcheck disable=SC2016
  printf '%s\n' 'grok_test_hm_loaded=$grok_test_nix_loaded' >"$grok_home/.nix-profile/etc/profile.d/hm-session-vars.sh"
  load_nix_profile
  [[ $grok_test_hm_loaded == true ]]
)

# Test the real guard before any installation or activation can occur.
if bash "$test_repo_dir/scripts/bootstrap-grok-bot.sh" unexpected >"$test_dir/usage.out" 2>&1; then
  exit 1
fi
if bash -c 'source "$1"; grok_home=/not-the-guest-home; main' _ "$test_repo_dir/scripts/bootstrap-grok-bot.sh" >"$test_dir/guard.out" 2>&1; then
  exit 1
fi
printf 'bootstrap-grok-bot tests passed\n'
