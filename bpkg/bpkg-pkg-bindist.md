# bpkg-pkg-bindist -- create binary distribution package

## Synopsis

```
bpkg pkg-bindist|bindist [--output-root|-o <dir>] [<options>] [<vars>] <pkg>...
```

## Description

The `pkg-bindist` command generates a binary distribution package for the
specified package. If additional packages are specified, then they are bundled
in the same distribution package. All the specified packages must have been
previously configured with `bpkg-pkg-build` or `bpkg-pkg-configure`. For some
system package managers a directory for intermediate files and subdirectories
as well as the resulting binary package may have to be specified explicitly with
the `--output-root|-o` option.

Underneath, this command roughly performs the following steps. First it installs
the specified packages similar to the `bpkg-pkg-install` command except that it
may override the installation locations (via the `config.install.*` variables)
to match the distribution's layout. Then it generates any necessary distribution
package metadata files based on the information from the package `manifest`
files. Finally, it invokes the distribution-specific command to produce the
binary package. Unless overridden with the `--architecture` and `--distribution`
options, the binary package is generated for the host architecture using the
host's standard system package manager. Additional command line variables
(`<vars>`, normally `config.*`) can be passed to the build system during the
installation step.

The specified packages may have dependencies and the default behavior is to not
bundle them but rather to specify them as dependencies in the corresponding
distribution package metadata, if applicable. This default behavior can be
overridden with the `--recursive` option (see the option description for the
available modes). Note, however, that dependencies that are satisfied by system
packages are always specified as dependencies in the distribution package
metadata (if applicable).

## Supported Distribution Formats

| Format | Name value | Description |
|--------|-----------|-------------|
| `debian` | `debian` | Debian and alike (Ubuntu, etc.) -- produces `.deb` packages via `dpkg-buildpackage` |
| `fedora` | `fedora` | Fedora and alike (RHEL, CentOS, etc.) -- produces `.rpm` packages via `rpmbuild` |
| `archive` | `archive` | Installation archive on any OS -- produces `tar.xz`, `tar.gz`, `zip`, etc. via `tar`/`zip` |

## Options

Note: also see [common options](bpkg-common-options.md).

### General Options

| Option | Arg | Description |
|--------|-----|-------------|
| `--distribution` | `<name>` | Alternative system/distribution package manager to generate the binary package for. Valid values: `debian`, `fedora`, `archive`. Some managers may only be supported on certain host operating systems. |
| `--architecture` | `<name>` | Alternative architecture to generate the binary package for. Valid values are system/distribution package manager-specific. If unspecified, the host architecture is used. |
| `--recursive` | `<mode>` | Bundle or generate dependencies of the specified packages. `auto` -- only required files from each dependency are bundled (pulled implicitly by the `install` operation). `full` -- all files of each dependency are bundled explicitly as if specified on the command line. `separate` -- a separate binary package is generated for each non-system dependency (equivalent to invoking `pkg-bindist` on each). `none` -- equivalent to not specifying this option. The mode value can also be prefixed with a package name in the `[?]pkg=mode` form to specify the mode per-package: if the name starts with `?`, the mode applies to the package itself; otherwise it applies only to that package's dependencies recursively. |
| `--private` | | Enable the private installation subdirectory using the package name as the subdirectory. Primarily useful when bundling shared library dependencies of an executable into a shared location such as `/usr/`. Requires `--recursive` `auto` or `full` mode. See `config.install.private` in the build system manual. |
| `--output-root`, `-o` | `<dir>` | Directory for intermediate files and subdirectories as well as the resulting binary package. May be required for some package managers and may not be specified for others. |
| `--wipe-output` | | Wipe the output root directory clean before using it to generate the binary package. |
| `--keep-output` | | Keep intermediate files in the output root directory after generating the binary package. Primarily useful for troubleshooting. |
| `--allow-dependent-config` | | Allow configuration imposed by dependent packages. Normally undesirable because the resulting binary packages become configured specifically for particular dependent packages. |
| `--os-release-id` | `<v>` | Override the `ID` component in `os-release(5)` or equivalent. Unlike the other `--os-release-*` options, this suppresses automatic detection of host operating system information. |
| `--os-release-version-id` | `<v>` | Override the `VERSION_ID` component in `os-release(5)` or equivalent. |
| `--os-release-name` | `<v>` | Override the `NAME` component in `os-release(5)` or equivalent. |

### Debian-specific Options

