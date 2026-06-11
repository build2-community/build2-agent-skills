#!/bin/sh
# Validate a bpkg manifest file for required and recommended fields.
#
# Usage: scripts/check-manifest.sh <path>
#
# Required fields (exit 1 if any missing): name, version, summary, license
# Recommended fields (warned, exit 0): url, email, description

set -e

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  echo "usage: $0 <manifest-path>" >&2
  exit 1
fi

manifest=$1

if [ ! -f "$manifest" ]; then
  echo "error: '$manifest' not found or not a file" >&2
  exit 1
fi

has_field () {
  field=$1
  grep -q "^$field:" "$manifest"
}

ok=true

check_required () {
  field=$1
  if has_field "$field"; then
    printf '%-14s OK\n' "$field"
  else
    printf '%-14s MISSING (required)\n' "$field" >&2
    ok=false
  fi
}

check_recommended () {
  field=$1
  if has_field "$field"; then
    printf '%-14s OK\n' "$field"
  else
    printf '%-14s missing (recommended)\n' "$field"
  fi
}

echo "Checking: $manifest"
echo

check_required name
check_required version
check_required summary
check_required license

echo
check_recommended url
check_recommended email
check_recommended description

echo

if [ "$ok" = false ]; then
  echo "FAIL: manifest is missing required fields." >&2
  exit 1
fi

echo "OK: all required fields present."
