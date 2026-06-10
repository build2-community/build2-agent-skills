# bpkg-cfg-unlink -- unlink configuration

## Synopsis

```
bpkg cfg-unlink [<options>] [<dir>]
bpkg cfg-unlink [<options>] --dangling
```

## Description

The `cfg-unlink` command unlinks the specified `bpkg` configuration from the
current configuration (the first form) or removes dangling implicit backlinks
(the second form). See [bpkg-cfg-create](bpkg-cfg-create.md) for background
on linked configurations.

In the first form the configuration to unlink can be specified either as a
configuration directory (`<dir>`), name (`--name`), id (`--id`), or UUID
(`--uuid`).

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|--------|-----|-------------|
| `--name` | `<name>` | Name of the configuration to unlink. |
| `--id` | `<id>` | Numeric id of the configuration to unlink. |
| `--uuid` | `<uuid>` | UUID of the configuration to unlink. |
| `--dangling` | | Remove dangling implicit backlinks. |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an
overview of the default options files. For the `cfg-unlink` command the
search start directory is the configuration directory. The following options
files are searched for in each directory and, if found, loaded in the order
listed:

```
bpkg.options
bpkg-cfg-unlink.options
```

The following `cfg-unlink` command options cannot be specified in the default
options files:

```
--directory|-d
```

## See Also

- [bpkg SUMMARY](SUMMARY.md)
- [bpkg-cfg-create](bpkg-cfg-create.md)
- [bpkg-cfg-info](bpkg-cfg-info.md)
- [bpkg-cfg-link](bpkg-cfg-link.md)
