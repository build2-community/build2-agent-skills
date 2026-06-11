# bdep-sync -- synchronize project and build configurations

## Synopsis

```
bdep sync [<options>] [<pkg-spec>] [<cfg-spec>] [<pkg-args>]
bdep sync [<options>] [<pkg-spec>] [<cfg-spec>]  --upgrade|-u | --patch|-p
bdep sync [<options>] [<pkg-spec>] [<cfg-spec>] [--upgrade|-u | --patch|-p]
          <dep-spec>... [<cfg-var>...]
```

```
<dep-spec> = <pkg>[/<ver>]
<cfg-spec> = (@<cfg-name> | --config|-c <cfg-dir>)... | --all|-a
<pkg-spec> = (<pkg> | (--directory|-d <pkg-dir>))... | <prj-spec>
<prj-spec> = --directory|-d <prj-dir>
<pkg-args> = (?<pkg> | <cfg-var>)...
```

## Description

The `sync` command synchronizes a project with its build configurations.

The first form (no `--upgrade` or `--patch` and only `<pkg-args>` arguments,
if any, are specified) upgrades the project packages to the latest
version/iteration, adjusts their dependencies according to the latest manifest
information, and updates the lockfile.

If no project or package directory is specified, then the current working
directory is assumed. If no configuration is specified, then the default
configurations are assumed. See [bdep-projects-configs](bdep-projects-configs.md)
for details on specifying projects and configurations. Optional `<pkg-args>`
are the additional dependency packages and/or configuration variables to pass
to the underlying `bpkg-pkg-build` command.

The second form (no arguments but either `--upgrade` or `--patch` is
specified), in addition to the first form's functionality, also upgrades or
patches immediate (by default or if `--immediate|-i` is specified) or all (if
`--recursive|-r` is specified) dependencies of the specified project packages.
If no project packages are specified explicitly, then this form upgrades or
patches dependencies of all the initialized packages in a project.

The third form (one or more `<dep-spec>` arguments are specified), in addition
to the first form's functionality, also upgrades (by default or if `--upgrade`
is specified) or patches (if `--patch` is specified) the specified
dependencies. If `--immediate|-i` or `--recursive|-r` is specified, then it
also upgrades or patches the immediate or all dependencies of the specified
dependencies, respectively. Alternative to `--upgrade` and `--patch`, the
desired upgrade (or downgrade) version can be specified explicitly.

Note that if a package that is specified as a `<pkg>` name (as opposed to as a
directory with `--directory|-d`) belongs to the project and is initialized in
any of the specified configurations, then it is interpreted as `<pkg-spec>` of
the first or second form. Otherwise, it is interpreted as `<dep-spec>` of the
third form of the command line.

Note also that `--immediate|-i` or `--recursive|-r` can only be specified with
an explicit `--upgrade` or `--patch`.

Configuration variables can be specified to only apply to specific packages in
`<pkg-args>` and `<dep-spec>` using the argument grouping mechanism (see
[bdep-argument-grouping](bdep-argument-grouping.md)). Additionally, packages
in `<pkg-args>` can be placed into specific linked configurations by specifying
the configuration with one of the `--config*` options (or `@` notation) using
the same grouping mechanism.

If during synchronization a build-time dependency is encountered and there is
no build configuration of a suitable type associated with the project, then the
user is prompted (unless the respective `--create-*-config` option is
specified) to automatically create such a configuration and associate it with
the project. See `bpkg-cfg-create` for background on configuration types.

## Examples

Consider project `prj` with two packages, `foo` and `libfoo`:

```
prj/
├── foo/
└── libfoo/
```

Assuming `foo` and `libfoo` have been initialized in the default build
configuration, the following invocations illustrate the common `sync` use
cases (the current working directory is shown before the shell prompt).

Synchronize `foo` and `libfoo` with the default configuration:

```
prj/$ bdep sync
```

The same (all initialized packages in a project are always synchronized at
once):

```
prj/$ cd foo
foo/$ bdep sync
```

As above but also reconfigure `foo`:

```
prj/$ cd foo
foo/$ bdep sync config.foo.bar=true
```

The same (package is specified explicitly):

```
prj/$ bdep sync foo config.foo.bar=true
```

Add a dependency on `libx` with `sync` fetching and configuring a suitable
version:

```
foo/$ edit manifest  # Add 'depends: libx ^1.0.0'
foo/$ bdep sync
```

Upgrade all the immediate dependencies of `foo`:

```
foo/$ bdep sync -u
```

Upgrade all the dependencies of all the initialized packages in a project
recursively:

```
foo/$ cd ../
prj/$ bdep sync -u -r
```

