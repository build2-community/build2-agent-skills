# Packaging Projects With No Version

A build2 package must have a version. Two sensible options exist depending on
the project's maturity and likelihood of adopting versioning.

## Option 1: Use 0.0.Z semver

Start with semver, restricting yourself to incrementing only the patch
component (`0.0.1`, `0.0.2`, ...). The reasoning: if upstream eventually
adopts versioning they will likely start at `0.1.0` or `1.0.0`, which orders
correctly after your `0.0.Z` releases.

Advantage: the [`version` module](../guides/build2-modules-core.md#version-module)
and all `bdep` commands including [`bdep-release`](../bdep/bdep-release.md)
work as normal.

Best for immature projects likely to adopt versioning in future.

## Option 2: Use a date

Use the commit or release date in `YYYYMMDD` format (e.g., `20210824`). This
format sorts correctly as a package version and makes it clear that semver
semantics do not apply.

Disadvantage: the `version` module and most `bdep` commands cannot be used.
See [package-version-non-semver](./package-version-non-semver.md#strategy-2-use-upstream-version-as-is)
for the workflow.

Best for mature projects unlikely to adopt versioning.

## Handling a future version scheme change: epochs

If you later need to switch versioning schemes (e.g., you used `0.0.Z` but
upstream starts using dates that clash), use a version epoch. Epochs ensure
correct ordering across scheme changes. See the
[package version format](../bpkg/bpkg-manifest-reference.md#package-version-format)
for the full syntax.

Example: switching from semver `0.0.3` to upstream's date scheme:

```
name: libfoo
version: +2-20210824
```

The `+2-` prefix denotes the second epoch (default epoch is `1`). Use epoch
`0` when you know the current scheme is temporary and upstream versioning
is imminent.

## See Also

- [bpkg manifest reference](../bpkg/bpkg-manifest-reference.md) -- version field and epoch syntax
- [build2 version module](../guides/build2-module-version.md) -- version variables and snapshot versioning
- [package-version-non-semver.md](./package-version-non-semver.md)
