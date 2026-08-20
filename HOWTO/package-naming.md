# Naming Packages for Third-Party Projects

See also [step 2 of the packaging guide](../guides/packaging-guide-summary.md#step-2-determine-package-structure)
for the full decision tree.

## Library vs executable naming

Use the `lib` prefix for library packages to avoid future name conflicts with
executables. Example: the `lz4` project provides both a library and a CLI
tool. The correct split is:

- Git repository: `lz4`
- Library package: `liblz4`
- Executable package: `lz4`

```
$ bdep new -t empty lz4
$ cd lz4
$ bdep new --package -l c -t lib liblz4
$ bdep new --package -l c -t exe lz4
```

See [`bdep-new`](../bdep/bdep-new.md) for the full option reference.

Add the `lib` prefix even if you intend to package only the library initially.
Removing it later is disruptive.

## When the lib prefix can be omitted

On `cppget.org`, a library is accepted without the `lib` prefix only when
both of the following hold:

1. The upstream project does not provide an executable with the same name.
2. No well-known project provides an executable with the same name (verified
   against the Debian package repository).

## Naming case: repository, project, package

Three names are involved in packaging a third-party project. They do not
follow the same case convention.

| Name | Case | Example (upstream `MoltenVK`) |
|---|---|---|
| Git repository | Mirror the upstream repository name exactly, including case. Drop only a `build2-` prefix or `-package` suffix. | `MoltenVK` |
| Manifest `project:` and `project =` in `build/bootstrap.build` | Lowercase, even when the repository is mixed case. | `project: moltenvk` |
| Manifest `name:` | Lowercase by default. | `libmoltenvk` |

The `Vulkan-Loader` package is the same split done correctly: repository
`Vulkan-Loader`, `project: vulkan-loader`, packages `libvulkan-loader` and
`vulkan-loader-asm-offset`.

This is convention, not a parser rule. `project` is typed as the same
`package_name` as `name:` (`libbpkg/manifest.hxx`). Comparison is
case-insensitive, and original case is preserved for display and file names
([Case Sensitivity](../guides/bpkg-package-name-version.md#case-sensitivity)).
Nothing rejects `project: MoltenVK`. A mixed-case `project:` that copies the
repository name will publish.

The packaging guide's Qt rows (`Qt5` / `Qt5Moc` / `libQt5Core`) are the
documented exception: mixed-case package names when that mixed case *is*
the upstream identifier
(`.submodules/build2-toolchain/doc/packaging.cli`, `#core-package-name`).
Do not copy the repository's mixed case into `project:` just because the
repo kept it.

## Target names vs package names

Build2 target identifiers (`lib{MoltenVK}`) live in a separate namespace
from `name:` and `project:`. They can diverge from both.

When the library's output is consumed outside the build2 graph, match
upstream's artifact. See
[match-upstream-library-name.md](./match-upstream-library-name.md) for the
preference order and the `bin.lib.version` / `bin.lib.prefix` / `extension`
knobs.

## See Also

- [packaging-guide-summary.md](../guides/packaging-guide-summary.md): full packaging workflow including package structure decisions
- [match-upstream-library-name.md](./match-upstream-library-name.md): matching upstream target names, SONAME, and file prefix
- [bpkg-package-name-version.md](../guides/bpkg-package-name-version.md): package name rules, version format, and constraint syntax
- [bdep-new.md](../bdep/bdep-new.md): creating multi-package project repositories
- [package-version-non-semver.md](./package-version-non-semver.md): handling upstream projects that don't use semantic versioning
- [package-version-none.md](./package-version-none.md): handling upstream projects with no version
