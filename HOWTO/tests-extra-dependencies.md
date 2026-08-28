# Tests with Extra Dependencies

When tests (or examples/benchmarks) require a dependency that the library
itself does not need (e.g., a testing framework), factor the tests into a
separate package in the same git repository. This way the extra dependency
is only built when users explicitly want to run the tests.

## Naming convention

Use the main package name with a suffix: `libhello-tests`, `libhello-examples`,
`libhello-benchmarks`.

## Setting up the structure

Use [`bdep-new`](../bdep/bdep-new.md) to scaffold:

```
$ bdep new -t empty libhello
$ cd libhello
$ bdep new --package -l c++ -t lib libhello
$ bdep new --package -l c++ -t exe libhello-tests
```

## Linking the packages

Add a `tests` field to `libhello/manifest` (use `examples` or `benchmarks` as
appropriate). This tells bpkg that the tests for `libhello` live in
`libhello-tests` and implies a dependency on `libhello` -- no explicit
`depends` on `libhello` is needed in `libhello-tests/manifest`:

```
tests: libhello-tests == $
```

See the [`tests`, `examples`, `benchmarks` manifest fields](../bpkg/bpkg-manifest-reference.md#test-package-fields)
for details.

The same two conventions below apply to every accompanying package type
recognized by those fields (`-tests`, `-examples`, `-benchmarks`). They are
sibling packages in the same repository, not an in-tree `tests/` (or
`examples/`, `benchmarks/`) subproject.

## Manifest summary

Copy the main package `summary` unchanged. Append ` (tests)`, ` (examples)`,
or ` (benchmarks)` to mark the accompanying kind. Do not rewrite the summary
(no "tests for ...", no appending the bare word `tests`).

The `summary` field is stored as a single string. It has no `[; <comment>]`
grammar, so a semicolon suffix would appear in the displayed text. Use the
parenthetical instead.

```
# libhello/manifest
summary: Friendly greeting C++ library

# libhello-tests/manifest
summary: Friendly greeting C++ library (tests)

# libhello-examples/manifest
summary: Friendly greeting C++ library (examples)

# libhello-benchmarks/manifest
summary: Friendly greeting C++ library (benchmarks)
```

## PACKAGE-README.md

An accompanying package does not keep the generated Usage-style
`PACKAGE-README.md`. Use the short template below for every type. Substitute
the type in the package name, the parenthetical heading suffix, and the
opening sentence (`test suite`, `examples`, or `benchmarks`). Keep the
Importable targets and Configuration variables sections even when empty.

The title after the hyphen is the same human-readable title as the main
package `PACKAGE-README.md` heading. The peculiarities paragraph is optional.
Omit it when there is nothing noteworthy. Only mention a [patch applied to
upstream source](../guides/packaging-guide-antipatterns.md#how-do-i-patch-upstream-source-code)
here if it is useful to and actually affects consumers (a behavior change, a
dropped/added feature, a platform workaround). A patch with no
consumer-visible effect, such as adding a missing `#include`, needs no
mention: it makes no real difference to consumers.

```
# lib<pkg>-tests - <same title as main package> (tests)

This is a `build2` package containing the test suite for the
[`<project>`](https://github.com/<org>/<project>) library.
<brief details if there are peculiarities, e.g. a consumer-affecting
patch or noteworthy changes like "using doctest instead of catch2",
or if only a subset of the upstream tests are covered>


## Importable targets

This package exports no targets.


## Configuration variables

This package provides no configuration variables.
```

For examples or benchmarks the heading ends with `(examples)` or
`(benchmarks)`, and the first sentence names that kind instead of "the test
suite".

## What to keep in the main package

Keep at least a smoke test in the library itself so users can do a basic
sanity check without pulling in the separate test package and all its
dependencies.

## Version management

Both packages normally share the same version.
[`bdep-release`](../bdep/bdep-release.md) updates both automatically.

## Running CI

Submit the library, not the test package. bpkg pulls in the test package
automatically:

```
$ bdep ci -d libhello
```

See [`bdep-ci`](../bdep/bdep-ci.md) for options.

## See Also

- [testscript-summary.md](../guides/testscript-summary.md) -- Testscript reference
- [bdep-new.md](../bdep/bdep-new.md) -- creating new packages (test-only package layout)
- [packaging-guide-testing.md](../guides/packaging-guide-testing.md) -- testing packages end-to-end
- [bdep-ci.md](../bdep/bdep-ci.md)
