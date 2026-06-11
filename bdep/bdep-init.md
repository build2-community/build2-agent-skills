# bdep-init -- initialize project in build configurations

## Synopsis

```
bdep init [<options>] [<pkg-spec>] [<cfg-spec>] [<pkg-args>]
bdep init [<options>] [<prj-spec>] --empty|-E
bdep init [<options>] [<pkg-spec>] --config-add|-A <cfg-dir> [@<cfg-name>]
          [<pkg-args>]
bdep init [<options>] [<pkg-spec>] --config-create|-C <cfg-dir> [@<cfg-name>]
          [<cfg-args>] [-- <pkg-args>]
```

```
<cfg-spec> = (@<cfg-name> | --config|-c <cfg-dir>)... | --all|-a
<pkg-spec> = (--directory|-d <pkg-dir>)... | <prj-spec>
<prj-spec> = --directory|-d <prj-dir>
<pkg-args> = (?<pkg> | <cfg-var>)...
<cfg-args> = [-- [<bpkg-options>]] [--existing|-e | (<module> | <cfg-var>)...]
```

## Description

The `init` command initializes a project in one or more build configurations.
The first form initializes the specified project packages (`<pkg-spec>`), or,
if the project itself is specified (`<prj-spec>`), all its available packages,
in one or more build configurations (`<cfg-spec>`) that have already been
associated with the project (see [bdep-config](bdep-config.md)).

If no project directory is specified, then the current working directory is
assumed. If no configuration is specified, then the default configuration is
assumed (failing if multiple default configurations are present). Note that
unlike in all other commands, in `init` the package to initialize in
`<pkg-spec>` cannot be specified as a `<pkg>` name, only as a directory with
`--directory|-d`. See [bdep-projects-configs](bdep-projects-configs.md) for
details on specifying projects and configurations. Optional `<pkg-args>` are
the additional dependency packages and/or configuration variables to pass to
the underlying `bpkg-pkg-build` command.

The second form (`--empty` is specified) initializes an empty project database
that can later be used to first add build configurations (see
[bdep-config](bdep-config.md)) and then initialize project packages using the
first form.

The third (`--config-add`) and fourth (`--config-create`) forms are shortcuts
to first adding an existing or newly created build configuration and then
initializing project packages in that configuration. Semantically they are
equivalent to first performing the `config add` or `config create` commands
(see [bdep-config](bdep-config.md)), respectively, followed by the first form.
Optional `<cfg-args>` in the fourth form are the additional arguments to the
underlying `bpkg-cfg-create` command. Note that in this case to specify
`<pkg-args>` without specifying `<cfg-args>` you have to use two `--`
separators, for example:

```
$ bdep init -C ../prj-gcc @gcc -- -- ?sys:libsqlite3/*
```

Configuration variables can be specified to only apply to specific packages in
`<pkg-args>` using the argument grouping mechanism (see
[bdep-argument-grouping](bdep-argument-grouping.md)). Additionally, such
packages can be placed into specific linked configurations by specifying the
configuration with one of the `--config*` options (or `@` notation) using the
same grouping mechanism. For example (assuming `gcc` is linked to `common`):

```
$ bdep init @gcc { @common config.liblarge.extra=true }+ ?liblarge
```

## Examples

Consider project `prj` with two packages, `foo` and `libfoo`:

```
prj/
├── foo/
└── libfoo/
```

The following invocations illustrate the common `init` use cases (the current
working directory is shown before the shell prompt).

Create new build configuration in `../prj-gcc`, call it `gcc`, and initialize
project packages `foo` and `libfoo` in this configuration:

```
prj/$ bdep init -C ../prj-gcc @gcc cc config.cxx=g++
```

Create new build configuration in `../prj-clang` using `bpkg-cfg-create`.
Then add it calling it `clang` and initialize project package `foo` in this
configuration:

```
prj/$ bpkg create -d ../prj-clang cc config.cxx=clang++
prj/$ cd foo
foo/$ bdep init -A ../../prj-clang @clang
```

