# bdep-update -- update project in build configurations

## Synopsis

```
bdep update [<options>] [<pkg-spec>] [<cfg-spec>] [<cfg-var>...]
```

```
<cfg-spec> = (@<cfg-name> | --config|-c <cfg-dir>)... | --all|-a
<pkg-spec> = (<pkg> | (--directory|-d <pkg-dir>))... | <prj-spec>
<prj-spec> = --directory|-d <prj-dir>
```

## Description

The `update` command updates the project packages in one or more build
configurations. Additionally, immediate or all dependencies of the project
packages can be updated by specifying the `--immediate|-i` or `--recursive|-r`
options, respectively.

Underneath `update` executes the `bpkg-pkg-update` command which itself is not
much more than the build system `update` operation (see `b` for details). As a
result, the main utility of this command is the ability to refer to build
configurations by names and to project packages implicitly via the current
working directory as well as to update dependencies.

If no project or package directory is specified, then the current working
directory is assumed. If no configuration is specified, then the default
configurations are assumed. See [bdep-projects-configs](bdep-projects-configs.md)
for details on specifying projects and configurations. Optional `<cfg-var>...`
are the additional configuration variables to pass to the build system.

## Options

Note: also see [common options](bdep-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--immediate`, `-i` | | Also update immediate dependencies. |
| `--recursive`, `-r` | | Also update all dependencies, recursively. |

## Default Options Files

See [bdep-default-options-files](bdep-default-options-files.md) for an
overview of the default options files. For the `update` command the search
start directory is the project directory. The following options files are
searched for in each directory and, if found, loaded in the order listed:

```
bdep.options
bdep-update.options
```

The following `update` command options cannot be specified in the default
options files:

```
--directory|-d
```

## See Also

- [bdep README](README.md)
- [bdep-projects-configs](bdep-projects-configs.md)
- [bdep-default-options-files](bdep-default-options-files.md)
