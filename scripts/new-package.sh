#!/bin/sh
# Scaffold a minimal bpkg package directory structure.
#
# Usage: scripts/new-package.sh <package-name>
#
# Creates:
#   <name>/
#     manifest
#     buildfile
#     build/
#       bootstrap.build
#       root.build
#     <name>/
#       buildfile
#       <name>.hxx
#       <name>.cxx

set -e

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  echo "usage: $0 <package-name>"
  exit 1
fi

name=$1

if [ -e "$name" ]; then
  echo "error: '$name' already exists" >&2
  exit 1
fi

mkdir -p "$name/build" "$name/$name"

cat >"$name/manifest" <<EOF
: 1
name: $name
version: 0.1.0-a.0.z
summary: $name C++ library
license: MIT
EOF

cat >"$name/buildfile" <<EOF
./: {*/ -build/} manifest
EOF

cat >"$name/build/bootstrap.build" <<EOF
project = $name

using version
using config
using test
using install
using dist
EOF

cat >"$name/build/root.build" <<EOF
cxx.std = latest

using cxx

hxx{*}: extension = hxx
cxx{*}: extension = cxx
EOF

cat >"$name/$name/buildfile" <<EOF
lib{$name}: {hxx cxx}{**}

cxx.poptions =+ "-I\$out_root" "-I\$src_root"

lib{$name}:
{
  cxx.export.poptions = "-I\$out_root" "-I\$src_root"
}
EOF

cat >"$name/$name/$name.hxx" <<EOF
#pragma once

namespace $name
{
  void hello ();
}
EOF

cat >"$name/$name/$name.cxx" <<EOF
#include <$name/$name.hxx>

#include <iostream>

namespace $name
{
  void hello ()
  {
    std::cout << "Hello from $name!" << std::endl;
  }
}
EOF

echo "Created package scaffold in '$name/'"
echo "Next steps:"
echo "  cd $name"
echo "  bdep init --empty"
echo "  bdep config create ../build-gcc @gcc cc config.cxx=g++"
echo "  bdep init @gcc"
echo "  bdep update @gcc"
