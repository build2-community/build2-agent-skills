#!/bin/sh
# Scan PATH for C++ compilers and print their family, version, and target triplet.
# Output is a table suitable for choosing a value for config.cxx=...
#
# Usage: scripts/probe-compiler.sh
#
# Checks: g++, clang++, c++, and version-suffixed variants (g++-12 through
# g++-15, clang++-14 through clang++-18). Exits 0 if at least one compiler
# is found, 1 if none are found.

set -e

found=false

probe () {
  compiler=$1
  if ! command -v "$compiler" >/dev/null 2>&1; then
    return
  fi
  found=true
  verline=$("$compiler" --version 2>/dev/null | head -1)
  case "$verline" in
    *clang*) family=clang ;;
    *GCC*|*g++*) family=gcc ;;
    *) family=unknown ;;
  esac
  triplet=$("$compiler" -dumpmachine 2>/dev/null) || triplet=unknown
  printf '%-20s %-8s %-24s %s\n' "$compiler" "$family" "$triplet" "$verline"
}

printf '%-20s %-8s %-24s %s\n' COMPILER FAMILY TARGET VERSION
printf '%-20s %-8s %-24s %s\n' '--------------------' '--------' '------------------------' '-------'

probe g++
probe clang++
probe c++
probe g++-12
probe g++-13
probe g++-14
probe g++-15
probe clang++-14
probe clang++-15
probe clang++-16
probe clang++-17
probe clang++-18

if [ "$found" = false ]; then
  echo "No C++ compilers found on PATH." >&2
  echo "Install g++ or clang++ and ensure they are on PATH." >&2
  exit 1
fi