Upgrade `libx` to the latest version:

```
prj/$ bdep sync libx
```

Upgrade `libx` and its immediate dependencies to the latest version:

```
prj/$ bdep sync -u -i libx
```

Upgrade `libx` to the latest patch version:

```
prj/$ bdep sync -p libx
```

Upgrade `libx` and all its dependencies recursively to the latest patch
version:

```
prj/$ bdep sync -p -r libx
```

Upgrade `libx` to version `1.2.3`:

```
prj/$ bdep sync libx/1.2.3
```

Upgrade `libx` to version `1.2.3` and patch all its dependencies, recursively:

```
prj/$ bdep sync -p -r libx/1.2.3
```

## Options

Note: also see [common options](bdep-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--upgrade`, `-u` | | Upgrade dependencies to the latest available version that satisfies all the constraints. |
| `--patch`, `-p` | | Upgrade dependencies to the latest available patch version that satisfies all the constraints. |
| `--immediate`, `-i` | | Also upgrade or patch immediate dependencies. |
| `--recursive`, `-r` | | Also upgrade or patch all dependencies, recursively. |
| `--yes`, `-y` | | Don't prompt for confirmation when up/down-grading dependencies. |
| `--disfigure` | | Disfigure project packages during synchronization effectively causing their from-scratch reconfiguration. |
| `--fetch`, `-f` | | Perform the `fetch` command prior to synchronization. |
| `--fetch-full`, `-F` | | Perform the `fetch --full` command prior to synchronization. |
| `--sys-no-query` | | Do not query the system package manager for the installed versions of packages specified with the `sys` scheme. See the corresponding `bpkg-pkg-build` option for details. |
| `--sys-install` | | Instruct the system package manager to install available versions of packages specified with the `sys` scheme that are not already installed. See the corresponding `bpkg-pkg-build` option for details. |
| `--sys-no-fetch` | | Do not fetch the system package manager metadata before querying for available versions of packages specified with the `sys` scheme. See the corresponding `bpkg-pkg-build` option for details. |
| `--sys-no-stub` | | Do not require a stub for packages specified with the `sys` scheme. See the corresponding `bpkg-pkg-build` option for details. |
| `--sys-yes` | | Assume the answer to the system package manager prompts is `yes`. See the corresponding `bpkg-pkg-build` option for details. |
| `--sys-sudo` | `<prog>` | The `sudo` program to use for system package manager interactions that normally require administrative privileges (fetch package metadata, install packages, etc). Defaults to `sudo`. See the corresponding `bpkg-pkg-build` option for details. |
| `--create-host-config` | | Create a configuration for build-time dependencies without prompt. |
| `--create-build2-config` | | Create a configuration for build system module dependencies without prompt. |
| `--implicit` | | Perform implicit synchronization. This mode is normally used by other tools (for example, a build system hook) to ensure projects and configurations are synchronized. To improve performance, especially for the "everything is already synchronized" case, `sync` executed in this mode assumes that no configuration flags (see `bdep-config`) have changed since the last explicit synchronization. It also does not search for a project in the current working directory -- if any, its directory should be specified explicitly with `--config|-c`. |

## Default Options Files

See [bdep-default-options-files](bdep-default-options-files.md) for an
overview of the default options files. For the `sync` command the search start
directory is the project directory, except for the implicit mode for which only
the predefined directories (system, etc) are searched in. The following options
files are searched for in each directory and, if found, loaded in the order
listed:

```
bdep.options
bdep-{sync|sync-implicit}.options  # (mode-dependent)
```

The following `sync` command options cannot be specified in the default options
files:

```
--directory|-d
--implicit
--config|-c
```

## Environment

The `BDEP_SYNC` environment variable can be used to suppress automatic
synchronization on build system invocation. If set, auto-synchronization will
only be performed if the variable's value is `true` or `1`. The ability to
suppress auto-synchronization can be useful when you don't have usable `bdep`
and/or `bpkg`.

To avoid recursive re-synchronization, the `sync` command also maintains the
`BDEP_SYNCED_CONFIGS` environment variable. It contains a space-separated,
`"`-quoted list of configuration paths that have been or are being synchronized
by the current `bdep` invocation chain. The `sync` command examines this
variable and silently ignores synchronization requests that have been or are
already being performed.

## See Also

- [bdep README](README.md)
- [bdep-init](bdep-init.md)
- [bdep-config](bdep-config.md)
- [bdep-projects-configs](bdep-projects-configs.md)
- [bdep-argument-grouping](bdep-argument-grouping.md)
- [bdep-default-options-files](bdep-default-options-files.md)
- [`build2-project-config`](../guides/build2-project-config.md) -- project configuration system
