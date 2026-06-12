# bpkg-cfg-create -- create bpkg configuration

## Synopsis

```
bpkg cfg-create|create [<options>] [<cfg-args>]
bpkg cfg-create|create [<options>] --existing|-e
```

```
<cfg-args> = (<module> | <cfg-var>)...
```

## Description

The `cfg-create` command creates a new `bpkg` configuration with the specified
`build2` modules and configuration variables (the first form) or initializes
one based on an existing build system configuration (the second form). The
`bpkg` configuration itself is a build system configuration. See the build
system driver (`b(1)`) `create` meta-operation for details.

Unless the `--existing|-e` or `--wipe` option is specified, `cfg-create`
expects the configuration directory to be empty or to not exist (in which case
it will be created).

By default, the configuration created with the first form loads the `config`,
`test`, `dist`, and `install` modules. However, additional modules and, if
required, their configuration variables can be specified as the `cfg-create`
arguments. For example:

```
bpkg create cxx config.cxx=clang++ config.install.root=/usr/local
```

By default, `bpkg` appends `.config` to the names of the modules that you
specify so that only their configurations are loaded. You can override this
behavior by specifying the period (`.`) after the module name. You can also
instruct `bpkg` to use the optional module load by prefixing the module name
with the question mark (`?`). For example:

```
bpkg create cxx. "?cli"
```

Configurations can be linked with each other to allow a package to be built in
one configuration while its dependencies reside in one or more linked
configurations. This can be used to create a "base" configuration with common
dependencies that are shared between multiple configurations. This mechanism is
also used to provide a host configuration that is used to build build-time
dependencies.

Each configuration is assigned an automatically-generated UUID unless one is
specified with the `--uuid` option. This UUID is used to check the integrity of
configuration links. For convenience of referring to linked configurations, a
configuration can also be assigned a name with the `--name` option.

A configuration also has a type specified with the `--type` option. Three
predefined types are `target`, `host`, and `build2`. If the type is not
specified explicitly, then `target` is assumed. When satisfying a dependency of
one package on another, a linked configuration will only be considered if (1)
it has the same type as the other configuration for run-time dependencies, (2)
it has the `host` type for regular build-time dependencies, and (3) it has the
`build2` type for build system module build-time dependencies. Note that a host
configuration is a target configuration for the host machine. So to create a
self-hosted configuration, use type `host`.

To link a configuration use the [bpkg-cfg-link](bpkg-cfg-link.md) command. As
a shortcut, host and build system module configurations can also be linked
during configuration creation with the `--host-config` and `--build2-config`
options, respectively. If a build-time dependency is encountered in a
configuration that has no linked configuration of a suitable type (`host` or
`build2`, nor is itself of a suitable type), then a private host or build
system module configuration named `host` or `build2`, respectively, is created
automatically inside the configuration's `.bpkg/` subdirectory.

## Options

See [common options](bpkg-common-options.md) for options common to all
commands.

| Option | Arg | Description |
|--------|-----|-------------|
| `--directory`, `-d` | `<dir>` | Create the configuration in `<dir>` rather than in the current working directory. |
| `--existing`, `-e` | | Initialize a `bpkg` configuration based on an existing build system configuration. |
| `--wipe` | | Wipe the configuration directory clean before creating the new configuration. For safety, this option requires that you specify the configuration directory explicitly with `--directory|-d`. |
| `--host-config` | `<dir>` | Link the specified host configuration with the configuration being created as if by running the [bpkg-cfg-link](bpkg-cfg-link.md) command. |
| `--no-host-config` | | Ignore any specified `--host-config` options. |
| `--build2-config` | `<dir>` | Link the specified build system module configuration with the configuration being created as if by running the [bpkg-cfg-link](bpkg-cfg-link.md) command. |
| `--no-build2-config` | | Ignore any specified `--build2-config` options. |
| `--name` | `<name>` | The name of the configuration being created. If this configuration is linked with another configuration using [bpkg-cfg-link](bpkg-cfg-link.md), this name will be used as the link name unless overridden. By default the configuration is created unnamed. |
| `--type` | `<type>` | The type of the configuration being created. By default, a configuration of type `target` is created. |
| `--uuid` | `<uuid>` | Use the specified UUID as the configuration id instead of generating one automatically. |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an
overview of the default options files. For the `cfg-create` command the search
start directory is the parent directory of the new configuration. The following
options files are searched for in each directory and, if found, loaded in the
order listed:

```
bpkg.options
bpkg-cfg-create.options
```

The following `cfg-create` command options cannot be specified in the default
options files:

```
--directory|-d
--wipe
```

## See Also

- [bpkg README](README.md)
- [bpkg-cfg-link](bpkg-cfg-link.md)
- [bpkg-cfg-info](bpkg-cfg-info.md)
- [`multiple-configurations`](../HOWTO/multiple-configurations.md) -- managing debug/release/sanitize configurations
- [`cross-compilation`](../HOWTO/cross-compilation.md) -- setting up a cross-compilation configuration with target triplets
