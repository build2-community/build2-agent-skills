# bpkg-rep-list -- list repositories in configuration

## Synopsis

```
bpkg rep-list|list [<options>]
```

## Description

The `rep-list` command lists the repositories in the configuration.

For each repository a line containing the repository name and location is printed to `stdout`. If the `--complements|-c` and/or `--prerequisites|-p` options are specified, then it is followed by the list of complement and/or prerequisite repositories, recursively.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|--------|-----|-------------|
| `--complements`, `-c` | | List complement repositories. |
| `--prerequisites`, `-p` | | List prerequisite repositories. |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an overview of the default options files. For the `rep-list` command the search start directory is the configuration directory. The following options files are searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-rep-list.options
```

The following `rep-list` command options cannot be specified in the default options files:

```
--directory|-d
```

## See Also

- [bpkg README](README.md)