Initialize project package `libfoo` in the build configuration `clang`:

```
foo/$ cd ..
prj/$ bdep init -d libfoo @clang
```

To additionally configure `libfoo` add configuration variables to the above
command line:

```
prj/$ bdep init -d libfoo @clang config.libfoo.bar=true
```

The following set of invocations achieves the same end result but using the
`bdep-config` command to manage configurations and `bdep-sync` command to
reconfigure a package.

Initialize an empty project database:

```
prj/$ bdep init --empty
```

Create new build configuration in `../prj-gcc`, call it `gcc`:

```
prj/$ bdep config create ../prj-gcc @gcc cc config.cxx=g++
```

Add existing build configuration in `../prj-clang`, call it `clang`:

```
prj/$ bdep config add ../prj-clang @clang
```

Initialize project packages `foo` and `libfoo` in build configurations `gcc`
and `clang`:

```
prj/$ bdep init @gcc @clang
```

Or, alternatively, in all the build configurations:

```
prj/$ bdep init -a
```

Reconfigure `libfoo` in the build configuration `clang`:

```
prj/$ bdep sync libfoo @clang config.libfoo.bar=true
```

## Options

Note: also see [common options](bdep-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--empty`, `-E` | | Initialize an empty build configuration set. |
| `--config-add`, `-A` | `<dir>` | Add an existing build configuration `<dir>`. |
| `--config-create`, `-C` | `<dir>` | Create a new build configuration in `<dir>`. |
| `--no-sync` | | Enter the project into the database but do not initialize it in the build configurations. The initialization can be finished later with an explicit `bdep-sync` command. |
| `--sys-no-query` | | Do not query the system package manager for the installed versions of packages specified with the `sys` scheme. See the corresponding `bpkg-pkg-build` option for details. |
| `--sys-install` | | Instruct the system package manager to install available versions of packages specified with the `sys` scheme that are not already installed. See the corresponding `bpkg-pkg-build` option for details. |
| `--sys-no-fetch` | | Do not fetch the system package manager metadata before querying for available versions of packages specified with the `sys` scheme. See the corresponding `bpkg-pkg-build` option for details. |
| `--sys-no-stub` | | Do not require a stub for packages specified with the `sys` scheme. See the corresponding `bpkg-pkg-build` option for details. |
| `--sys-yes` | | Assume the answer to the system package manager prompts is `yes`. See the corresponding `bpkg-pkg-build` option for details. |
| `--sys-sudo` | `<prog>` | The `sudo` program to use for system package manager interactions that normally require administrative privileges (fetch package metadata, install packages, etc). Defaults to `sudo`. See the corresponding `bpkg-pkg-build` option for details. |
| `--create-host-config` | | Create a configuration for build-time dependencies without prompt (see `bdep-sync` for details). |
| `--create-build2-config` | | Create a configuration for build system module dependencies without prompt (see `bdep-sync` for details). |

## Default Options Files

See [bdep-default-options-files](bdep-default-options-files.md) for an
overview of the default options files. For the `init` command the search start
directory is the project directory. The following options files are searched
for in each directory and, if found, loaded in the order listed:

```
bdep.options
bdep-{config config-add}.options                # if --config-add|-A
bdep-{config config-add config-create}.options  # if --config-create|-C
bdep-init.options
```

The following `init` command options cannot be specified in the default options
files:

```
--directory|-d
--config-add|-A
--config-create|-C
--wipe
```

## See Also

- [bdep README](README.md)
- [bdep-config](bdep-config.md)
- [bdep-sync](bdep-sync.md)
- [bdep-projects-configs](bdep-projects-configs.md)
- [bdep-argument-grouping](bdep-argument-grouping.md)
- [bdep-default-options-files](bdep-default-options-files.md)
- [`toolchain-dev-setup`](../HOWTO/toolchain-dev-setup.md) -- setting up build2 for toolchain development
