#!/bin/sh
# Initialize submodules and extract docs to .docs/
#
# Run once after cloning, or after updating a submodule, to populate .docs/.
# .docs/ is git-ignored; the submodules are the authoritative source.

set -e

TOOLCHAIN=build2-toolchain
HOWTO=build2-howto
OUTPUT=.docs

git submodule update --init --recursive -- "$TOOLCHAIN"
git submodule update --init -- "$HOWTO"

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
