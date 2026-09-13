#!/bin/sh
# Initialize submodules and extract docs to .docs/
#
# Run once after cloning, or after updating a submodule, to populate .docs/.
# .docs/ is git-ignored; the submodules are the authoritative source.
#
# Usage: init-docs.sh <upgrade>
#   upgrade  true  -- pull each submodule to latest HEAD before extracting
#            false -- use currently checked-out submodule state
#
# To revert a 'true' run back to pinned commits (clean git status):
#   git submodule deinit --all -f && git submodule update --init

set -e

if [ "$#" -ne 1 ] || { [ "$1" != 'true' ] && [ "$1" != 'false' ]; }; then
  echo "usage: $0 true|false"
  echo "  true   upgrade submodules to latest HEAD before extracting"
  echo "  false  extract from currently checked-out submodule state"
  exit 1
fi

UPGRADE="$1"
TOOLCHAIN=.submodules/build2-toolchain
BUILD2=.submodules/build2
BPKG=.submodules/bpkg
BDEP=.submodules/bdep
LIBBUTL=.submodules/libbutl
HOWTO=.submodules/build2-howto
AUTOCONF=.submodules/libbuild2-autoconf
KCONFIG=.submodules/libbuild2-kconfig
BREP=.submodules/build2-brep
HELLO=.submodules/libbuild2-hello
OUTPUT=.docs

git submodule update --init -- "$TOOLCHAIN"
git submodule update --init -- "$BUILD2"
git submodule update --init -- "$BPKG"
git submodule update --init -- "$BDEP"
git submodule update --init -- "$LIBBUTL"
git submodule update --init -- "$HOWTO"
git submodule update --init -- "$AUTOCONF"
git submodule update --init -- "$KCONFIG"
git submodule update --init -- "$BREP"
git submodule update --init -- "$HELLO"

if [ "$UPGRADE" = 'true' ]; then
  git submodule update --remote -- "$TOOLCHAIN"
  git submodule update --remote -- "$BUILD2"
  git submodule update --remote -- "$BPKG"
  git submodule update --remote -- "$BDEP"
  git submodule update --remote -- "$LIBBUTL"
  git submodule update --remote -- "$HOWTO"
  git submodule update --remote -- "$AUTOCONF"
  git submodule update --remote -- "$KCONFIG"
  git submodule update --remote -- "$BREP"
  git submodule update --remote -- "$HELLO"
fi

rm -rf "$OUTPUT"

# Extract build2-toolchain's own top-level docs (installation and packaging
# guide sources live here, not in any of its nested submodules).
find "$TOOLCHAIN" -name '*.cli' \
  ! -path '*/tests/*'           \
  ! -path '*/test/*'            \
  | while IFS= read -r src; do
    rel="${src#$TOOLCHAIN/}"
    dst="$OUTPUT/$rel"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  done

find "$TOOLCHAIN" -name '*.md' \
  ! -path '*/tests/*'          \
  ! -path '*/test/*'           \
  | while IFS= read -r src; do
    rel="${src#$TOOLCHAIN/}"
    dst="$OUTPUT/$rel"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  done

# Extract build2, bpkg, bdep, and libbutl: each is added directly as its own
# top-level submodule (rather than reached through build2-toolchain's nested
# submodules) so a plain, non-recursive submodule init already reaches them.
for src_dir in "$BUILD2" "$BPKG" "$BDEP" "$LIBBUTL"; do
  name=$(basename "$src_dir")

  find "$src_dir" -name '*.cli' \
    ! -path '*/tests/*'         \
    ! -path '*/test/*'          \
    | while IFS= read -r src; do
      rel="${src#$src_dir/}"
      dst="$OUTPUT/$name/$rel"
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
    done

  find "$src_dir" -name '*.md' \
    ! -path '*/tests/*'        \
    ! -path '*/test/*'         \
    | while IFS= read -r src; do
      rel="${src#$src_dir/}"
      dst="$OUTPUT/$name/$rel"
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
    done
done

find "$HOWTO" -name '*.md' \
  | while IFS= read -r src; do
    rel="${src#$HOWTO/}"
    dst="$OUTPUT/HOWTO/$rel"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  done

