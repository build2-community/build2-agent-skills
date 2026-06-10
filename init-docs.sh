#!/bin/sh
# Initialize build2-toolchain submodule and extract .cli source docs to .docs/
#
# Run once after cloning, or after updating the submodule, to populate .docs/.
# .docs/ is git-ignored; the submodule is the authoritative source.

set -e

SUBMODULE=build2-toolchain
OUTPUT=.docs

git submodule update --init --recursive -- "$SUBMODULE"

rm -rf "$OUTPUT"

find "$SUBMODULE" -name '*.cli' \
  ! -path '*/tests/*'          \
  ! -path '*/test/*'           \
  | while IFS= read -r src; do
    rel="${src#$SUBMODULE/}"
    dst="$OUTPUT/$rel"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  done

count=$(find "$OUTPUT" -name '*.cli' | wc -l)
echo "Extracted $count .cli files to $OUTPUT/"
