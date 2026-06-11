# bpkg-pkg-fetch -- fetch package archive

## Synopsis

```
bpkg pkg-fetch [<options>] (<pkg>/<ver> | --existing|-e <file>)
```

## Description

The `pkg-fetch` command fetches the archive for the specified package name and version from one of the archive-based repositories ([bpkg-rep-add](bpkg-rep-add.md)). The resulting package state is `fetched` ([bpkg-pkg-status](bpkg-pkg-status.md)).

If the `--replace|-r` option is specified, then `pkg-fetch` will replace the archive of a package that is already in the `fetched` or `unpacked` state. Otherwise, `pkg-fetch` expects the package to not exist in the configuration.

If the `--existing|-e` option is used, then instead of the name and version arguments, `pkg-fetch` expects a local path to an existing package archive. In this case, `bpkg` will use the archive in place, without copying it into the configuration directory. Also, unless the `--purge|-p` option is specified, `bpkg` will not attempt to remove this archive when the package is later purged with the [bpkg-pkg-purge](bpkg-pkg-purge.md) command.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--replace`, `-r` | | Replace the archive if the package is already fetched or unpacked. |
| `--existing`, `-e` | | Treat the argument as an existing package archive path rather than the package name/version to fetch. |
| `--purge`, `-p` | | Remove the existing package archive when the package is purged. |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an overview of the default options files. For the `pkg-fetch` command the search start directory is the configuration directory. The following options files are searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-pkg-fetch.options
```

The following `pkg-fetch` command options cannot be specified in the default options files:

```
--directory|-d
--purge|-p
```

## See Also

- [bpkg README](README.md)
