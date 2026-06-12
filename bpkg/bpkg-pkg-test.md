# bpkg-pkg-test -- test package

## Synopsis

```
bpkg pkg-test|test [<options>] [<vars>] <pkg>...
bpkg pkg-test|test [<options>] [<vars>] --all|-a
bpkg pkg-test|test [<options>] [<vars>] (--all-pattern <pattern>)...
```

## Description

The `pkg-test` command tests the specified packages (the first form), all the
held packages (the second form, see [bpkg-pkg-status](bpkg-pkg-status.md)), or
all the held packages that match any of the specified wildcard patterns (the
third form). Additionally, immediate or all dependencies of these packages can
also be tested by specifying the `--immediate|-i` or `--recursive|-r` options,
respectively. Underneath, this command doesn't do much more than run `b test`.
In the first form the specified packages must have been previously configured
with [bpkg-pkg-build](bpkg-pkg-build.md) or `bpkg-pkg-configure`.

Additional command line variables (_vars_, normally `config.*`) can be passed to
the build system. Such variables apply to all the specified packages but can
also be specified to only apply to specific packages using the argument grouping
mechanism (see `bpkg-argument-grouping` for details).

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--all`, `-a` | | Test all held packages. |
| `--all-pattern` | _pattern_ | Test held packages that match the specified wildcard pattern. Repeat this option to match multiple patterns. Note that you may need to quote the pattern to prevent expansion by your shell. |
| `--immediate`, `-i` | | Also test immediate dependencies. |
| `--recursive`, `-r` | | Also test all dependencies, recursively. |
| `--package-cwd` | | Change the current working directory to the package directory prior to running tests. This may help ported third-party packages since it is not uncommon for tests to expect they are running from the project root directory. |

## Default Options Files

See `bpkg-default-options-files` for an overview of the default options files.
For the `pkg-test` command the search start directory is the configuration
directory. The following options files are searched for in each directory and,
if found, loaded in the order listed:

```
bpkg.options
bpkg-pkg-test.options
```

The following `pkg-test` command options cannot be specified in the default
options files:

```
--directory|-d
```

## See Also

- [bpkg README](README.md)
- [`sanitize-tests`](../HOWTO/sanitize-tests.md) -- sanitizing misbehaving tests with Testscript
- [`assert-in-tests`](../HOWTO/assert-in-tests.md) -- correctly using assert() in tests
- [`tests-extra-dependencies`](../HOWTO/tests-extra-dependencies.md) -- tests with extra dependencies (separate test package)