| Option | Arg | Description |
|--------|-----|-------------|
| `--debian-prepare-only` | | Prepare all package metadata files (`control`, `rules`, etc) but do not invoke `dpkg-buildpackage`. Prints the command line unless quiet. Implies `--keep-output`. |
| `--debian-buildflags` | `<mode>` | `dpkg-buildflags` usage mode. `assign` (default) -- use build flags instead of configured. `append` -- use build flags in addition to configured, putting them last. `prepend` -- use build flags in addition to configured, putting them first. `ignore` -- ignore build flags. Compiler mode options are always used as configured. |
| `--debian-maint-option` | `<o>` | Alternative options for the `DEB_BUILD_MAINT_OPTIONS` variable in the `rules` file. Repeat or separate with spaces for multiple values. |
| `--debian-build-option` | `<o>` | Additional option to pass to `dpkg-buildpackage`. Repeat for multiple options. |
| `--debian-build-meta` | `<data>` | Alternative or additional build metadata in the binary package version. A leading/trailing `+` adds the value after/before the default metadata. Empty value suppresses all build metadata. Default is the `ID` and `VERSION_ID` from `os-release(5)`, for example `debian10` in version `1.2.3-0~debian10`. See also `--os-release-*`. |
| `--debian-section` | `<v>` | Alternative `Section` control file field value for the main binary package. Default is `libs` or `devel` depending on package type. |
| `--debian-priority` | `<v>` | Alternative `Priority` control file field value. Default is `optional`. |
| `--debian-maintainer` | `<v>` | Alternative `Maintainer` control file field value. Default is the `package-email` value from package `manifest`. |
| `--debian-architecture` | `<v>` | Alternative `Architecture` control file field value for the main binary package, normally `all` for architecture-independent packages. Default is `any` (architecture-dependent). |
| `--debian-main-langdep` | `<v>` | Override the language runtime dependencies (such as `libc6`, `libstdc++6`, etc) in the `Depends` field of the main binary package. |
| `--debian-dev-langdep` | `<v>` | Override the language runtime dependencies (such as `libc-dev`, `libstdc++-dev`, etc) in the `Depends` field of the development (`-dev`) binary package. |
| `--debian-main-extradep` | `<v>` | Extra dependencies to add to the `Depends` field of the main binary package. |
| `--debian-dev-extradep` | `<v>` | Extra dependencies to add to the `Depends` field of the development (`-dev`) binary package. |
| `--debian-no-debug` | | Do not generate the debug information (`-dbgsym`) binary package. |

### Fedora-specific Options

| Option | Arg | Description |
|--------|-----|-------------|
| `--fedora-prepare-only` | | Prepare the RPM spec file but do not invoke `rpmbuild`. Prints the command line unless quiet. |
| `--fedora-buildflags` | `<mode>` | `%{build_*flags}` macros usage mode. `assign` (default) -- use build flags instead of configured. `append` -- use build flags in addition to configured, putting them last. `prepend` -- use build flags in addition to configured, putting them first. `ignore` -- ignore build flags. Compiler mode options are always used as configured. |
| `--fedora-build-option` | `<o>` | Additional option to pass to `rpmbuild`. Must be consistent with `--fedora-query-option` to produce identical macro expansions. Repeat for multiple options. |
| `--fedora-query-option` | `<o>` | Additional option to pass to the `rpm` program (used to query RPM macro values). Must be consistent with `--fedora-build-option` to produce identical macro expansions. Repeat for multiple options. |
| `--fedora-dist-tag` | `<tag>` | Alternative or additional distribution tag in the binary package release. A leading/trailing `+` adds the value after/before the default tag. Empty value suppresses the distribution tag. Default identifies the distribution, for example `fc35` for Fedora 35 or `el8` for RHEL 8. |
| `--fedora-packager` | `<v>` | Alternative `Packager` RPM spec file directive value. Default is the `package-email` value from package `manifest`. Empty value omits the directive. |
| `--fedora-build-arch` | `<v>` | `BuildArch` RPM spec file directive value for the main binary package, normally `noarch` for architecture-independent packages. Omitted by default (package assumed architecture-dependent). |
| `--fedora-main-langreq` | `<v>` | Override the language runtime dependencies (such as `glibc`, `libstdc++`, etc) of the main binary package by replacing the corresponding `Requires` directives. Empty value specifies no language runtime dependencies. Repeat for multiple values. |
| `--fedora-devel-langreq` | `<v>` | Override the language runtime dependencies (such as `glibc-devel`, `libstdc++-devel`, etc) of the development (`-devel`) binary package. Empty value specifies no language runtime dependencies. Repeat for multiple values. |
| `--fedora-stat-langreq` | `<v>` | Override the language runtime dependencies (such as `glibc-static`, `libstdc++-static`, etc) of the static libraries (`-static`) binary package. Empty value specifies no language runtime dependencies. Repeat for multiple values. |
| `--fedora-main-extrareq` | `<v>` | Extra dependency to add to the main binary package as an additional `Requires` directive. Repeat for multiple values. |
| `--fedora-devel-extrareq` | `<v>` | Extra dependency to add to the development (`-devel`) binary package as an additional `Requires` directive. Repeat for multiple values. |
| `--fedora-stat-extrareq` | `<v>` | Extra dependency to add to the static libraries (`-static`) binary package as an additional `Requires` directive. Repeat for multiple values. |
| `--fedora-no-debug` | | Do not generate the debug information (`-debuginfo`) binary package. |

