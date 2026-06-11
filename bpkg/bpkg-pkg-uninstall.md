# bpkg-pkg-uninstall -- uninstall package

## Synopsis

```
bpkg pkg-uninstall|uninstall [<options>] [<vars>] <pkg>...
bpkg pkg-uninstall|uninstall [<options>] [<vars>] --all|-a
bpkg pkg-uninstall|uninstall [<options>] [<vars>] (--all-pattern <pattern>)...
```

## Description

The `pkg-uninstall` command uninstalls the specified packages (the first form),
all the held packages (the second form, see
[bpkg-pkg-status](bpkg-pkg-status.md)), or all the held packages that match any
of the specified wildcard patterns (the third form). Additionally, immediate or
all dependencies of these specified packages can be also uninstalled by
specifying the `--immediate|-i` or `--recursive|-r` options, respectively.
Underneath, this command doesn't do much more than run `b uninstall`. In the
first form the specified packages must have been previously configured with
[bpkg-pkg-build](bpkg-pkg-build.md) or `bpkg-pkg-configure`.

Additional command line variables (_vars_, normally `config.*`) can be passed to
the build system. Such variables apply to all the specified packages but can
also be specified to only apply to specific packages using the argument grouping
mechanism (see `bpkg-argument-grouping` for details). See
[bpkg-pkg-install](bpkg-pkg-install.md) for some examples.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--all`, `-a` | | Uninstall all held packages. |
| `--all-pattern` | _pattern_ | Uninstall held packages that match the specified wildcard pattern. Repeat this option to match multiple patterns. Note that you may need to quote the pattern to prevent expansion by your shell. |
| `--immediate`, `-i` | | Also uninstall immediate dependencies. |
| `--recursive`, `-r` | | Also uninstall all dependencies, recursively. |

## Default Options Files

See `bpkg-default-options-files` for an overview of the default options files.
For the `pkg-uninstall` command the search start directory is the configuration
directory. The following options files are searched for in each directory and,
if found, loaded in the order listed:

```
bpkg.options
bpkg-pkg-uninstall.options
```

The following `pkg-uninstall` command options cannot be specified in the default
options files:

```
--directory|-d
```

## See Also

- [bpkg README](README.md)
