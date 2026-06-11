# bdep -- Project Dependency Manager

_Use for: day-to-day project workflow -- creating projects, initializing
configurations, syncing manifests/lockfiles, running tests across
configurations, releasing and publishing packages._

## Overview

`bdep` is the build2 project dependency manager. Where `bpkg` manages individual
packages inside a build configuration, `bdep` manages the lifecycle of a project
under active development. It acts as an orchestration layer that calls `bpkg` for
dependency management and `b` (the build system) for building. It does not replace
either tool but coordinates them into a coherent development workflow.

A `bdep` project is a directory, normally tracked by a version control system such
as git, called the project repository. A project contains one or more build2
packages. If it contains multiple packages they are typically related, for example a
library (`libhello`) and a program (`hello`) that uses it. Packages that live inside
the project are called project packages. Packages that the project depends on from
outside are called dependency packages.

For development, a `bdep` project is associated with one or more `bpkg` build
configurations. These configurations serve as the backing store in which project
packages and their dependency packages are built. The set of associated configurations
and the list of project packages initialized in each one are stored in the `bdep`
project database under the `.bdep/` subdirectory of the project root. Multiple
projects can share a single build configuration, in which case all of them are
synchronized together.

The core of `bdep` is state synchronization. When a developer edits a package
`manifest` to add, remove, or change a dependency, `bdep-sync` brings the associated
configurations up to date: it fetches missing packages, configures them, and updates
the `lockfile`. By default, build configurations are auto-synced on every build system
invocation through a forwarding mechanism, so an explicit `bdep sync` call is rarely
needed. The source directory forwards to the default configuration, allowing `b` to be
run directly in source with results linked back via symlinks.


## Key Concepts

**Project repository** -- The VCS-tracked root directory of a project. Contains one
or more packages and the `.bdep/` project database. A single-package project places
`manifest` and `lockfile` at the root. A multi-package project adds a
`packages.manifest` listing subdirectory locations.

**Project packages vs dependency packages** -- Packages whose source lives inside the
project repository are project packages. Packages consumed from external repositories
are dependency packages. The same package can be a project package in one context and
a dependency package in another.

**Build configuration set** -- The collection of `bpkg` configurations associated
with a project via `bdep init` or `bdep config add/create`. Each configuration is
identified by an optional name (e.g., `@gcc`) and a directory path. Commands that
accept `<cfg-spec>` can address configurations by name, path, or `--all / -a`.

**Auto-sync** -- When the default configuration has auto-sync enabled (the default),
every invocation of the build system in the forwarded source directory triggers
`bdep-sync` automatically. Dependency changes take effect without a manual sync step.

**Forwarding** -- The default configuration is set up as a forward target for the
source directory. Running `b` in source builds in that configuration and links
artifacts back, so executables appear alongside source. Other configurations require
explicit `bdep update/test/clean` or direct `b` invocation with the configuration
path.


## Command Reference

### Project Lifecycle

| Command | Description |
|---|---|
| `bdep-new` | Create and initialize a new project |
| `bdep-init` | Initialize project in build configurations |
| `bdep-deinit` | Deinitialize project in build configurations |

### Build Operations

| Command | Description |
|---|---|
| `bdep-sync` | Synchronize project and build configurations (delegates to bpkg) |
| `bdep-fetch` | Fetch list of available project dependencies |
| `bdep-update` | Update (build) project in build configurations (delegates to b) |
| `bdep-test` | Test project in build configurations (delegates to b) |
| `bdep-clean` | Clean project in build configurations (delegates to b) |

### Status and CI

| Command | Description |
|---|---|
| `bdep-status` | Print status of project and/or its dependencies |
| `bdep-ci` | Submit project test request to CI server |

### Release Workflow

| Command | Description |
|---|---|
| `bdep-release` | Manage project version during release |
| `bdep-publish` | Publish project to archive repository |

### Configuration Management

| Command | Subcommands | Description |
|---|---|---|
| `bdep-config` | `add` | Add an existing bpkg configuration to the project set |
| | `create` | Create a new bpkg configuration and add it |
| | `link` | Link two configurations (host/target relationship) |
| | `unlink` | Remove a link between two configurations |
| | `list` | List configurations associated with the project |
| | `move` | Move a configuration to a new directory |
| | `rename` | Rename a configuration |
| | `remove` | Remove one or more configurations from the project set |
| | `set` | Change per-configuration flags: default, forward, auto-sync |

### Reference Topics

| Topic | Description |
|---|---|
| `bdep-argument-grouping` | Argument grouping facility for passing options to subtools |
| `bdep-default-options-files` | Specifying default options via files |
| `bdep-projects-configs` | Specifying projects and configurations on the command line |
| `bdep-common-options` | Details on options common to all commands |


## Typical Workflows

### Create a new project and initialize dependencies

1. Create the project skeleton with `bdep new`:
   ```
   bdep new -l c++ -t exe hello
   cd hello
   ```
2. Create an associated build configuration and initialize the project in it:
   ```
   bdep init -C @gcc cc config.cxx=g++
   ```
3. Edit `repositories.manifest` to add a prerequisite repository.
4. Edit `manifest` to add a `depends:` entry.
5. Synchronize configurations to fetch and configure the new dependency:
   ```
   bdep sync
   ```

### Add a dependency to an existing project

1. Edit `repositories.manifest` and add the dependency's repository under
   `role: prerequisite`.
2. Edit the package `manifest` and add a `depends:` line with the desired
   version constraint.
3. Run `bdep sync` (or simply invoke `b` if auto-sync is active). `bdep` fetches
   and configures the new dependency and upgrades the package iteration in all
   associated configurations.

### Run tests across all configurations

1. Verify the project is initialized in the desired configurations:
   ```
   bdep status -a
   ```
2. Run tests across all configurations at once:
   ```
   bdep test -a
   ```
   Each configuration prints a header line before its output. To target specific
   configurations use names: `bdep test @gcc @clang`.

### Release a new version

1. Finalize all changes and ensure tests pass: `bdep test -a`.
2. Use `bdep release` to update the version in `manifest` and tag the VCS commit:
   ```
   bdep release
   ```
3. Publish the release to a package archive repository:
   ```
   bdep publish
   ```


## Navigation

### Per-command reference

- [bdep-new](bdep-new.md)
- [bdep-init](bdep-init.md)
- [bdep-deinit](bdep-deinit.md)
- [bdep-sync](bdep-sync.md)
- [bdep-fetch](bdep-fetch.md)
- [bdep-update](bdep-update.md)
- [bdep-test](bdep-test.md)
- [bdep-clean](bdep-clean.md)
- [bdep-status](bdep-status.md)
- [bdep-ci](bdep-ci.md)
- [bdep-release](bdep-release.md)
- [bdep-publish](bdep-publish.md)
- [bdep-config](bdep-config.md)
- [bdep-help](bdep-help.md)

### Shared reference

- [Common options](bdep-common-options.md)
- [Projects and configurations](bdep-projects-configs.md)
- [Default options files](bdep-default-options-files.md)
- [Argument grouping](bdep-argument-grouping.md)
