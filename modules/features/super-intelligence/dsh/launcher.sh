# Keep dsh's positional profile shorthand and plugin management dispatch.
case "${1-}" in
plugin | --version | -V | --help | -h | "") exec '@dsh@' "$@" ;;
esac
for arg in "$@"; do
  # Upstream explicitly rejects patches with this inspection command.
  if [[ $arg == --dump-default-config ]]; then
    exec '@dsh@' "$@"
  fi
done
case "$1" in
-*) ;;
*) set -- --profile "$@" ;;
esac
exec '@dsh@' --patch '@patch@' "$@"
