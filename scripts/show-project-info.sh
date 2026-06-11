#!/bin/sh
# Run b info on a build2 project directory and display key fields.
#
# Usage: scripts/show-project-info.sh [<dir>]
#
# <dir> defaults to the current directory. Displays: project name, version,
# summary, src-root, out-root, and amalgamation (if set).

set -e

dir=${1:-.}

if ! command -v b >/dev/null 2>&1; then
  echo "error: 'b' not found on PATH" >&2
  echo "See guides/install-bootstrap.md for installation instructions." >&2
  exit 1
fi

if [ ! -d "$dir" ]; then
  echo "error: '$dir' is not a directory" >&2
  exit 1
fi

case "$dir" in
  */) target="$dir" ;;
  *)  target="$dir/" ;;
esac

info=$(b info: "$target" 2>&1) || {
  echo "error: 'b info: $target' failed:" >&2
  echo "$info" >&2
  exit 1
}

extract () {
  field=$1
  printf '%s\n' "$info" | grep "^$field:" | head -1 | sed "s/^$field: *//"
}

project=$(extract project)
version=$(extract version)
summary=$(extract summary)
src_root=$(extract src-root)
out_root=$(extract out-root)
amalgamation=$(extract amalgamation)

echo "Project info: $dir"
echo
printf '%-14s %s\n' "project:"  "${project:-<not set>}"
printf '%-14s %s\n' "version:"  "${version:-<not set>}"
printf '%-14s %s\n' "summary:"  "${summary:-<not set>}"
printf '%-14s %s\n' "src-root:" "${src_root:-<not set>}"
printf '%-14s %s\n' "out-root:" "${out_root:-<not set>}"
if [ -n "$amalgamation" ]; then
  printf '%-14s %s\n' "amalgamation:" "$amalgamation"
fi