### Archive-specific Options

| Option | Arg | Description |
|--------|-----|-------------|
| `--archive-prepare-only` | | Prepare all package contents but do not create the binary package archive. Prints its directory unless quiet. Implies `--keep-output`. |
| `--archive-type` | `<ext>` | Archive type to create, specified as a file extension: `tar.xz`, `tar.gz`, `tar`, `zip`. Repeat for multiple archive types. Default is `zip` on Windows and `tar.xz` on POSIX. |
| `--archive-lang` | `<ln>=<rt>` | Map interface language name `<ln>` to runtime id `<rt>`. Falls back to `--archive-lang-impl` if not found here. Fails if still not found. An empty `<rt>` ignores that language. Only considered for library packages (all languages are implementation for other types). Multiple ids for the same language are combined; an empty id clears previous entries. |
| `--archive-lang-impl` | `<ln>=<rt>` | Map implementation language name `<ln>` to runtime id `<rt>`. If no mapping is found, the implementation language is silently ignored (suitable for statically-linked or always-present runtimes). |
| `--archive-no-cpu` | | Assume the package is CPU architecture-independent and omit the CPU from the binary package directory name and archive file base. |
| `--archive-no-os` | | Assume the package is operating system-independent and omit the OS from the binary package directory name and archive file base. |
| `--archive-build-meta` | `<data>` | Alternative or additional build metadata appended after the version in directory and file names. A leading/trailing `+` adds the value after/before the default metadata. Empty value suppresses all build metadata. |
| `--archive-install-root` | `<d>` | Alternative installation root directory. Default is `/usr/local/` on POSIX and `C:\<project>\` on Windows, where `<project>` is the `project` package manifest value. |
| `--archive-install-config` | | Use the installation directory layout (`config.install.*` variables) as configured rather than overriding them with OS-appropriate defaults. The `config.install.root` value is still overridden by `--archive-install-root` if specified. |
| `--archive-strip-comps` | `<num>` | Number of leftmost directory components to strip from the installation root directory path before archiving. Does not affect `config.install.root`. Alters the top-level layout inside the archive. Should normally only be used with a relocatable installation. |
| `--archive-split` | `<key>=<filt>` | Split the installation into multiple binary packages. For each `<key>=<filt>` pair, run `install` with `config.install.filter=<filt>` and package the result as `<package>-<key>-<version>-<build_metadata>` (the `-<key>` part is omitted if `<key>` is empty). Wildcard patterns in `<filt>` must be quoted. |

## Distribution Mapping

### Debian

The binary package names and versions are derived from the bpkg package
`manifest` as follows. For a library package `libfoo` at version `1.2.3`, the
command produces:

- `libfoo` -- the main runtime binary package (shared libraries, executables)
- `libfoo-dev` -- the development package (headers, static libraries, pkg-config files)
- `libfoo-doc` -- the documentation package (if documentation is installed)
- `libfoo-common` -- the architecture-independent data package
- `libfoo-dbgsym` -- the debug symbols package (unless `--debian-no-debug`)

The Debian package version is derived from the bpkg version with a release
suffix encoding the OS, for example `1.2.3-0~debian11`. The `~` character
causes pre-release versions to sort below the release in Debian's version
ordering.

By default, dependencies are expressed as references to non-native packages
(those that would be generated by `pkg-bindist`). To have a dependency resolve
to a distribution-provided native package, build the dependency as a system
package:

```
bpkg build --sys-install libhello ?sys:libsqlite3
```

Install the resulting `.deb` files (including any missing native dependencies)
with:

```
sudo apt-get install ./libhello_1.2.3-0~debian11_amd64.deb \
                     ./libhello-dev_1.2.3-0~debian11_amd64.deb
