# bdep-config -- manage project build configurations

## Synopsis

```
bdep config add    [<options>] [<prj-spec>] [@<cfg-name>] <cfg-dir>
bdep config create [<options>] [<prj-spec>] [@<cfg-name>] <cfg-dir> [<cfg-args>]
bdep config link   [<options>] [<prj-spec>] <cfg-spec> <cfg-spec>
bdep config unlink [<options>] [<prj-spec>] <cfg-spec> <cfg-spec>
bdep config list   [<options>] [<prj-spec>] [<cfg-spec>...]
bdep config move   [<options>] [<prj-spec>] <cfg-spec> <cfg-dir>
bdep config rename [<options>] [<prj-spec>] <cfg-spec> <cfg-name>
bdep config remove [<options>] [<prj-spec>] <cfg-spec>... | --all|-a
bdep config set    [<options>] [<prj-spec>] <cfg-spec>... | --all|-a
                               [--[no-]default]
                               [--[no-]forward]
                               [--[no-]auto-sync]

<cfg-spec> = @<cfg-name> | --config|-c <cfg-dir>
<prj-spec> = --directory|-d <prj-dir>
<cfg-args> = [-- [<bpkg-options>]] [--existing|-e | (<module> | <cfg-var>)...]
```

## Description

The `config` command provides the following subcommands for managing project's
build configurations. If no project directory is specified, then the current
working directory is assumed.

## Options

Note: also see [common options](bdep-common-options.md).

### add and create

The `add` subcommand adds an existing [bpkg(1)](../bpkg/bpkg.md) build
configuration in directory _cfg-dir_ to the project's build configuration set.
The `create` subcommand creates a new configuration in directory _cfg-dir_ by
executing the [bpkg-cfg-create(1)](../bpkg/bpkg-cfg-create.md) command and
passing to it _cfg-args_, if any. It then proceeds as `add` by adding the new
configuration to the project's build configuration set.

In both subcommands, if _cfg-name_ is specified, then the added configuration
is given this name. Several `bdep` commands can use such names as a more
convenient way to specify build configurations (see
[bdep-projects-configs(1)](bdep-projects-configs.md) for details).

As a shortcut, if _cfg-name_ is not specified and _cfg-dir_ is a simple path
that starts with `@`, then it is treated as the name and the configuration
directory is assumed to be _prj-dir_**-**_cfg-name_. Note that in case of
`create`, _cfg-dir_ must be preceded with `--` (double dash) to disambiguate
it from `@`_cfg-name_. For example, assuming the project directory is `hello`:

```
$ bdep config add @clang                         # ../hello-clang
$ bdep config create -- @gcc cc config.cxx=g++   # ../hello-gcc
```

A configuration also has a type that is specified with the `--type` option (or
`--config-type` from [bdep-new(1)](bdep-new.md)). If the type is not specified
explicitly, then `target` is assumed. See
[bpkg-cfg-create(1)](../bpkg/bpkg-cfg-create.md) for background on
configuration types.

Unless the `--no-default` option is specified, the first added or created build
configuration of each type is designated as the default. Several `bdep`
commands use such a configuration by default if no configuration was specified
explicitly (see [bdep-projects-configs(1)](bdep-projects-configs.md) for
details). To make a subsequently added configuration the default use the
`--default` option. Note also that in case of multiple default configurations
any given package within a project can only be initialized in one such
configuration.

The default build configuration of each type is also designated as forwarded
unless the `--no-forward` option is specified or another configuration of this
type is already designated as forwarded. When a project is initialized in a
forwarded build configuration, its source directory is configured to forward to
this configuration (see [b(1)](../b/b.md) for details on forwarded
configurations). To designate a non-default configuration as forwarded use the
`--forward` option. Note also that it is possible to have multiple forwarded
configurations, however, any given package within a project can only be
initialized in one such configuration.

Unless the `--no-auto-sync` option is specified, an added or created build
configuration will be automatically synchronized on every build system
invocation. Note that this flag affects the entire build configuration and if
multiple projects share the same configuration, then they must have a
consistent auto-synchronization setting.

| Option | Arg | Description |
|--------|-----|-------------|
| `--type`, `--config-type` | `<typ>` | The type of the configuration being created. By default, configuration of type `target` is created. See [bpkg-cfg-create(1)](../bpkg/bpkg-cfg-create.md) for background on configuration types. |
| `--default` | | Make the added or created configuration the default. |
| `--no-default` | | Don't make the first added or created configuration the default. |
| `--forward` | | Make the added or created configuration forwarded. |
| `--no-forward` | | Don't make the added or created configuration forwarded. |
| `--auto-sync` | | Make the added or created configuration automatically synchronized. |
| `--no-auto-sync` | | Don't make the added or created configuration automatically synchronized. |
| `--existing`, `-e` | | Initialize a `bpkg` configuration based on an existing build system configuration. |
| `--wipe` | | Wipe the configuration directory clean before creating the new configuration. |

