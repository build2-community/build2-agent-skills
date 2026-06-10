# bpkg-rep-fetch -- fetch list of available packages

## Synopsis

```
bpkg rep-fetch|fetch [<options>] [(<rep-name> | <rep-loc>)...]
```

## Description

The `rep-fetch` command fetches the list of available packages for the specified repositories as well as all their complement and prerequisite repositories, recursively. If no repositories were specified, then all the repositories previously added ([bpkg-rep-add](bpkg-rep-add.md)) to the configuration are fetched.

The repository to fetch can be specified either as a repository name or as a repository location (URL or a directory path, see [bpkg-rep-add](bpkg-rep-add.md) for details). In the latter case, the repository location is added/replaced as if by first executing the `rep-add` command.

Note that fetching only a specific repository that happens to be a prerequisite or complement of another repository not being fetched may result in an inconsistent repository state.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|--------|-----|-------------|
| `--shallow` | | Do not re-fetch complement and prerequisite repositories of the specified repositories unless the set of complements and/or prerequisites has changed. |
| `--no-dir-progress` | | Do not print progress for the specified directory-based repositories. |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an overview of the default options files. For the `rep-fetch` command the search start directory is the configuration directory. The following options files are searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-rep-fetch.options
```

The following `rep-fetch` command options cannot be specified in the default options files:

```
--directory|-d
```

## See Also

- [bpkg SUMMARY](SUMMARY.md)
