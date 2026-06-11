# bpkg-pkg-status -- print package status

## Synopsis

```
bpkg pkg-status|status [<options>] [<pkg>[/<ver>]...]
```

## Description

The `pkg-status` command prints the status of the specified packages or, if
`<ver>` is specified, package versions. If no packages were specified, then
`pkg-status` prints the status of all the held packages (which are the
packages that were explicitly built, see [bpkg-pkg-build](bpkg-pkg-build.md)).
The latter mode can be modified to print the status of all the packages by
specifying the `--all`|`-a` option. Additionally, the status of immediate or
all dependencies (and dependency constraints) of the above packages can be
printed by specifying the `--immediate`|`-i` or `--recursive`|`-r` options,
respectively. Note that the status is written to `stdout`, not `stderr`.

The default output format (see the `--stdout-format` common option) is regular
with components separated with spaces. Each line starts with the package name
followed by one of the status words listed below. Some of them can be
optionally followed by `,` (no spaces) and a sub-status word. Lines
corresponding to dependencies from linked configurations will additionally
mention the configuration directory in square brackets after the package name.
Lines corresponding to dependency constraints will have the package name
prefixed with `?`.

If the package name was specified without the package version, then the
`available` status word is followed by the list of available versions.
Versions that are only available for up/down-grading are printed in `[]` (such
versions are only available as dependencies from prerequisite repositories of
other repositories). If the `--system` option is specified, then the last
version in this list may have the `sys:` prefix indicating an available system
version. Such a system version may be the special `?` value indicating that a
package may or may not be available from the system and that its version is
unknown.

The `fetched`, `unpacked`, `configured`, and `broken` status words are
followed by the version of the package. If the package version was specified,
then the `unknown` status word is also followed by the version.

If the status is `fetched`, `unpacked`, `configured`, or `broken` and newer
versions are available, then the package version is followed by the
`available` status word and the list of newer versions. To instead see a list
of all versions, including the older ones, specify the `--old-available`|`-o`
option. In this case the currently selected version is printed in `()`.

If the package name was specified with the version, then only the status (such
as `configured`, `available`, etc.) of this version is considered.

If a package is being held, then its name is printed prefixed with `!`.
Similarly, if a package version is being held, then the version is printed
prefixed with `!`. Held packages and held versions were selected by the user
and are not automatically dropped and upgraded, respectively.

## Status Output Format

Each output line has the following general shape:

```
[!]<name> [<config>] <status>[,<sub-status>] [<version>] [available <ver>...]
```

**Status words:**

**`unknown`** -- the package is not part of the configuration nor available
from any of the repositories.

**`available`** -- the package is not part of the configuration but is
available from one of the repositories.

**`fetched`** -- the package is part of the configuration and is fetched.

**`unpacked`** -- the package is part of the configuration and is unpacked.

**`configured`** -- the package is part of the configuration and is
configured. May be followed by the `system` sub-status indicating a package
coming from the system. The version of such a system package may be the
special `*` value indicating a wildcard version.

**`broken`** -- the package is part of the configuration and is broken.
Broken packages can only be purged (see
[bpkg-pkg-purge](bpkg-pkg-purge.md)).

**Examples** (assuming `libfoo` `1.0.0` is configured and held, with `1.1.0`
and `1.1.1` available from source and `1.1.0` from the system):

```
bpkg status libbar
libbar unknown

bpkg status libbar/1.0.0
libbar unknown 1.0.0

bpkg status libfoo/1.0.0
!libfoo configured !1.0.0

bpkg status libfoo/1.1.0
libfoo available 1.1.0

bpkg status --system libfoo/1.1.0
libfoo available 1.1.0 sys:1.1.0

bpkg status libfoo
!libfoo configured !1.0.0 available 1.1.0 1.1.1

bpkg status libfoo/1.1.1 libbar
libfoo available 1.1.1
libbar unknown
```

After dropping `libfoo` from the configuration:

```
bpkg status libfoo/1.0.0
libfoo unknown 1.0.0

bpkg status libfoo
libfoo available 1.1.0 1.1.1
```

After building `libfoo` as a system package with the wildcard version:

```
bpkg status libfoo
!libfoo configured,system !* available 1.1.0 1.1.1
```

Example including dependencies and constraints:

```
bpkg status -r libbaz
!libbaz configured 1.0.0
  libfoo configured 1.0.0
    bison [.bpkg/host/] configured 1.0.0
  libbar configured 2.0.0
  ?bison [.bpkg/host/] configured 1.0.0
```

### JSON Output Format

If the output format is `json` (via `--stdout-format`), the output is a JSON
array of objects serialized from the following structure:

```
struct available_version
{
  string version;
  bool   system;
  bool   dependency;
};

struct package_status
{
  string                    name;
  optional<string>          configuration;
  optional<string>          version_constraint;
  string                    status;
  optional<string>          sub_status;
  optional<string>          version;
  bool                      hold_package;
  bool                      hold_version;
  vector<available_version> available_versions;
  vector<package_status>    dependencies;
  vector<package_status>    constraints;
};
```

Example JSON output:

```json
[
  {
    "name": "hello",
    "status": "configured",
    "version": "1.0.0",
    "hold_package": true,
    "available_versions": [
      {
        "version": "1.0.1"
      },
      {
        "version": "2.0.0"
      }
    ],
    "dependencies": [
      {
        "name": "libhello",
        "status": "configured",
        "version": "1.0.2"
      }
    ]
  }
]
```

In `package_status`, the `configuration` member contains the absolute
directory of a linked configuration if this package resides in a linked
configuration. The `version_constraint` member is present only if the
`--version-constraint` option is specified. The `version` member is absent if
the `status` member is `unknown` or `available` and no package version is
specified on the command line. If the `sub_status` member is `system`, then
the `version` member can be special `*`. The `dependencies` and `constraints`
members are present only if the `--immediate|-i` or `--recursive|-r` options
are specified.

In `available_version`, if the `system` member is `true`, then this version is
available from the system, in which case the `version` member can be special
`?` or `*`. If the `dependency` member is `true`, then this version is only
available as a dependency from prerequisite repositories of other repositories.

See the JSON OUTPUT section in [bpkg-common-options](bpkg-common-options.md)
for details on the overall properties of this format and the semantics of the
struct serialization.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--all`, `-a` | | Print the status of all the packages, not just held. |
| `--link` | | Also print the status of held/all packages from linked configurations. |
| `--immediate`, `-i` | | Also print the status of immediate dependencies and constraints. |
| `--recursive`, `-r` | | Also print the status of all dependencies and constraints, recursively. |
| `--old-available`, `-o` | | Print old available versions. |
| `--version-constraint` | | Print version constraints for dependencies and constraints. |
| `--system` | | Check the availability of packages from the system. |
| `--no-hold` | | Don't print the package or version hold status. |
| `--no-hold-package` | | Don't print the package hold status. |
| `--no-hold-version` | | Don't print the version hold status. |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an
overview of the default options files. For the `pkg-status` command the search
start directory is the configuration directory. The following options files are
searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-pkg-status.options
```

The following `pkg-status` command options cannot be specified in the default
options files:

```
--directory|-d
```

## See Also

- [bpkg README](README.md)
- [bpkg-pkg-build](bpkg-pkg-build.md)
- [bpkg-pkg-purge](bpkg-pkg-purge.md)
- [bpkg-common-options](bpkg-common-options.md)
- [bpkg-default-options-files](bpkg-default-options-files.md)
