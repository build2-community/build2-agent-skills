# Tests: Package manifest format

Source documentation: `bpkg/bpkg-manifest-reference.md`, `guides/packaging-license.md`


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


## T007 -- builds class expression grammar

**Query:** What is the grammar for the `builds:` manifest field value?

**Key facts** (all must appear in a correct answer):
- An optional underlying class set before `:` defines the base configuration set.
- The class expression is a space-separated list of terms evaluated left to right.
- Each term begins with `+` (add), `-` (subtract), or `&` (intersect).
- Appending `!` to the operator inverts the operand against the underlying set.
- A term may be a class name or a parenthesized sub-expression.

**Source:** `bpkg/bpkg-manifest-reference.md`


## T008 -- build-include/build-exclude first-match-wins rule

**Query:** In what order are `build-include` and `build-exclude` patterns
applied, and what happens when none of them match?

**Key facts** (all must appear in a correct answer):
- Patterns are applied in the order they appear in the manifest.
- The first matching pattern determines whether the package is built for that configuration.
- If no pattern matches, the package is built.

**Source:** `bpkg/bpkg-manifest-reference.md`


## T009 -- platform whitelist without redundant builds: default

**Query:** How do you restrict a package to build only on Linux using
`build-include:` and `build-exclude:`, and is a `builds: default` line needed?

**Key facts** (all must appear in a correct answer):
- Use `build-include: linux**` followed by `build-exclude: **`.
- No `builds:` line is needed.
- Omitting `builds:` defaults to `default`, and `build-exclude: **` makes
  an explicit `builds: default` redundant.

**Source:** `bpkg/bpkg-manifest-reference.md`


## T010 -- pre-defined class names

**Query:** Which build target configuration class names are guaranteed to be
pre-defined in every build bot deployment?

**Key facts** (all must appear in a correct answer):
- `none`, `default`, `all`, `host`, and `build2` are always pre-defined.
- Additional class names such as `linux`, `windows`, `macos` vary by
  build-bot deployment.

**Source:** `bpkg/bpkg-manifest-reference.md`


## T011 -- evaluation order of builds: and build-include:/build-exclude:

**Query:** In what order are `builds:`, `build-include:`, and
`build-exclude:` evaluated when all three are present?

**Key facts** (all must appear in a correct answer):
- `builds:` values are evaluated first to produce the initial configuration set.
- `build-include:` and `build-exclude:` patterns then refine that set.

**Source:** `bpkg/bpkg-manifest-reference.md`


## T012 -- license AND semantics

**Query:** A package requires users to comply with both MIT and BSD-2-Clause
simultaneously. How is that expressed in the manifest?

**Key facts** (all must appear in a correct answer):
- Put both names in a single `license:` value, comma-separated or using the
  SPDX `AND` operator: `license: MIT, BSD-2-Clause` or
  `license: MIT AND BSD-2-Clause`.
- A comma-separated list within one value has AND semantics -- the user must
  comply with every license listed.
- Two separate `license:` lines would instead mean OR (the user may choose
  either), which is the wrong semantics here.

**Source:** `guides/packaging-license.md`


## T013 -- license OR semantics (dual licensing)

**Query:** A project offers its code under either Apache-2.0 or MIT; users
may pick either. How is that written in the manifest?

**Key facts** (all must appear in a correct answer):
- Use two separate `license:` values, one per line:
  ```
  license: Apache-2.0
  license: MIT
  ```
- Multiple `license:` values have OR semantics -- the user may comply with
  any one of them.
- Alternatively, the SPDX OR operator inside a single value works for
  same-scheme names: `license: Apache-2.0 OR MIT`.

**Source:** `guides/packaging-license.md`


## T014 -- license comment syntax

**Query:** What is the syntax for adding a human-readable comment to a
`license:` value, and what rules apply to the comment text?

**Key facts** (all must appear in a correct answer):
- Append `;` followed by the comment text to the value:
  `license: MPL-2.0 ; Mozilla Public License 2.0.`
- The comment is part of the value (not a `#`-style manifest comment), so it
  is preserved and displayed to users.
- The comment must be one or more full sentences: start with a capital letter
  and end with a period.
- A non-comment semicolon within the value must be escaped with `\`.

**Source:** `guides/packaging-license.md`


## T015 -- other: scheme predefined names

**Query:** What are the predefined `other:` license names and what does each
mean?

**Key facts** (all must appear in a correct answer):
- `other: public domain` -- released into the public domain.
- `other: available source` -- not free/open source but source code is publicly
  accessible.
- `other: proprietary` -- not free/open source.
- `other: TODO` -- license is not yet decided.
- For new public-domain projects, `Unlicense` (an SPDX identifier) is
  preferred over `other: public domain`.

**Source:** `guides/packaging-license.md`


## T016 -- bdep new detects only one license

**Query:** A third-party project is dual-licensed under Apache-2.0 and MIT.
After running `bdep new`, the generated manifest shows only one of them. Why,
and what must be done?

**Key facts** (all must appear in a correct answer):
- `bdep new` auto-detects the license by reading the `LICENSE` file (or
  `LICENSE.txt`, `LICENSE.md`, `COPYING`, `UNLICENSE`) but it will detect at
  most one license.
- The second license must be added to the manifest by hand after generation.

**Source:** `guides/packaging-license.md`
