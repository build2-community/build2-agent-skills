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
