#!/bin/sh
# Verify that the build2 toolchain is installed and report versions.
# Exits with status 1 if any tool is not found on PATH.
#
# Usage: scripts/verify-install.sh

set -e

ok=true

check () {
  tool=$1
  if command -v "$tool" >/dev/null 2>&1; then
    version=$("$tool" --version 2>/dev/null | head -1)
    printf '%-8s %s\n' "$tool" "$version"
  else
    printf '%-8s NOT FOUND\n' "$tool" >&2
    ok=false
  fi
}

check b
check bpkg
check bdep
check bx

if [ "$ok" = false ]; then
  echo >&2
  echo "One or more build2 tools are missing from PATH." >&2
  echo "See guides/install-bootstrap.md for installation instructions." >&2
  exit 1
fi