### link

The `link` subcommand links the first specified build configuration with the
second by executing the [bpkg-cfg-link(1)](../bpkg/bpkg-cfg-link.md) command.
See [bpkg-cfg-create(1)](../bpkg/bpkg-cfg-create.md) for background on linked
configurations.

### unlink

The `unlink` subcommand unlinks the first specified build configuration from
the second by executing the
[bpkg-cfg-unlink(1)](../bpkg/bpkg-cfg-unlink.md) command. See
[bpkg-cfg-create(1)](../bpkg/bpkg-cfg-create.md) for background on linked
configurations.

### list

The `list` subcommand prints the list of build configurations associated with
the project. Unless one or more configurations are specified explicitly, `list`
prints all the associated configurations. Note that the output is written to
`stdout`, not `stderr`.

If the output format is `json` (see the `--stdout-format` common option), then
the output is a JSON array of objects which are the serialized representation
of the following structure:

```
struct package
{
  string name;
};

struct configuration
{
  uint64_t         id;
  string           path;
  optional<string> name;
  string           type;
  bool             default;
  bool             forward;
  bool             auto_sync;
  vector<package>  packages;
};
```

For example:

```json
[
  {
    "id": 1,
    "path": "/tmp/hello-gcc",
    "name": "gcc",
    "type": "target",
    "default": true,
    "forward": true,
    "auto_sync": true,
    "packages": [
      {
        "name": "hello"
      }
    ]
  }
]
```

The `id` member is a numeric configuration id that can be used to identify the
configuration instead of the name or path (see the `--config-id` option). The
`path` member is an absolute path to the configuration directory. The
`packages` member contains the array of packages belonging to this project that
have been initialized in this configuration. See the `create` subcommand for
the meaning of other members (`name`, `type`, `default`, etc).

### move

The `move` subcommand assigns the specified build configuration a new
directory. It is normally used after moving/renaming the configuration
directory. Note that an explicit [bdep-sync(1)](bdep-sync.md) command is
required for this change to take effect. See
[bdep-projects-configs(1)](bdep-projects-configs.md) for various ways to
specify a build configuration.

### rename

The `rename` subcommand gives the specified build configuration a new name. See
[bdep-projects-configs(1)](bdep-projects-configs.md) for various ways to
specify a build configuration.

### remove

The `remove` subcommand removes one or more build configurations from the
project's build configuration set. Note that only configurations that have no
initialized packages can be removed. See
[bdep-projects-configs(1)](bdep-projects-configs.md) for various ways to
specify build configurations.

### set

The `set` subcommand modifies various properties of one or more build
configurations associated with the project. See
[bdep-projects-configs(1)](bdep-projects-configs.md) for various ways to
specify build configurations.

The properties that can be modified include the default (`--[no-]default`),
forward (`--[no-]forward`), and auto-synchronization (`--[no-]auto-sync`)
flags. Note that changing any of these flags requires an explicit
[bdep-sync(1)](bdep-sync.md) command to take effect.

| Option | Arg | Description |
|--------|-----|-------------|
| `--default` | | Make the configuration the default. |
| `--no-default` | | Remove the default designation from the configuration. |
| `--forward` | | Make the configuration forwarded. |
| `--no-forward` | | Remove the forwarded designation from the configuration. |
| `--auto-sync` | | Enable automatic synchronization for the configuration. |
| `--no-auto-sync` | | Disable automatic synchronization for the configuration. |

### Common specifier options

These options are available across subcommands for specifying the project and
configurations.

| Option | Arg | Description |
|--------|-----|-------------|
| `--config`, `-c` | `<dir>` | Specify the build configuration as a directory. |
| `--config-name`, `-n` | `<name>` | Specify the build configuration as a name. |
| `--config-id` | `<num>` | Specify the build configuration as an id. |
| `--all`, `-a` | | Use all build configurations. |
| `--directory`, `-d` | `<dir>` | Assume project is in the specified directory rather than in the current working directory. |

## Default Options Files

See [bdep-default-options-files(1)](bdep-default-options-files.md) for an
overview of the default options files. For the `config` command the search
start directory is the project directory. The following options files are
searched for in each directory and, if found, loaded in the order listed:

```
bdep.options
bdep-config.options
bdep-config-add.options           # if the create subcommand
bdep-config-<subcommand>.options  # (subcommand-dependent)
```

The following `config` command options cannot be specified in the default
options files:

```
--directory|-d
--wipe
```

## See Also

- [bdep README](README.md)
- [`multiple-configurations`](../HOWTO/multiple-configurations.md) -- managing debug/release/sanitize configurations with bdep config
