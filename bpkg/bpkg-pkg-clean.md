# bpkg-pkg-clean -- clean package

## Synopsis

```
bpkg pkg-clean|clean [<options>] [<vars>] <pkg>...
bpkg pkg-clean|clean [<options>] [<vars>] --all|-a
bpkg pkg-clean|clean [<options>] [<vars>] (--all-pattern <pattern>)...
```

## Description

The `pkg-clean` command cleans the specified packages (the first form), all the
held packages (the second form, see [bpkg-pkg-status](bpkg-pkg-status.md)), or
all the held packages that match any of the specified wildcard patterns (the
third form). Additionally, immediate or all dependencies of these packages can
be also cleaned by specifying the `--immediate|-i` or `--recursive|-r` options,
respectively. Underneath, this command doesn't do much more than run `b clean`.
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
| `--all`, `-a` | | Clean all held packages. |
| `--all-pattern` | _pattern_ | Clean held packages that match the specified wildcard pattern. Repeat this option to match multiple patterns. Note that you may need to quote the pattern to prevent expansion by your shell. |
| `--immediate`, `-i` | | Also clean immediate dependencies. |
| `--recursive`, `-r` | | Also clean all dependencies, recursively. |

## Default Options Files

See `bpkg-default-options-files` for an overview of the default options files.
For the `pkg-clean` command the search start directory is the configuration
directory. The following options files are searched for in each directory and,
if found, loaded in the order listed:

```
bpkg.options
bpkg-pkg-clean.options
```

The following `pkg-clean` command options cannot be specified in the default
options files:

```
--directory|-d
```

## See Also

- [bpkg SUMMARY](SUMMARY.md)
