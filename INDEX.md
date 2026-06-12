# build2 Ecosystem -- AI Index

## Overview

build2 is an integrated build toolchain for C and C++ development that
combines a build system, a package manager, and a project dependency manager
into a coherent ecosystem. The three tools -- b (the build system driver),
bpkg (the package dependency manager), and bdep (the project dependency
manager) -- are designed to work together but can also be used independently.

The build system driver `b` reads `buildfile` scripts and executes build
operations such as compile, link, test, and install. It understands targets,
rules, modules, and configuration, and supports both in-source and
out-of-source builds. A bpkg build configuration is, in build system terms,
an amalgamation: a configuration project that contains packages as
sub-projects, so packages automatically inherit configuration values and can
resolve imports to sibling packages inside the same amalgamation.

bpkg manages the lifecycle of packages within a build configuration: it
creates configurations, adds and fetches repositories, resolves version
constraints, builds packages and their dependency trees, and can install or
generate binary distribution packages. bdep sits above bpkg and manages the
developer-facing project workflow: it associates a VCS project directory with
one or more bpkg build configurations, synchronises dependency declarations
in `manifest` and `lockfile` files with the actual state of those
configurations, and provides convenience wrappers for common build system
operations (update, test, clean) that operate across multiple configurations.


## Tool Summary

| Tool   | Binary | Role                          |
|--------|--------|-------------------------------|
| build2 | `b`    | Build system driver           |
| build2 | `bx`   | Shell script and task runner  |
| bpkg   | `bpkg` | Package dependency manager    |
| bdep   | `bdep` | Project dependency manager    |


## Command Index

### b (build system driver)

b accepts a buildspec of the form
`<meta-operation>(<operation>(<target>...))`. All parts are optional and
default to `perform(update(./))`.

#### Meta-operations

| Meta-operation | Purpose                                                                      |
|----------------|------------------------------------------------------------------------------|
| perform        | Perform an operation (default meta-operation)                               |
| configure      | Configure all operations and save result to build/config.build              |
| disfigure      | Remove configuration saved by configure                                     |
| create         | Create and configure a configuration project (amalgamation)                 |
| dist           | Prepare a distribution archive containing all files needed to build         |
| info           | Print project metadata (name, version, dirs, modules) to stdout             |

#### Operations

| Operation          | Purpose                                                                |
|--------------------|------------------------------------------------------------------------|
| update             | Build (update) a target (default operation for perform)                |
| clean              | Remove build artifacts for a target                                    |
| test               | Test a target; runs update as a pre-operation                          |
| update-for-test    | Update only what is necessary for testing                              |
| install            | Install a target; runs update as a pre-operation                       |
| uninstall          | Uninstall a target; runs update as a pre-operation                     |
| update-for-install | Update only what is necessary for installation                         |


### bx (shell script and task runner)

`bx` runs a `.bx` shell script or a named task with optional arguments.
The first argument determines the mode: a script path (contains `/` or ends
in `.bx`) or a task name (anything else). No argument means the default task
-- use `--` to pass arguments to it.

| Form | Purpose |
|------|---------|
| `bx <path> [<arg>...]` | Run a `.bx` script |
| `bx <task> [<arg>...]` | Run a named task |
| `bx [-- <arg>...]` | Run the default task |

See [bx reference](bx/bx.md) for the full option list.


### bpkg commands

| Command         | Alias      | Purpose                                   |
|-----------------|------------|-------------------------------------------|
| cfg-create      | create     | Create configuration                      |
| cfg-info        |            | Print configuration information           |
| cfg-link        | link       | Link configuration                        |
| cfg-unlink      | unlink     | Unlink configuration                      |
| rep-info        |            | Print repository information              |
| rep-add         | add        | Add repository to configuration           |
| rep-remove      | remove     | Remove repository from configuration      |
| rep-list        | list       | List repositories in configuration        |
| rep-fetch       | fetch      | Fetch list of available packages          |
| rep-create      |            | Create repository                         |
| pkg-status      | status     | Print package status                      |
| pkg-build       | build      | Build package                             |
| pkg-drop        | drop       | Drop package                              |
| pkg-install     | install    | Install package                           |
| pkg-uninstall   | uninstall  | Uninstall package                         |
| pkg-update      | update     | Update package                            |
| pkg-test        | test       | Test package                              |
| pkg-clean       | clean      | Clean package                             |
| pkg-bindist     | bindist    | Generate binary distribution package      |
| pkg-verify      |            | Verify package archive                    |
| pkg-fetch       |            | Fetch package archive                     |
| pkg-unpack      |            | Unpack package archive                    |
| pkg-checkout    |            | Check out package version                 |
| pkg-configure   |            | Configure package                         |
| pkg-disfigure   |            | Disfigure package                         |
| pkg-purge       |            | Purge package                             |
| help            |            | Show help for a command or help topic     |


