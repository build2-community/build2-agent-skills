# Tests: Package manifest format

Source documentation: `bpkg/bpkg-manifest-reference.md`


## T001 -- Required fields

**Query:** What are the required fields in a bpkg package manifest?

**Key facts** (all must appear in a correct answer):
- `name` -- the package name.
- `version` -- the package version.
- `summary` -- a short one-line description.
- `license` -- the license expression (SPDX or `other:` scheme).
- Exactly four fields are required; no others are mandatory.

**Source:** `bpkg/bpkg-manifest-reference.md`


## T002 -- Manifest format version

**Query:** What must the first name-value pair in a manifest file contain?

**Key facts** (all must appear in a correct answer):
- The first pair must have an empty name.
- Its value is the manifest format version.
- The format version must currently be `1`.

**Source:** `bpkg/bpkg-manifest-reference.md`


## T003 -- Dollar sign in depends

**Query:** What does the `$` symbol mean in a `depends` version constraint?

**Key facts** (all must appear in a correct answer):
- `$` refers to the version of the primary (current) package.
- It is used to express that a dependency must match the same version as the
  package declaring it.

**Source:** `bpkg/bpkg-manifest-reference.md`


## T004 -- topics field limit

**Query:** How many topics can a package declare in its manifest?

**Key facts** (all must appear in a correct answer):
- A package may declare up to five topics.

**Source:** `bpkg/bpkg-manifest-reference.md`


## T005 -- Build-time dependency marker

**Query:** How do you declare a build-time (rather than run-time) dependency
in a manifest `depends` field?

**Key facts** (all must appear in a correct answer):
- Prefix the dependency entry with `*` to mark it as build-time.
- Example: `depends: * build2 >= 0.15.0`

**Source:** `bpkg/bpkg-manifest-reference.md`


## T006 -- builds field default

**Query:** What does omitting the `builds` field from a manifest imply?

**Key facts** (all must appear in a correct answer):
- Omitting `builds` is equivalent to `builds: default`.
- The package is built for default configurations.

**Source:** `bpkg/bpkg-manifest-reference.md`
