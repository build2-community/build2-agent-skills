# bpkg-rep-remove -- remove repository from configuration

## Synopsis

```
bpkg rep-remove|remove [<options>] (<rep-name>|<rep-loc>)...
bpkg rep-remove|remove [<options>] --all|-a
bpkg rep-remove|remove [<options>] --clean
```

## Description

The `rep-remove` command removes the specified package repositories from the configuration. The repository to remove can be specified either as a repository name or as a repository location (URL or a directory path).

Alternatively, the `--all|-a` option can be used to remove all the repositories that were previously added ([bpkg-rep-add](bpkg-rep-add.md)) to the configuration.

Finally, the `--clean` option can be used to revert the repositories to the clean state, as if they were added but never fetched.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|--------|-----|-------------|
| `--all`, `-a` | | Remove all the repositories. |
| `--clean` | | Clean the repository state. |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an overview of the default options files. For the `rep-remove` command the search start directory is the configuration directory. The following options files are searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-rep-remove.options
```

The following `rep-remove` command options cannot be specified in the default options files:

```
--directory|-d
```

## See Also

- [bpkg README](README.md)
