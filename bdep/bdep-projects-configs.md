# bdep-projects-configs -- specifying projects and configurations

> Help topic. Describes how to specify projects, packages, and build
> configurations on the bdep command line. Not a command itself.

## Synopsis

```
bdep <command> [<pkg-spec>] [<cfg-spec>] ...

<cfg-spec> = (@<cfg-name> | --config|-c <cfg-dir>)... | --all|-a
<pkg-spec> = (<pkg> | (--directory|-d <pkg-dir>))... | <prj-spec>
<prj-spec> = --directory|-d <prj-dir>
```

## Description

Most bdep commands operate on a project (or a subset of its packages) together
with one or more of its associated build configurations. For example, `status`
shows the package state in selected configurations and `fetch` fetches available
dependency versions for selected configurations.

### Specifying the project or package

Without any `--directory|-d` option, bdep assumes the current working
directory is the project root, a package root, or a subdirectory of a package.
This mirrors how version control tools like `git` work.

To target a specific directory, use `--directory|-d`. In all commands except
`init`, an initialized package can also be referred to by its name (`<pkg>`).

bdep always operates on a single project but can act on multiple packages
within it simultaneously.

Some commands (such as `fetch`) operate at the project level. If given a
package directory they automatically determine the project root. Other commands
(such as `status`) operate at the package level. If given a project directory
they automatically expand to all packages initialized in the relevant
configurations.

### Specifying build configurations

A build configuration associated with the project can be specified by name
using the `@<cfg-name>` notation:

```
$ bdep status @gcc @clang
```

> **Note for Windows/PowerShell users:** a leading `@` has special meaning in
> PowerShell. Use the alternative `-@gcc` syntax or `-n gcc` instead.

A configuration without a name can be specified by its directory path using
`--config|-c`:

```
$ bdep status @gcc -c ../builds/clang
```

Name and directory forms can be freely mixed. To target all associated
configurations use `--all|-a`.

### Default configurations

Each associated configuration can be designated as the _default_ for its
configuration type. When no configuration is specified explicitly, the default
configurations are used. Running `bdep status` with no arguments in a project
directory therefore shows the status across all default configurations.

## See Also

- [bdep SUMMARY](SUMMARY.md)
- [bdep-config](bdep-config.md)
- [bdep-init](bdep-init.md)