# Extract libbuild2-autoconf: README, checks catalog, and tests README.
# checks/ contains the builtin check implementations (.h files) that serve
# as the authoritative source for what the module can detect.
ac_src="$AUTOCONF/libbuild2-autoconf"
ac_dst="$OUTPUT/libbuild2-autoconf"
mkdir -p "$ac_dst/checks"

cp "$AUTOCONF/README.md" "$ac_dst/README.md"

find "$ac_src/libbuild2/autoconf/checks" -name '*.h' \
  | while IFS= read -r src; do
    cp "$src" "$ac_dst/checks/$(basename "$src")"
  done

if [ -f "$AUTOCONF/libbuild2-autoconf-tests/README.md" ]; then
  cp "$AUTOCONF/libbuild2-autoconf-tests/README.md" "$ac_dst/tests-README.md"
fi

# Extract libbuild2-kconfig: README and module manual.
kc_src="$KCONFIG/libbuild2-kconfig"
kc_dst="$OUTPUT/libbuild2-kconfig"
mkdir -p "$kc_dst/doc"

cp "$KCONFIG/README.md" "$kc_dst/README.md"
cp "$kc_src/doc/manual.cli" "$kc_dst/doc/manual.cli"

# Extract libbuild2-hello: README and module source files.
# The source files (init.cxx, init.hxx, export.hxx) are the authoritative
# reference for the module API patterns documented in guides/.
hello_src="$HELLO/libbuild2-hello"
hello_dst="$OUTPUT/libbuild2-hello"
mkdir -p "$hello_dst"

cp "$HELLO/README.md" "$hello_dst/README.md"

find "$hello_src" \( -name '*.hxx' -o -name '*.cxx' \) \
  | while IFS= read -r src; do
    rel="${src#$hello_src/}"
    dst="$hello_dst/$rel"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  done

# Extract brep: .cli files and .md files, excluding test directories.
brep_dst="$OUTPUT/brep"
mkdir -p "$brep_dst"

find "$BREP" -name '*.cli' \
  ! -path '*/tests/*'      \
  ! -path '*/test/*'       \
  | while IFS= read -r src; do
    rel="${src#$BREP/}"
    dst="$brep_dst/$rel"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  done

find "$BREP" -name '*.md' \
  ! -path '*/tests/*'     \
  ! -path '*/test/*'      \
  | while IFS= read -r src; do
    rel="${src#$BREP/}"
    dst="$brep_dst/$rel"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  done

find "$BREP" -name '*.in'     \
  ! -name '*.hxx.in'          \
  ! -path '*/tests/*'         \
  ! -path '*/test/*'          \
  | while IFS= read -r src; do
    rel="${src#$BREP/}"
    dst="$brep_dst/$rel"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  done

cli_count=$(find "$OUTPUT" -name '*.cli' | wc -l)
generic_md_count=$(find "$OUTPUT" -name '*.md' ! -path "$OUTPUT/HOWTO/*" ! -path "$OUTPUT/libbuild2-autoconf/*" ! -path "$OUTPUT/libbuild2-kconfig/*" ! -path "$OUTPUT/brep/*" ! -path "$OUTPUT/libbuild2-hello/*" | wc -l)
md_count=$(find "$OUTPUT/HOWTO" -name '*.md' | wc -l)
h_count=$(find "$ac_dst/checks" -name '*.h' | wc -l)
brep_cli_count=$(find "$brep_dst" -name '*.cli' | wc -l)
brep_md_count=$(find "$brep_dst" -name '*.md' | wc -l)
brep_in_count=$(find "$brep_dst" -name '*.in' ! -name '*.hxx.in' | wc -l)
hello_src_count=$(find "$hello_dst" \( -name '*.hxx' -o -name '*.cxx' \) | wc -l)
echo "Extracted $cli_count .cli files to $OUTPUT/ (includes brep)"
echo "Extracted $generic_md_count .md files from $TOOLCHAIN, $BUILD2, $BPKG, $BDEP, $LIBBUTL to $OUTPUT/"
echo "Extracted $md_count .md files to $OUTPUT/HOWTO/"
echo "Extracted $h_count autoconf check headers to $OUTPUT/libbuild2-autoconf/checks/"
echo "Extracted $brep_cli_count .cli, $brep_md_count .md, $brep_in_count .in files from $BREP to $OUTPUT/brep/"
echo "Extracted $hello_src_count source files from $HELLO to $OUTPUT/libbuild2-hello/"
