# bdep-status -- print status of project and/or its dependencies

## Synopsis

```
bdep status [<options>] [<pkg-spec>] [<cfg-spec>] [<dep-spec>...]
```

```
<dep-spec> = <pkg>[/<ver>]
<cfg-spec> = (@<cfg-name> | --config|-c <cfg-dir>)... | --all|-a
<pkg-spec> = (<pkg> | (--directory|-d <pkg-dir>))... | <prj-spec>
<prj-spec> = --directory|-d <prj-dir>
```

## Description

The `status` command prints the status of project packages and/or their
dependencies in one or more build configurations.

If no project or package directory is specified, then the current working
directory is assumed. If no configuration is specified, then the default
configurations are assumed. See [bdep-projects-configs](bdep-projects-configs.md)
for details on specifying projects and configurations.

Note that if a package that is specified as a `<pkg>` name (as opposed to as
a directory with `--directory|-d`) belongs to the project and is initialized
in any of the specified configurations, then it is interpreted as `<pkg-spec>`.
Otherwise, it is interpreted as `<dep-spec>`.

If no `<dep-spec>` arguments are specified, then `status` prints the status
of the project's packages. Otherwise, the status of the specified dependency
packages is printed. Additionally, the status of immediate or all dependencies
of the above packages can be printed by specifying the `--immediate|-i` or
`--recursive|-r` options, respectively.

In the default output format (see the `--stdout-format` common option), the
status of each package is printed on a separate line. Note that the status is
written to `stdout`, not `stderr`. The semantics of `<dep-spec>` and the
format of the status line are described in `bpkg-pkg-status`.

If the output format is `json`, then the output is a JSON array of objects
representing configuration and package status. Each element has a
`configuration` object (with `id`, `path`, and optional `name` fields) and a
`packages` array of package status objects as defined by `bpkg-pkg-status`.

For example:

```json
[
  {
    "configuration": {
      "id": 1,
      "path": "/tmp/hello-gcc",
      "name": "gcc"
    },
    "packages": [
      {
        "name": "hello",
        "status": "configured",
        "version": "1.0.0",
        "hold_package": true,
        "available_versions": [
          { "version": "1.0.1" },
          { "version": "2.0.0" }
        ],
        "dependencies": [
          {
            "name": "libhello",
            "status": "configured",
            "version": "1.0.2"
          }
        ]
      }
    ]
  }
]
```

See the JSON OUTPUT section in [bdep-common-options](bdep-common-options.md)
for details on the overall properties of this format. Refer to the `list`
subcommand of `bdep-config` for details on the `configuration` members. Refer
to `bpkg-pkg-status` for the definition of the package status members. Note
also that in the `json` output format certain conditions (no associated
configurations, no initialized packages, etc.) are not treated as errors but
instead result in valid output. Uninitialized packages have the special
`uninitialized` status value.

## Options

Note: also see [common options](bdep-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--immediate`, `-i` | | Also print the status of immediate dependencies. |
| `--recursive`, `-r` | | Also print the status of all dependencies, recursively. |
| `--old-available`, `-o` | | Print old available versions. |
| `--fetch`, `-f` | | Perform the `fetch` command prior to printing the status. |
| `--fetch-full`, `-F` | | Perform the `fetch --full` command prior to printing the status. |

## Default Options Files

See [bdep-default-options-files](bdep-default-options-files.md) for an
overview of the default options files. For the `status` command the search
start directory is the project directory. The following options files are
searched for in each directory and, if found, loaded in the order listed:

```
bdep.options
bdep-status.options
```

The following `status` command options cannot be specified in the default
options files:

```
--directory|-d
```

## See Also

- [bdep SUMMARY](SUMMARY.md)
- [bdep-fetch](bdep-fetch.md)
- [bdep-projects-configs](bdep-projects-configs.md)
- [bdep-default-options-files](bdep-default-options-files.md)
