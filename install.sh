#!/usr/bin/env sh
# Installs every skill under skills/ and every extension under extensions/ into omp's agent dir.
# From a clone:    sh install.sh
# Without a clone: curl -fsSL https://raw.githubusercontent.com/ataberkus/omp-skills/main/install.sh | sh
# Target: $OMP_AGENT_DIR, default ~/.omp/agent. Existing files with the same name are replaced.
set -eu
agent_dir="${OMP_AGENT_DIR:-$HOME/.omp/agent}"

src=""
case "$0" in
  */install.sh|install.sh) src="$(cd "$(dirname "$0")" && pwd)" ;;
esac
tmp=""
if [ -z "$src" ] || [ ! -d "$src/skills" ]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL https://github.com/ataberkus/omp-skills/archive/refs/heads/main.tar.gz | tar -xz -C "$tmp"
  src="$tmp/omp-skills-main"
fi

mkdir -p "$agent_dir/skills" "$agent_dir/extensions"
for skill in "$src"/skills/*/; do
  name="$(basename "$skill")"
  rm -rf "$agent_dir/skills/$name"
  cp -R "$skill" "$agent_dir/skills/$name"
  echo "skill      $agent_dir/skills/$name"
done
for ext in "$src"/extensions/*; do
  [ -f "$ext" ] || continue
  cp "$ext" "$agent_dir/extensions/"
  echo "extension  $agent_dir/extensions/$(basename "$ext")"
done
printf '\nDone. Restart omp (or open a new session) to load new extensions.\n'
