# bpkg-pkg-purge -- purge package

## Synopsis

```
bpkg pkg-purge [<options>] <pkg>
```

## Description

The `pkg-purge` command removes the package directory and archive from the
filesystem and removes the package from the configuration. Only packages in the
`fetched` and `unpacked` state ([bpkg-pkg-status](bpkg-pkg-status.md)) can be
purged plus `broken` packages if the `--force|-f` option is specified (see the
option's description for details on purging broken packages). If the `--keep|-k`
option is specified, then the package archive is not removed (see the option's
description for details on this mode).

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--keep`, `-k` | | Keep the package archive. Note that in this mode the package is still retained in the configuration's database in the `fetched` state. |
| `--force`, `-f` | | Purge a broken package. In this mode `bpkg` will verify that the package directory and archive no longer exist and then remove the package from the configuration. |

## Default Options Files

See `bpkg-default-options-files` for an overview of the default options files.
For the `pkg-purge` command the search start directory is the configuration
directory. The following options files are searched for in each directory and,
if found, loaded in the order listed:

```
bpkg.options
bpkg-pkg-purge.options
```

The following `pkg-purge` command options cannot be specified in the default
options files:

```
--directory|-d
```

## See Also

- [bpkg README](README.md)
