# bpkg-pkg-install -- install package

## Synopsis

```
bpkg pkg-install|install [<options>] [<vars>] <pkg>...
bpkg pkg-install|install [<options>] [<vars>] --all|-a
bpkg pkg-install|install [<options>] [<vars>] (--all-pattern <pattern>)...
```

## Description

The `pkg-install` command installs the specified packages (the first form), all
the held packages (the second form, see [bpkg-pkg-status](bpkg-pkg-status.md)),
or all the held packages that match any of the specified wildcard patterns (the
third form). Additionally, immediate or all dependencies of these packages can
be also installed by specifying the `--immediate|-i` or `--recursive|-r`
options, respectively. Underneath, this command doesn't do much more than run
`b install`. In the first form the specified packages must have been previously
configured with [bpkg-pkg-build](bpkg-pkg-build.md) or `bpkg-pkg-configure`.

Additional command line variables (_vars_, normally `config.*`) can be passed to
the build system. Such variables apply to all the specified packages but can
also be specified to only apply to specific packages using the argument grouping
mechanism (see `bpkg-argument-grouping` for details). In particular, this
mechanism can be used to specify the installation directory, for example:

```
bpkg install config.install.root=/usr/local \
             config.install.sudo=sudo       \
             libfoo libbar
```

Alternatively, the installation directory can be specified once when creating
the configuration ([bpkg-cfg-create](bpkg-cfg-create.md)).

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--all`, `-a` | | Install all held packages. |
| `--all-pattern` | _pattern_ | Install held packages that match the specified wildcard pattern. Repeat this option to match multiple patterns. Note that you may need to quote the pattern to prevent expansion by your shell. |
| `--immediate`, `-i` | | Also install immediate dependencies. |
| `--recursive`, `-r` | | Also install all dependencies, recursively. |

## Default Options Files

See `bpkg-default-options-files` for an overview of the default options files.
For the `pkg-install` command the search start directory is the configuration
directory. The following options files are searched for in each directory and,
if found, loaded in the order listed:

```
bpkg.options
bpkg-pkg-install.options
```

The following `pkg-install` command options cannot be specified in the default
options files:

```
--directory|-d
```

## See Also

- [bpkg SUMMARY](SUMMARY.md)
