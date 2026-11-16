#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}
usage() {
  cat <<'HELP'
mobile doctor                  Check SDK, CLI, Java, and KVM
mobile avd-create              Create this shell's AVD without overwriting one
mobile avd-start [flags...]    Start this shell's AVD in the foreground
mobile wait [seconds]          Wait for this shell's emulator to finish booting
mobile android [args...]       Android CLI using the pinned SDK, without metrics
mobile create [args...]        Scaffold using a writable template-download cache
mobile gradle [tasks...]       Run ./gradlew using the pinned SDK and JDK
mobile test [args...]          Run Maestro tests on MOBILE_DEVICE or this shell's AVD
mobile analyze APK OUTPUT     Hash and statically inspect an APK into a new directory

Use adb -s emulator-$MOBILE_PORT for this shell's emulator.
HELP
}
cmd="${1:-help}"
if [[ $# -gt 0 ]]; then shift; fi
case "$cmd" in
help | --help | -h)
  usage
  exit 0
  ;;
esac
: "${MOBILE_WORKSPACE:?Run inside nix develop}"
: "${ANDROID_HOME:?Run inside nix develop}"
case "$cmd" in
doctor)
  failed=0
  for tool in java adb android; do
    if ! command -v "$tool"; then failed=1; fi
  done
  [[ -d "$ANDROID_HOME/platforms" ]] || {
    echo 'SDK platforms missing'
    failed=1
  }
  printf 'SDK: %s\nAVD storage: %s\n' "$ANDROID_HOME" "$ANDROID_AVD_HOME"
  java -version
  android --no-metrics --version
  if [[ $MOBILE_EMULATOR == 1 ]]; then
    if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
      echo '/dev/kvm unavailable: enable host virtualization and kvm group access.'
      failed=1
    fi
    emulator -accel-check || failed=1
  fi
  exit "$failed"
  ;;
avd-create)
  [[ $MOBILE_EMULATOR == 1 ]] || fail 'Enable emulator in nix/settings.nix first.'
  [[ $# == 0 ]] || fail 'Usage: mobile avd-create'
  if [[ -e "$ANDROID_AVD_HOME/$MOBILE_AVD.ini" || -e "$ANDROID_AVD_HOME/$MOBILE_AVD.avd" ]]; then
    fail "AVD already exists: $MOBILE_AVD (kept unchanged)."
  fi
  mkdir -p "$ANDROID_AVD_HOME"
  printf 'no\n' | avdmanager create avd --name "$MOBILE_AVD" --package "$MOBILE_IMAGE"
  ;;
avd-start)
  [[ $MOBILE_EMULATOR == 1 ]] || fail 'Enable emulator in nix/settings.nix first.'
  [[ -e "$ANDROID_AVD_HOME/$MOBILE_AVD.ini" ]] || fail 'Run mobile avd-create first.'
  [[ -r /dev/kvm && -w /dev/kvm ]] || fail '/dev/kvm unavailable; run mobile doctor.'
  exec emulator -avd "$MOBILE_AVD" -port "$MOBILE_PORT" -no-snapshot "$@"
  ;;
wait)
  [[ $# -le 1 ]] || fail 'Usage: mobile wait [seconds]'
  seconds="${1:-180}"
  [[ $seconds =~ ^[1-9][0-9]*$ ]] || fail 'Timeout must be a positive integer.'
  # Bound the entire wait, including adb itself; no unbounded wait-for-device.
  # shellcheck disable=SC2016
  exec timeout "$seconds" bash -c '
      until [[ "$(adb -s "$1" shell getprop sys.boot_completed 2>/dev/null | tr -d "\r")" == 1 ]]; do
        sleep 2
      done
    ' _ "emulator-$MOBILE_PORT"
  ;;
android)
  exec android --no-metrics --sdk="$ANDROID_HOME" "$@"
  ;;
create)
  exec android --no-metrics --sdk="$MOBILE_WORKSPACE/.mobile/bootstrap-sdk" create "$@"
  ;;
gradle)
  [[ -x ./gradlew ]] || fail 'Run from an app directory containing executable ./gradlew.'
  exec ./gradlew "$@"
  ;;
test)
  [[ $# -gt 0 ]] || fail 'Usage: mobile test [Maestro test options] FLOW'
  exec maestro --device "${MOBILE_DEVICE:-emulator-$MOBILE_PORT}" test "$@"
  ;;
analyze)
  [[ $MOBILE_ANALYSIS == 1 ]] || fail 'Enter nix develop .#analysis first.'
  [[ $# == 2 ]] || fail 'Usage: mobile analyze APK OUTPUT'
  apk=$(realpath -- "$1")
  [[ -f $apk ]] || fail "APK not found: $apk"
  output="$2"
  # mkdir fails for existing paths, preventing accidental replacement of evidence.
  mkdir -- "$output"
  sha256sum -- "$apk" >"$output/SHA256SUMS"
  printf '%s\n' "$apk" >"$output/source.txt"
  jadx -d "$output/jadx" "$apk"
  apktool d "$apk" -o "$output/apktool"
  ;;
*)
  usage >&2
  exit 2
  ;;
esac
