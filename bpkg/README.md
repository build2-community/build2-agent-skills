# bpkg -- Package Manager

_Use for: creating build configurations, adding or removing package
dependencies, resolving version conflicts, building/installing/publishing
packages._

## Overview

`bpkg` is the `build2` package dependency manager. It manipulates build
configurations, packages, and repositories using a set of named commands. A
package is an archive or directory (potentially in a version control system)
that contains a `build2` project together with a `manifest` file. `bpkg` can
use package archives and directories directly from the filesystem, or it can
fetch them from remote or local repositories.

A `bpkg` build configuration is a directory that contains packages built with
a consistent set of settings (target platform, compiler, compile options, and
so on). Internally the configuration is a `build2` amalgamation that treats
each installed package as a subproject. Configurations are cheap to create and
can be discarded at will. They can be moved or copied by moving or copying the
directory, though a move or copy may leave some packages out-of-date.

Build configurations come in three roles. A *target* configuration holds
packages intended to run on the target platform. A *host* configuration holds
packages that run on the build host, such as code-generation tools that must
execute during the build. A *build2* configuration holds `build2` build system
modules. When `pkg-build` needs a build-time dependency it looks for a linked
host configuration, and when it needs a build system module it looks for a
linked build2 configuration.

Configurations can be linked with each other using `cfg-link`. When a package
is built in one configuration its dependencies can be satisfied from any linked
configuration. This allows a shared "base" configuration to hold common
libraries that are reused across many per-target configurations without
rebuilding them. The relationship between `bpkg` and `bdep` is that `bdep` is
a project-level wrapper: it manages the association between a source project
and one or more `bpkg` configurations, and it delegates the actual package
management work to `bpkg`.

---

## Key Concepts

**Configuration.** A directory managed by `bpkg` that acts as a `build2`
amalgamation. Created with `cfg-create`, queried with `cfg-info`, and linked
to other configurations with `cfg-link` / `cfg-unlink`.

**Held package.** A package that was explicitly requested by the user (as
opposed to one pulled in automatically as a dependency). Held packages are the
targets of upgrade/patch operations when `pkg-build --upgrade` or
`pkg-build --patch` is used without an explicit package list.

**Repository.** A collection of packages together with metadata describing
prerequisite and complement repositories. Three repository types are supported:
archive, directory, and version-control. Identified by a local path or a URL.
See `bpkg-repository-types` for structure and URL format details.

**pkg-build vs. manual workflow.** `pkg-build` is the high-level command: it
resolves dependencies, fetches sources, configures, and builds in one step. The
manual workflow uses the lower-level primitives `pkg-fetch`, `pkg-unpack` (or
`pkg-checkout`), `pkg-configure`, `pkg-update`, `pkg-disfigure`, and
`pkg-purge` for fine-grained control, for example when working with a package
checked out from version control.

**Configuration linking.** `cfg-link` records a directed link from the current
configuration to another. The linked configuration can then supply dependency
packages during builds. `cfg-unlink` removes such a link. Multiple links are
allowed, enabling layered dependency sharing.

---

## Command Reference

### Configuration Management

| Command | Alias | Description |
|---|---|---|
| `bpkg-cfg-create` | `create` | Create a new build configuration |
| `bpkg-cfg-info` | -- | Print information about a configuration |
| `bpkg-cfg-link` | `link` | Link another configuration into the current one |
| `bpkg-cfg-unlink` | `unlink` | Remove a previously created configuration link |

### Repository Management

| Command | Alias | Description |
|---|---|---|
| `bpkg-rep-add` | `add` | Add a repository to the configuration |
| `bpkg-rep-remove` | `remove` | Remove a repository from the configuration |
| `bpkg-rep-list` | `list` | List repositories in the configuration |
| `bpkg-rep-info` | -- | Print information about a repository |
| `bpkg-rep-fetch` | `fetch` | Fetch the list of available packages from all added repositories |
| `bpkg-rep-create` | -- | Create a repository from a directory of package archives |

### Package Lifecycle

| Command | Alias | Description |
|---|---|---|
| `bpkg-pkg-build` | `build` | Build one or more packages (fetch, configure, compile in one step) |
| `bpkg-pkg-drop` | `drop` | Drop (remove) one or more packages and unused dependencies |
| `bpkg-pkg-status` | `status` | Print status of one or more packages |
| `bpkg-pkg-fetch` | -- | Fetch a package archive into the configuration |
| `bpkg-pkg-unpack` | -- | Unpack a fetched package archive |
| `bpkg-pkg-checkout` | -- | Check out a specific package version from version control |
| `bpkg-pkg-configure` | -- | Configure an unpacked package |
| `bpkg-pkg-disfigure` | -- | Disfigure (unconfigure) a configured package |
| `bpkg-pkg-update` | `update` | Update (recompile) a configured package |
| `bpkg-pkg-test` | `test` | Run the test suite of a configured package |
| `bpkg-pkg-clean` | `clean` | Clean build artifacts of a configured package |
| `bpkg-pkg-install` | `install` | Install a built package to the configured install root |
| `bpkg-pkg-uninstall` | `uninstall` | Uninstall a previously installed package |
| `bpkg-pkg-purge` | -- | Remove a package that was fetched or unpacked but not configured |
| `bpkg-pkg-verify` | -- | Verify the integrity and structure of a package archive |
| `bpkg-pkg-bindist` | `bindist` | Generate a binary distribution package (deb, rpm, etc.) |

