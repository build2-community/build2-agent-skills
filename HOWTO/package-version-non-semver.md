# Packaging Projects That Don't Use Semver

Two strategies are available: coerce to semver or use the upstream version
as-is. See the [package version format](../bpkg/bpkg-manifest-reference.md#package-version-format)
for the full specification.

## Strategy 1: Coerce to semver

Derive a semver-like version from the upstream version (e.g., `20210824` ->
`2021.8.24`). The version is syntactically semver but not semantically -- avoid
semver-style constraints like `^2021.8.24`.

Advantage: the [`version` module](../guides/build2-modules-core.md#version-module)
and all [`bdep`](../bdep/bdep-release.md) commands work as normal.

Document the original upstream version in `manifest`:

```
name: hello
version: 2021.8.24
upstream-version: 20210824
```

## Strategy 2: Use upstream version as-is

Use the upstream value directly (adjusting only to satisfy the package version
syntax, e.g., stripping `-`). This makes the package version unambiguously
non-semver.

Disadvantage: the `version` module and most `bdep` commands (including
`bdep-release`) cannot be used. `bdep-ci` and `bdep-publish` are still
available with extra steps.

Extract the version in `build/bootstrap.build` manually:

```
project = hello
version = $process.run(sed -n -e 's/^version: (.+)/\1/p' $src_root/manifest)

dist.package = $project-$version

using config
using test
using install
using dist
```

To use [`bdep-ci`](../bdep/bdep-ci.md) and [`bdep-publish`](../bdep/bdep-publish.md),
configure an out-of-source build and forward the source directory to it:

```
$ b configure: hello/@hello-gcc/ config.cxx=g++
$ b configure: hello/@hello-gcc/,forward
```

Then run from the project directory:

```
$ cd hello/
$ bdep ci --forward
$ bdep publish --forward --section=stable
```

The `--section` must be explicit because it cannot be deduced from a
non-semver version.