### bdep commands

| Command  | Purpose                                              |
|----------|------------------------------------------------------|
| new      | Create and initialize new project                    |
| init     | Initialize project in build configurations           |
| sync     | Synchronize project and build configurations         |
| fetch    | Fetch list of available project dependencies         |
| status   | Print status of project and/or its dependencies      |
| ci       | Submit project test request to CI server             |
| release  | Manage project's version during release              |
| publish  | Publish project to archive repository                |
| deinit   | Deinitialize project in build configurations         |
| config   | Manage project build configurations                  |
| test     | Test project in build configurations                 |
| update   | Update project in build configurations               |
| clean    | Clean project in build configurations                |
| help     | Show help for a command or help topic                |


## Navigation

### Reference files

- [b README](b/README.md) -- b driver overview
- [b full reference](b/b.md)
- [bx README](bx/README.md) -- shell script and task runner
- [bx full reference](bx/bx.md)
- [bpkg reference](bpkg/README.md) -- bpkg overview, workflows, command table, and per-command index
- [bdep reference](bdep/README.md) -- bdep overview, workflows, command table, and per-command index

### HOWTO

- [HOWTO index](HOWTO/README.md) -- practical recipes indexed by topic

### Guides

- [Glossary](GLOSSARY.md)
- [build2 concepts: targets, scopes, modules, variables](guides/build2-intro-concepts.md)
- [build2 buildfile language reference](guides/build2-buildfile-language.md)
- [build2 directives, name patterns, and attributes](guides/build2-directives-patterns.md)
- [build2 advanced projects: importation, libraries, testing, installation](guides/build2-projects-advanced.md)
- [build2 manual: project configuration](guides/build2-project-config.md)
- [build2 manual: targets and variables](guides/build2-targets-variables.md)
- [build2 manual: core modules (config, test, install)](guides/build2-modules-core.md)
- [build2 module: version](guides/build2-module-version.md)
- [build2 modules: bin target types](guides/build2-modules-bin.md)
- [build2 modules: cc C-common infrastructure](guides/build2-modules-cc.md)
- [build2 modules: c compilation](guides/build2-modules-c.md)
- [build2 modules: cxx C++ compilation](guides/build2-modules-cxx.md)
- [build2 manual: misc modules](guides/build2-modules-misc.md)
- [testscript reference](guides/testscript-summary.md)
- [testscript: commands, redirections, and builtins](guides/testscript-commands.md)
- [packaging guide: setup through installation](guides/packaging-guide-summary.md)
- [packaging guide: testing and publishing](guides/packaging-guide-testing.md)
- [packaging guide: review process and checklist](guides/packaging-guide-review.md)
- [bpkg package naming, version format, and constraint syntax](guides/bpkg-package-name-version.md)
- [packaging guide: version management workflows](guides/packaging-guide-version-management.md)
- [packaging guide: common antipatterns and upstream patching](guides/packaging-guide-antipatterns.md)
- [autoconf module](guides/build2-modules-autoconf.md)
- [autoconf: project-specific checks](guides/build2-autoconf-project-checks.md)
- [autoconf: buildfile integration](guides/build2-autoconf-buildfile.md)
- [autoconf: contributing builtin checks](guides/build2-autoconf-contributing-checks.md)
- [kconfig module: language reference](guides/kconfig-summary.md)
- [kconfig module: build system integration](guides/kconfig-integration.md)
- [install and bootstrap (steps 1-2)](guides/install-bootstrap.md)
- [install: step 3 from repository](guides/install-toolchain.md)
- [install: upgrade](guides/install-upgrade.md)
