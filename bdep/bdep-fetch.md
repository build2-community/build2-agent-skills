# bdep-fetch -- fetch list of available project dependencies

## Synopsis

```
bdep fetch [<options>] [--full|-F] [<prj-spec>] [<cfg-spec>]
```

```
<cfg-spec> = (@<cfg-name> | --config|-c <cfg-dir>)... | --all|-a
<prj-spec> = --directory|-d <prj-dir>
```

## Description

The `fetch` command fetches the list of packages available in the project's
prerequisite/complement repositories in one or more build configurations.

If no project or package directory is specified, then the current working
directory is assumed. If no configuration is specified, then the default
configurations are assumed. See [bdep-projects-configs](bdep-projects-configs.md)
for details on specifying projects and configurations.

If the `--full|-F` option is specified, then instead `fetch` performs a full
re-fetch of all the repositories added to the configuration. This mode is
primarily useful when a configuration (and some of the
prerequisite/complement repositories) are shared between several projects. In
this situation an incremental fetch may result in an inconsistent repository
state.

## Options

Note: also see [common options](bdep-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--full`, `-F` | | Perform a full re-fetch of all the repositories. |

## Default Options Files

See [bdep-default-options-files](bdep-default-options-files.md) for an
overview of the default options files. For the `fetch` command the search
start directory is the project directory. The following options files are
searched for in each directory and, if found, loaded in the order listed:

```
bdep.options
bdep-fetch.options
```

The following `fetch` command options cannot be specified in the default
options files:

```
--directory|-d
```

## See Also

- [bdep SUMMARY](SUMMARY.md)
- [bdep-projects-configs](bdep-projects-configs.md)
- [bdep-default-options-files](bdep-default-options-files.md)
