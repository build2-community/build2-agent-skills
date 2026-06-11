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
