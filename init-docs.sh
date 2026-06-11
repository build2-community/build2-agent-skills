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
OUTPUT=.docs

git submodule update --init --recursive -- "$TOOLCHAIN"
git submodule update --init -- "$HOWTO"

if [ "$UPGRADE" = 'true' ]; then
  git submodule update --remote --recursive -- "$TOOLCHAIN"
  git submodule update --remote -- "$HOWTO"
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

find "$HOWTO" -name '*.md' \
  | while IFS= read -r src; do
    rel="${src#$HOWTO/}"
    dst="$OUTPUT/HOWTO/$rel"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  done

cli_count=$(find "$OUTPUT" -name '*.cli' | wc -l)
md_count=$(find "$OUTPUT/HOWTO" -name '*.md' | wc -l)
echo "Extracted $cli_count .cli files to $OUTPUT/"
echo "Extracted $md_count .md files to $OUTPUT/HOWTO/"
