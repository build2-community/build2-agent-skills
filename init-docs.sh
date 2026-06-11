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
  echo "  true   upgrade submodules to latest HEAD (recursively) before extracting"
  echo "  false  extract from currently checked-out submodule state"
  exit 1
fi

UPGRADE="$1"
TOOLCHAIN=build2-toolchain
HOWTO=build2-howto
AUTOCONF=libbuild2-autoconf
OUTPUT=.docs

git submodule update --init --recursive -- "$TOOLCHAIN"
git submodule update --init -- "$HOWTO"
git submodule update --init -- "$AUTOCONF"

if [ "$UPGRADE" = 'true' ]; then
  git submodule update --remote --recursive -- "$TOOLCHAIN"
  git submodule update --remote -- "$HOWTO"
  git submodule update --remote -- "$AUTOCONF"
fi

rm -rf "$OUTPUT"

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

cli_count=$(find "$OUTPUT" -name '*.cli' | wc -l)
toolchain_md_count=$(find "$OUTPUT" -name '*.md' ! -path "$OUTPUT/HOWTO/*" ! -path "$OUTPUT/libbuild2-autoconf/*" | wc -l)
md_count=$(find "$OUTPUT/HOWTO" -name '*.md' | wc -l)
h_count=$(find "$ac_dst/checks" -name '*.h' | wc -l)
echo "Extracted $cli_count .cli files to $OUTPUT/"
echo "Extracted $toolchain_md_count .md files from $TOOLCHAIN to $OUTPUT/"
echo "Extracted $md_count .md files to $OUTPUT/HOWTO/"
echo "Extracted $h_count autoconf check headers to $OUTPUT/libbuild2-autoconf/checks/"
