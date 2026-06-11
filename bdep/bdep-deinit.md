# bdep-deinit -- deinitialize project in build configurations

## Synopsis

```
bdep deinit [<options>] [<pkg-spec>] [<cfg-spec>]
```

```
<cfg-spec> = (@<cfg-name> | --config|-c <cfg-dir>)... | --all|-a
<pkg-spec> = (<pkg> | (--directory|-d <pkg-dir>))... | <prj-spec>
<prj-spec> = --directory|-d <prj-dir>
```

## Description

The `deinit` command deinitializes the specified project packages
(`<pkg-spec>`), or, if the project itself is specified (`<prj-spec>`), all its
previously initialized packages, in one or more build configurations
(`<cfg-spec>`).

If no project directory is specified, then the current working directory is
assumed. If no configuration is specified, then the default configurations are
assumed. See [bdep-projects-configs](bdep-projects-configs.md) for details on
specifying projects and configurations.

## Options

Note: also see [common options](bdep-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--force` | | Deinitialize packages without attempting to remove them from the build configuration. This mode is primarily useful when the configuration directory has been removed or is otherwise unusable. |
| `--no-fetch` | | Do not re-fetch the repository information before attempting to replace packages being deinitialized with versions from repositories. |

## Default Options Files

See [bdep-default-options-files](bdep-default-options-files.md) for an
overview of the default options files. For the `deinit` command the search
start directory is the project directory. The following options files are
searched for in each directory and, if found, loaded in the order listed:

```
bdep.options
bdep-deinit.options
```

The following `deinit` command options cannot be specified in the default
options files:

```
--directory|-d
```

## See Also

- [bdep README](README.md)
- [bdep-init](bdep-init.md)
- [bdep-projects-configs](bdep-projects-configs.md)
- [bdep-default-options-files](bdep-default-options-files.md)
