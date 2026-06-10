# bpkg-pkg-checkout -- check out package version

## Synopsis

```
bpkg pkg-checkout [<options>] <pkg>/<ver>
```

## Description

The `pkg-checkout` command checks out the specified package version from one of the version control-based repositories ([bpkg-rep-add](bpkg-rep-add.md)). The resulting package state is `unpacked` ([bpkg-pkg-status](bpkg-pkg-status.md)).

If the `--output-root` option is passed, then the package is checked out into the specified directory rather than into the configuration directory. In this case, `bpkg` uses the package (source) directory in place, similar to the `pkg-unpack --existing|-e` mode. Also, unless the `--output-purge` option is specified, `bpkg` will not attempt to remove this directory when the package is later purged with the [bpkg-pkg-purge](bpkg-pkg-purge.md) command. Note also that such a package is not _external_ (see [bpkg-pkg-unpack](bpkg-pkg-unpack.md) for details).

If the `--replace|-r` option is specified, then `pkg-checkout` will replace the archive and/or source directory of a package that is already in the `unpacked` or `fetched` state.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--replace`, `-r` | | Replace the source directory if the package is already fetched or unpacked. |
| `--output-root` | `<dir>` | Check out the package into the specified directory rather than into the configuration directory. Note that the package source is placed into the _package_**-**_version_ subdirectory of this directory. |
| `--output-purge` | | Remove the checked out package (source) directory when the package is purged. |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an overview of the default options files. For the `pkg-checkout` command the search start directory is the configuration directory. The following options files are searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-pkg-checkout.options
```

The following `pkg-checkout` command options cannot be specified in the default options files:

```
--directory|-d
```

## See Also

- [bpkg SUMMARY](SUMMARY.md)