```

### Fedora

For a library package `libfoo` at version `1.2.3`, the command produces:

- `libfoo` -- the main runtime package
- `libfoo-devel` -- the development package
- `libfoo-static` -- the static libraries package
- `libfoo-doc` -- the documentation package
- `libfoo-common` -- the architecture-independent data package
- `libfoo-debuginfo` -- the debug information package (unless `--fedora-no-debug`)

The RPM release field encodes the distribution tag, for example `1.fc35` for
Fedora 35 or `1.el8` for RHEL 8.

The resulting packages are placed in the standard `rpmbuild` output directory,
normally `~/rpmbuild/RPMS/<arch>/`. Install with:

```
sudo dnf install libhello-1.2.3-1.fc35.x86_64.rpm \
                 libhello-devel-1.2.3-1.fc35.x86_64.rpm
```

### Archive

The binary package directory (and archive file base) has the form:

```
<package>-<version>-<build_metadata>
```

Where `<build_metadata>` defaults to `<cpu>-<os>[-<langrt>...]`, for example
`x86_64-debian11-gcc12`. The OS part is taken from `os-release(5)` ID and
VERSION_ID fields. Language runtimes are mapped via `--archive-lang` and
`--archive-lang-impl`.

Example producing `libhello-1.2.3-x86_64-debian11-gcc12.tar.xz`:

```
bpkg build libhello
bpkg test libhello
bpkg bindist              \
  -o /tmp/output/         \
  --distribution=archive  \
  --archive-lang cc=gcc12 \
  libhello
```

To unpack into `/usr/local/`:

```
sudo tar -xf libhello-1.2.3-x86_64-debian11-gcc12.tar.xz \
  -C / --strip-components=1
```

For a relocatable installation (recommended when the unpack destination may
differ from the original install root), pass
`config.install.relocatable=true` as a `<vars>` argument.

Cross-compilation example (Linux host to Windows target using MinGW):

```
bpkg bindist                        \
  --distribution=archive            \
  --architecture=x86_64-w64-mingw32 \
  --os-release-id=windows           \
  --os-release-name=Windows         \
  --os-release-version-id=10        \
  --archive-install-root /          \
  --archive-lang cc=mingw_w64_gcc12 \
  ...
```

## Structured Result

When the `--structured-result=json` common option is specified, the command
writes a JSON object to `stdout` instead of printing human-readable output to
`stderr`. The object is a serialization of the following structure:

```
struct os_release
{
  string           name_id;           // ID
  vector<string>   like_ids;          // ID_LIKE
  optional<string> version_id;        // VERSION_ID
  optional<string> variant_id;        // VARIANT_ID
  optional<string> name;              // NAME
  optional<string> version_codename;  // VERSION_CODENAME
  optional<string> variant;           // VARIANT
};

struct file
{
  string           type;
  string           path;
  optional<string> system_name;
};

struct package
{
  string           name;
  string           version;
  optional<string> system_version;
  vector<file>     files;
};

struct bindist_result
{
  string           distribution;     // --distribution or auto-detected
  string           architecture;     // --architecture or auto-detected
  os_release       os_release;       // --os-release-* or auto-detected
  optional<string> recursive;        // --recursive
  bool             private;          // --private
  bool             dependent_config; // see --allow-dependent-config

  package          package;
  vector<package>  dependencies;     // only present with --recursive=separate
};
```

The `file::type` member is distribution-specific:

- **debian**: `main.deb`, `dev.deb`, `doc.deb`, `common.deb`, `dbgsym.deb`, `changes`, `buildid`
- **fedora**: `main.rpm`, `devel.rpm`, `static.rpm`, `doc.rpm`, `common.rpm`, `debuginfo.rpm`
- **archive**: the archive type extension (e.g. `tar.xz`, `zip`), optionally prefixed with the split key (e.g. `dev.tar.xz`)

The `package::system_version` and `file::system_name` members are absent if not
applicable to the distribution. `file::system_name` is also absent for non-package
files such as `.changes` and `.buildid` in the `debian` distribution.

## Default Options Files

See `bpkg-default-options-files` for an overview. For `pkg-bindist` the search
starts from the configuration directory. The following files are searched for
in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-pkg-bindist.options
```

The following option cannot be specified in default options files:

```
--directory|-d
```

## See Also

- [bpkg README](README.md)
- [bpkg-pkg-install](bpkg-pkg-install.md)
- [bpkg-pkg-build](bpkg-pkg-build.md)
- [bpkg-common-options](bpkg-common-options.md)
- [`packaging-guide-summary`](../guides/packaging-guide-summary.md) -- end-to-end packaging guide including publish steps
- [`packaging-guide-testing`](../guides/packaging-guide-testing.md) -- testing and publishing to cppget.org
- [`packaging-guide-version-management`](../guides/packaging-guide-version-management.md) -- new revision and version bump workflows
- [`packaging-guide-review`](../guides/packaging-guide-review.md) -- review checklist and process
