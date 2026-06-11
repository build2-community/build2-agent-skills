# bpkg-rep-add -- add repository to configuration

## Synopsis

```
bpkg rep-add|add [<options>] <rep-loc>...
```

## Description

The `rep-add` command adds the specified package repositories to the configuration. The repository location _rep-loc_ is a URL or a directory path. If a repository with the same canonical name already exists in the configuration, then its location is replaced with the specified.

Note that this command does not fetch the list of available packages for the newly added repository. For that, use the [bpkg-rep-fetch](bpkg-rep-fetch.md) command, normally, after adding all the repositories you wish to use.

Currently three types of repositories are supported: archive-based `pkg`, directory-based `dir`, and version control-based `git`. See [bpkg-repository-types](bpkg-repository-types.md) for details on their structure and URL format.

Normally the repository type can be automatically guessed by examining its URL (for example, the presence of the `.git` extension) or, in case of a local repository, its content (for example, the presence of the `.git/` subdirectory). Without any identifying information the `pkg` type is assumed unless explicitly specified with the `--type` option or in the URL scheme. Note, however, that the `dir` repository type is never guessed since it is not easily distinguishable from local `pkg` and `git` repositories.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|--------|-----|-------------|
| `--type` | `<type>` | Specify the repository type with valid values being `pkg`, `dir`, and `git`. |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an overview of the default options files. For the `rep-add` command the search start directory is the configuration directory. The following options files are searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-rep-add.options
```

The following `rep-add` command options cannot be specified in the default options files:

```
--directory|-d
```

## See Also

- [bpkg README](README.md)
