# Packaging an Upstream Changelog with a Non-Canonical Name

See also [step 2 of the packaging guide](../guides/packaging-guide-summary.md#step-2-determine-package-structure)
for the pre-seed workflow and [step 4](../guides/packaging-guide-summary.md#step-4-write-the-root-buildfile)
for the root buildfile `doc{}` group.

## The problem

`bdep new --package` auto-detects a pre-seeded `NEWS`, `CHANGES`, or
`ChangeLog` file and derives the `changes-file` manifest field from it (see
[bdep-new](../bdep/bdep-new.md)). Some upstream projects ship their changelog
under a different name, for example `ChangeLog (Historical).txt` (as seen in
`libsquish`). Auto-detection simply doesn't fire for these, since the
recognized basenames are fixed.

## Two independent facts

1. **`changes-file:` accepts an arbitrary path.** The manifest field is
   defined as `<path> [; <comment>]` -- "Path to a changes/NEWS file" -- with
   no basename restriction (see the
   [bpkg manifest reference](../bpkg/bpkg-manifest-reference.md)). The
   canonical-name recognition (`NEWS`/`CHANGES`/`ChangeLog`) is purely a
   `bdep new --package` generation-time convenience for auto-populating the
   manifest from files already present in the target directory; it is not a
   constraint on the manifest field itself.
2. **`doc{}` and `changes-file:` are unrelated mechanisms.** Listing a file
   as a `doc{}` prerequisite in the root `buildfile` is what makes `dist` and
   `install` pick it up. Setting `changes-file:` in the `manifest` only tells
   bpkg/brep which file to read as the package's changes metadata. Neither
   implies the other: a file referenced by `changes-file:` that isn't also
   listed in `doc{}` won't be distributed or installed.

## Recipe

Don't rename or symlink the file to a canonical name. Symlink it under its
actual name and wire it up by hand.

**Step 2 (pre-seed):**

```
$ ln -s '../upstream/ChangeLog (Historical).txt' 'libsquish/ChangeLog (Historical).txt'
```

Auto-detection won't pick this up (expected), so also set the field by hand
in Step 3.

**Step 3 (manifest):**

```
changes-file: ChangeLog (Historical).txt
```

**Step 4 (root buildfile):** list it as a `doc{}` prerequisite. Quote the
name since it contains a space and parentheses:

```
./: {*/ -build/}                                          \
    doc{README.md PACKAGE-README.md "ChangeLog (Historical).txt"} \
    legal{LICENSE} manifest
```

## When symlinking to a canonical name is still useful

If you're generating fresh with `bdep new --package` and want auto-detection
to populate `changes-file` for you, pre-seeding under a canonical name (for
example `ln -s '../upstream/ChangeLog (Historical).txt' libfoo/ChangeLog`)
works too. It's a cosmetic convenience for that one command, not a
requirement, and the `doc{}` listing in Step 4 is still needed regardless of
which name ends up in `manifest`.

## See Also

- [`packaging-guide-summary`](../guides/packaging-guide-summary.md) -- full packaging workflow, Steps 2-4
- [`bpkg-manifest-reference`](../bpkg/bpkg-manifest-reference.md) -- `changes-file` field definition
- [`bdep-new`](../bdep/bdep-new.md) -- pre-seed auto-detection of `NEWS`/`CHANGES`/`ChangeLog`
