# bpkg-pkg-build -- build packages

## Synopsis

```
bpkg pkg-build|build [<options>] [--upgrade|-u | --patch|-p]
                     [<cfg-var>... --] <pkg-spec>...
bpkg pkg-build|build [<options>]  --upgrade|-u | --patch|-p
                     [<cfg-var>... --]
```

```
<pkg-spec> = [<flags>](([<scheme>:]<pkg>[<ver-spec>]),... [@<rep-loc>] |
                        [@]<rep-loc>                                    |
                        <file>                                          |
                        <dir>/)
<flags>    = ?
<scheme>   = sys
<ver-spec> = /<version> | <version-constraint>
```

## Description

`pkg-build` builds one or more packages including all their dependencies.
It also handles upgrades, downgrades, and, unless `--keep-unused|-K` is
specified, drops dependency packages that are no longer needed.

The first form (one or more packages specified) builds, upgrades, or patches
the named packages. The second form (no packages, but `--upgrade` or `--patch`
specified) upgrades or patches all _held_ packages in the configuration.

In both forms, `--immediate|-i` or `--recursive|-r` also upgrades/patches
the immediate or all transitive dependencies respectively. In the first form
these options require an explicit `--upgrade` or `--patch`.

### Specifying packages

**By name:** `pkg-build foo libfoo/1.2.3 "bar < 2.0.0"` -- fetched
automatically from a configured repository. `<ver-spec>` is either an exact
version (`/1.2.3`) or a version constraint. Without `<ver-spec>` the latest
available version is used. Downgrading requires an explicit version.

**By repository location:** the `<rep-loc>` can be included inline. If no
version is specified the latest from that repository is used. If only a
location is given, the latest versions of all packages directly in that
repository are built (complements excluded):

```
bpkg build foo,libfoo/1.2.3@https://git.example.org/foo.git#master
bpkg build https://git.example.org/foo.git#master
bpkg build @/path/to/repository/
```

**By archive or directory:** pass the path to a `.tar.gz` archive (`<file>`)
or to a package source directory (`<dir>/`, note the trailing `/`). See
`bpkg-pkg-fetch` and `bpkg-pkg-unpack` for semantics.

### Hold vs dependency

By default a package specified on the command line is built _to hold_: it will
not be automatically removed if it loses all dependents. Only versions from
repositories added to the configuration are eligible as held packages.

Prefix a package with `?` (the `<flags>` field) or use `--dependency` to
build it as a _dependency_ instead. A dependency package is only kept while
it has dependents and is dropped automatically when it no longer has any.
Only versions from prerequisite repositories of the package's dependents are
eligible.

Packages built with an explicit `<ver-spec>` or as an archive/directory have
their versions _held_: they will not be automatically upgraded.

Example showing hold vs dependency semantics (stable has `foo 1.0.0`,
`libfoo 1.0.0` and `1.1.0`; testing has `libfoo 2.0.0`; `foo` depends on
`libfoo >= 1.0.0`):

```
bpkg fetch https://example.org/1/testing

bpkg build foo            # build foo    1.0.0 to hold
                          # build libfoo 1.1.0 as dependency

bpkg build ?libfoo/1.0.0  # downgrade libfoo 1.0.0 as dependency,
                          #           also hold version 1.0.0

bpkg build ?libfoo/2.0.0  # error: 2.0.0 unavailable in dependent's
                          #        (foo) repository (stable)

bpkg build libfoo/2.0.0   # upgrade libfoo 2.0.0 to hold,
                          #         also hold version 2.0.0
```

### sys: scheme

Prefix a package name with `sys:` to treat it as provided by the system
rather than building from source:

```
bpkg build sys:libssl
bpkg build sys:libssl/1.1.0
bpkg build sys:libssl/*
```

The version may be the special `/*` value, meaning the version is unknown but
satisfies any constraint. Without an explicit version, `pkg-build` queries the
system package manager for the installed version (unless unsupported or
disabled with `--sys-no-query`), falling back to `/*`. Use `--sys-install` to
request automatic installation via the system package manager. A stub package
must exist in a configured repository unless `--sys-no-stub` is used.

### Configuration variables

Additional configuration variables (`<cfg-var>`) apply only during the
configure phase and only to packages explicitly listed on the command line
(unless they are global overrides). They are separated from the package list
with `--`. Use argument grouping to target specific packages:

```
bpkg build { config.foo.debug=true }+ foo bar
```

### Linked configurations

A package can be built in a linked configuration (useful for host or
build-system-module dependencies) by grouping `--config-*` options with the
package:

```
bpkg build foo { --config-name=alt-host }+ ?bison
```

## Package-Level Options