### Reference Topics

| Topic | Description |
|---|---|
| `bpkg-argument-grouping` | Argument grouping facility for per-package option sets |
| `bpkg-default-options-files` | How and where default options files are loaded |
| `bpkg-repository-types` | Repository types (archive, directory, git), structure, and URL formats |
| `bpkg-repository-signing` | How to sign a repository and how signatures are verified |
| `bpkg-repository-manifest-reference` | Repository, repository list, signature, and package list manifest formats |
| `bpkg-common-options` | All options shared across every `bpkg` command |

---

## Typical Workflows

### Install a package from a repository

1. Create a configuration and specify the C++ toolchain and install root:
   ```
   bpkg create cc config.cxx=g++ config.install.root=/usr/local config.install.sudo=sudo
   ```
2. Add one or more source repositories:
   ```
   bpkg add https://pkg.cppget.org/1/stable
   ```
3. Fetch repository metadata (available package list):
   ```
   bpkg fetch
   ```
4. Build the desired packages (resolves and builds all dependencies):
   ```
   bpkg build libfoo bar
   ```
5. Install to the configured root:
   ```
   bpkg install bar
   ```

### Build a package from a local source directory

1. Create a configuration:
   ```
   bpkg create cc config.cxx=clang++
   ```
2. Build directly from the source directory (trailing `/` is required):
   ```
   bpkg build /path/to/mypkg/
   ```

### Upgrade packages

1. Refresh the available package list:
   ```
   bpkg fetch
   ```
2. Upgrade all held packages to their latest compatible versions:
   ```
   bpkg build --upgrade
   ```
   Or patch (minor/patch updates only) all held packages:
   ```
   bpkg build --patch
   ```
3. Upgrade a specific package:
   ```
   bpkg build libfoo
   ```

### Remove a package

Drop a package and any dependencies that are no longer needed:
```
bpkg drop foo
```

---

## Navigation

### Per-command reference

- [bpkg-cfg-create](bpkg-cfg-create.md)
- [bpkg-cfg-info](bpkg-cfg-info.md)
- [bpkg-cfg-link](bpkg-cfg-link.md)
- [bpkg-cfg-unlink](bpkg-cfg-unlink.md)
- [bpkg-rep-add](bpkg-rep-add.md)
- [bpkg-rep-remove](bpkg-rep-remove.md)
- [bpkg-rep-list](bpkg-rep-list.md)
- [bpkg-rep-info](bpkg-rep-info.md)
- [bpkg-rep-fetch](bpkg-rep-fetch.md)
- [bpkg-rep-create](bpkg-rep-create.md)
- [bpkg-pkg-build](bpkg-pkg-build.md)
- [bpkg-pkg-drop](bpkg-pkg-drop.md)
- [bpkg-pkg-status](bpkg-pkg-status.md)
- [bpkg-pkg-fetch](bpkg-pkg-fetch.md)
- [bpkg-pkg-unpack](bpkg-pkg-unpack.md)
- [bpkg-pkg-checkout](bpkg-pkg-checkout.md)
- [bpkg-pkg-configure](bpkg-pkg-configure.md)
- [bpkg-pkg-disfigure](bpkg-pkg-disfigure.md)
- [bpkg-pkg-update](bpkg-pkg-update.md)
- [bpkg-pkg-test](bpkg-pkg-test.md)
- [bpkg-pkg-clean](bpkg-pkg-clean.md)
- [bpkg-pkg-install](bpkg-pkg-install.md)
- [bpkg-pkg-uninstall](bpkg-pkg-uninstall.md)
- [bpkg-pkg-purge](bpkg-pkg-purge.md)
- [bpkg-pkg-verify](bpkg-pkg-verify.md)
- [bpkg-pkg-bindist](bpkg-pkg-bindist.md)

### Shared reference

- [Common options](bpkg-common-options.md)
- [Argument grouping](bpkg-argument-grouping.md)
- [Default options files](bpkg-default-options-files.md)
- [Repository types](bpkg-repository-types.md)
- [Repository signing](bpkg-repository-signing.md)
- [Repository manifest reference](bpkg-repository-manifest-reference.md)

## See Also

- [`bdep README`](../bdep/README.md) -- project dependency manager that orchestrates bpkg
- [`bpkg-dependency-negotiation`](bpkg-dependency-negotiation.md) -- how version constraints are resolved across the dependency graph
- [`bpkg-manifest-reference`](bpkg-manifest-reference.md) -- manifest file format and all supported fields
- [`bpkg-repository-manifest-reference`](bpkg-repository-manifest-reference.md) -- repository, repository list, signature, and package list manifest formats
- [`packaging-guide-summary`](../guides/packaging-guide-summary.md) -- end-to-end guide for packaging a third-party library
- [`multiple-configurations`](../HOWTO/multiple-configurations.md) -- managing debug/release/sanitize configurations with bdep
- [`troubleshooting`](../HOWTO/troubleshooting.md) -- common bpkg error messages and resolutions
