#!/bin/bash
# Validate all relative Markdown links in checked-in files.
#
# Usage: scripts/check-links.sh
#
# Scans every .md file and llms.txt tracked by git, extracts relative
# Markdown link targets from [text](target) syntax, and verifies each
# referenced path exists on disk. Prints broken links to stderr as
# "FILE  TARGET". Exits 1 if any broken links are found, 0 if all links resolve.

set -e

root=$(git rev-parse --show-toplevel)
fail=$(mktemp)
trap 'rm -f "$fail"' EXIT

# Matches [text](target) -- capture groups: 1=text, 2=target.
link_re='\[([^]]*)\]\(([^)]+)\)'

# check_file FILE
# Extract and verify all relative markdown links in FILE.
check_file () {
  local file=$1
  local dir
  dir=$(dirname "$root/$file")
  local in_code_block=0

  while IFS= read -r line; do
    [[ "$line" =~ ^(\`\`\`|~~~) ]] && in_code_block=$(( 1 - in_code_block ))
    [[ $in_code_block -eq 1 ]] && continue
    local remainder="$line"
    while [[ "$remainder" =~ $link_re ]]; do
      local target="${BASH_REMATCH[2]}"
      # Advance past this match. Target is a file path (no glob metacharacters).
      remainder="${remainder#*"${target})"}"
      case "$target" in
        http://*|https://*|mailto:*|ftp://*|'#'*) continue ;;
      esac
      # Skip targets that contain characters invalid in file paths (CLI synopsis
      # notation, format strings, etc. caught inside code spans).
      [[ "$target" =~ [[:space:]\<\>\|] ]] && continue
      local path="${target%%#*}"
      [[ -z "$path" ]] && continue
      if [[ ! -e "$dir/$path" ]]; then
        printf '%-55s %s\n' "$file" "$target" >&2
        echo 1 >> "$fail"
      fi
    done
  done < "$root/$file"
}

count=0
while IFS= read -r file; do
  check_file "$file"
  count=$(( count + 1 ))
done < <(git -C "$root" ls-files -- '*.md' 'llms.txt')

printf 'Checked %d files.\n' "$count"

if [[ -s "$fail" ]]; then
  printf 'Broken links found -- see above.\n' >&2
  exit 1
fi
