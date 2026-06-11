#!/bin/sh
# Run bpkg test on all held packages in a bpkg configuration directory.
#
# Usage: scripts/run-tests.sh <config-dir>
#
# Validates that <config-dir> is a bpkg configuration by checking for
# build/config.build, then runs: bpkg -d <config-dir> test --all

set -e

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  echo "usage: $0 <config-dir>" >&2
  exit 1
fi

config_dir=$1

if [ ! -d "$config_dir" ]; then
  echo "error: '$config_dir' is not a directory" >&2
  exit 1
fi

if [ ! -f "$config_dir/build/config.build" ]; then
  echo "error: '$config_dir' does not look like a bpkg configuration" >&2
  echo "       (expected build/config.build to exist)" >&2
  exit 1
fi

echo "Configuration: $config_dir"
echo "Running: bpkg test --all"
echo

if bpkg -d "$config_dir" test --all; then
  echo
  echo "PASS"
else
  echo
  echo "FAIL" >&2
  exit 1
fi
