# bpkg-pkg-unpack -- unpack package archive

## Synopsis

```
bpkg pkg-unpack [<options>] (<pkg>[/<ver>] | --existing|-e <dir>)
```

## Description

If only the package name is specified, then the `pkg-unpack` command unpacks the archive for the previously fetched ([bpkg-pkg-fetch](bpkg-pkg-fetch.md)) package. The resulting package state is `unpacked` ([bpkg-pkg-status](bpkg-pkg-status.md)).

If the package version is also specified, then the (source) directory from one of the directory-based repositories ([bpkg-rep-add](bpkg-rep-add.md)) is used in place, without copying it into the configuration directory. Such a package is called _external_.

If the `--existing|-e` option is used, then instead of the package name, `pkg-unpack` expects a local path to an existing package directory. In this case, `bpkg` will use the (source) directory in place, the same as for packages from directory-based repositories. Also, unless the `--purge|-p` option is specified, `bpkg` will not attempt to remove this directory when the package is later purged with the [bpkg-pkg-purge](bpkg-pkg-purge.md) command. Such a package is also _external_.

If `--existing|-e` is specified together with the `--replace|-r` option, then `pkg-unpack` will replace the archive and/or source directory of a package that is already in the `unpacked` or `fetched` state.

An external package triggers several changes in semantics compared to a normal package. The package (output) directory inside the configuration is called just _pkg_ rather than _pkg_**-**_ver_. It is also assumed that the packaging information (package manifest and lockfile) for such packages may change without incrementing the package version (for example, during development). To support this, `bpkg` implements the _package iteration_ mechanism which may result in iteration numbers to be shown as part of the package version, for example, `1.2.3#1`.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--existing`, `-e` | | Treat the argument as an existing package directory path rather than the package name to unpack. |
| `--purge`, `-p` | | Remove the existing package directory when the package is purged. |
| `--replace`, `-r` | | Replace the source directory if the package is already unpacked or fetched. Can only be specified with an external package. |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an overview of the default options files. For the `pkg-unpack` command the search start directory is the configuration directory. The following options files are searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-pkg-unpack.options
```

The following `pkg-unpack` command options cannot be specified in the default options files:

```
--directory|-d
--purge|-p
```

## See Also

- [bpkg README](README.md)