The following options can be grouped to apply to individual `<pkg-spec>`
entries (see [bpkg-argument-grouping](bpkg-argument-grouping.md)) or specified
globally to apply to all.

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|--------|-----|-------------|
| `--upgrade`, `-u` | | Upgrade to the latest available version satisfying all constraints. |
| `--patch`, `-p` | | Upgrade to the latest available patch version satisfying all constraints. |
| `--deorphan` | | Replace orphaned packages (no longer available in their origin repository) with the best matching available version. See version preference order below. |
| `--immediate`, `-i` | | Also upgrade, patch, or deorphan immediate dependencies. |
| `--recursive`, `-r` | | Also upgrade, patch, or deorphan all dependencies recursively. |
| `--upgrade-immediate` | | Upgrade immediate dependencies (independent of what is done to the package itself). |
| `--patch-immediate` | | Patch immediate dependencies. |
| `--deorphan-immediate` | | Deorphan immediate dependencies. |
| `--upgrade-recursive` | | Upgrade all dependencies recursively. |
| `--patch-recursive` | | Patch all dependencies recursively. |
| `--deorphan-recursive` | | Deorphan all dependencies recursively. |
| `--dependency` | | Build as a dependency rather than to hold. Equivalent to the `?` flag prefix. |
| `--keep-out` | | Keep output directories of external packages between upgrades/downgrades. See `bpkg-pkg-disfigure`. |
| `--disfigure` | | Disfigure packages between upgrades/downgrades, forcing a from-scratch reconfiguration. |
| `--checkout-root` | `<dir>` | Check out packages from version control repositories into `<dir>` rather than the configuration directory. See `--output-root` in `bpkg-pkg-checkout`. |
| `--checkout-purge` | | Remove checked out package source directories when packages are purged. See `--output-purge` in `bpkg-pkg-checkout`. |
| `--config-name` | `<name>` | Build this package in the named linked configuration. Repeatable. |
| `--config-id` | `<num>` | Build this package in the linked configuration with the given numeric id. Repeatable. |
| `--config-uuid` | `<uuid>` | Build this package in the linked configuration with the given UUID. Repeatable. |

### --deorphan version preference order

When replacing an orphan without an explicit target version:
1. Same version, revision, and iteration.
2. Latest iteration of same version and revision.
3. Later revision of same version.
4. Later patch of same version.
5. Later minor of same version.
6. Latest available version (including earlier).

## Global Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|--------|-----|-------------|
| `--yes`, `-y` | | Assume yes to all prompts (excludes system package manager prompts -- see `--sys-yes`). |
| `--for`, `-f` | `<operation>` | Use `update-for-<operation>` instead of `update`. Typically `install` or `test`. |
| `--keep-unused`, `-K` | | Don't drop dependency packages that are no longer used. |
| `--update-dependent`, `-U` | | Update without confirmation any dependent packages reconfigured due to dependency changes. |
| `--leave-dependent`, `-L` | | Don't offer to update dependent packages reconfigured due to dependency changes. |
| `--configure-only`, `-c` | | Configure all packages but skip the update step. |
| `--print-only` | | Print the plan to stdout without executing it. |
| `--plan` | `<header>` | Print the plan (even with `--yes`) prefixed by `<header>` (unless empty). |
| `--no-fetch` | | Don't fetch repositories specified as part of this build command. |
| `--fetch-shallow` | | Don't re-fetch complement/prerequisite repositories of repositories specified in this command. See `--shallow` in `bpkg-rep-fetch`. |
| `--mask-repository` | `<rep>` | Pretend the named or located repository was removed for the duration of this command. Recursively masks its complements/prerequisites unless reachable from unmasked repositories. Repeatable. |
| `--mask-repository-uuid` | `<uuid>=<rep>` | Like `--mask-repository` but scoped to a specific configuration identified by UUID. Repeatable. |
| `--no-refinement` | | Don't offer to drop unused dependencies left behind by a previous command when this command would otherwise be a no-op. |
| `--no-move` | | Don't move dependency packages between configurations. `--config-*` options then specify current rather than new locations. |
| `--noop-exit` | `<code>` | Exit with `<code>` if the command is a no-op (no builds, upgrades, etc. performed). |
| `--rebuild-checksum` | `<sum>` | Hash names, versions, and configurations of all packages that would be built. Exit without building if the checksum matches `<sum>` (using `--noop-exit` code if set). Always prints the resulting checksum to stdout. |
| `--no-private-config` | `<code>` | If no suitable linked configuration exists for a build-time dependency, exit with `<code>` and print the dependency chain to stdout instead of creating a private configuration automatically. |
| `--sys-no-query` | | Don't query the system package manager for versions of `sys:`-scheme packages. |
| `--sys-install` | | Instruct the system package manager to install `sys:`-scheme packages that are not yet installed. See also `--sys-no-fetch`, `--sys-yes`, `--sys-sudo`. |
| `--sys-no-fetch` | | Don't fetch system package manager metadata before querying. Only meaningful with `--sys-install`. |
| `--sys-no-stub` | | Don't require a stub for `sys:`-scheme packages. Effective only when system package manager interactions are supported and enabled. |
| `--sys-yes` | | Assume yes to system package manager prompts. Use only on throw-away setups -- this may modify your system. |
| `--sys-sudo` | `<prog>` | The sudo program for system package manager operations requiring elevated privileges. Default: `sudo`. Pass empty string or `false` to disable. Normally only needed with `--sys-install`. |
| `--sys-distribution` | `<name>` | Alternative system package manager to use. Valid values: `debian` (Debian, Ubuntu, etc.), `fedora` (Fedora, RHEL, CentOS, etc.). |
| `--sys-architecture` | `<name>` | Alternative architecture for system package manager queries. Default: host architecture. Valid values are distribution-specific. |
| `--directory`, `-d` | `<dir>` | Configuration directory. Repeatable for multiple configurations (need not be in the same linked cluster). |

## Default Options Files

Search start directory: the configuration directory. Files loaded in order:

```
bpkg.options
bpkg-pkg-build.options
```

`--directory|-d` cannot be specified in default options files.

## See Also

- [bpkg SUMMARY](SUMMARY.md)
- [bpkg-argument-grouping](bpkg-argument-grouping.md)
- [bpkg-pkg-status](bpkg-pkg-status.md)
- [bpkg-pkg-drop](bpkg-pkg-drop.md)
- [bpkg-pkg-checkout](bpkg-pkg-checkout.md)
- [bpkg-rep-fetch](bpkg-rep-fetch.md)
- [bpkg-cfg-create](bpkg-cfg-create.md)
