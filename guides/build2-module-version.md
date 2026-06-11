# build2 version Module

The `version` module automates version management for projects that use the
build2 standard version format (based on Semantic Versioning). It reads the
version from the project `manifest` file, parses it into individual components,
and exposes them as build system variables. It also extracts snapshot
information from `git` automatically when the version string ends with `.z`.

Additional responsibilities include: checking the `build2` version requirement
from the manifest, installing the manifest as documentation, and providing a
rule (based on the `in` module) for generating version headers or similar
files from templates.

See [build2-modules-core.md](build2-modules-core.md) for the `config`, `test`,
and `install` modules.

## Enabling

Load in `build/bootstrap.build` (must be the first module loaded, before
`config`):

```
using version
```

Loading `version` in subprojects (for example, `tests/`) without their own
manifest causes the module to load the amalgamating project's manifest, which
also performs the build2 version requirement check.

## Standard Version Format

```
<major>.<minor>.<patch>[-<prerel>]
```

Pre-release forms:

```
1.2.3-a.1      # alpha pre-release
1.2.3-b.2      # beta pre-release
1.2.3-a.1.z    # latest/uncommitted snapshot (z = latest)
1.2.3-a.1.20180319215815.26efe301f4a7  # committed snapshot
```

Package version (adds epoch and revision):

```
[+<epoch>-]<major>.<minor>.<patch>[-<prerel>][+<revision>]
```

## Key Variables

All variables are set by the module after loading. They are read-only
and derived from the project manifest.

| Variable | Type | Description |
|---|---|---|
| `version` | string | Full package version string including epoch and revision. |
| `version.project` | string | Project version string without epoch or revision. |
| `version.project_number` | uint64 | Integer representation of the project version for use in preprocessor macros. |
| `version.project_id` | string | Version string with snapshot id but without snapshot sequence number. |
| `version.stub` | bool | `true` if the version is a stub (`0` or `0+<revision>`). |
| `version.epoch` | uint64 | Version epoch number. |
| `version.major` | uint64 | Major version component. |
| `version.minor` | uint64 | Minor version component. |
| `version.patch` | uint64 | Patch version component. |
| `version.alpha` | bool | `true` if this is an alpha pre-release. |
| `version.beta` | bool | `true` if this is a beta pre-release. |
| `version.pre_release` | bool | `true` if this is any pre-release. |
| `version.pre_release_string` | string | Pre-release string, for example `b.4`. |
| `version.pre_release_number` | uint64 | Pre-release number. |
| `version.snapshot` | bool | `true` if this is a snapshot version. |
| `version.snapshot_sn` | uint64 | Snapshot sequence number (commit date in YYYYMMDDhhmmss form). |
| `version.snapshot_id` | string | Snapshot id (abbreviated commit hash). |
| `version.snapshot_string` | string | Combined snapshot string, for example `1234567.deadbeef`. |
| `version.snapshot_committed` | bool | `true` if the snapshot corresponds to a clean, committed state. |
| `version.revision` | uint64 | Package revision number. |
| `project.summary` | string | Value of the `summary` field from the manifest. |
| `project.url` | string | Value of the `url` field from the manifest. |

## Integer Version Representation

The project version without snapshot information is encoded as a 19-digit
decimal integer comparable with `<`, `>=`, etc. in preprocessor directives:

```
AAAAABBBBBCCCCCDDDE

AAAAA - major
BBBBB - minor
CCCCC - patch
DDD   - alpha number, or beta number + 500
E     - final (0) or snapshot (1)
```

If `DDDE` is non-zero, one is subtracted from `AAAAABBBBBCCCCC`.

Examples:

```
             AAAAABBBBBCCCCCDDDE
0.1.0        0000000001000000000
1.2.3        0000100002000030000
2.2.0-a.1    0000200001999990010
2.2.0-a.1.z  0000200001999990011
```

## Snapshot Versions

For snapshot versions (version ends with `.z`), the module queries `git` to
populate `version.snapshot_sn` and `version.snapshot_id`:

- Clean working tree: uses HEAD commit date (YYYYMMDDhhmmss UTC) and
  abbreviated commit hash.
- Dirty working tree: uses HEAD commit date plus one second, no id.
- No commits yet: uses `19700101000000` (UNIX epoch).

When preparing a source distribution of a snapshot, the manifest is patched
with the resolved snapshot number and id, replacing `.z`.

## Version Header Generation

The `version` module provides a rule that generates a file from a `.in`
template. The rule matches a `file{}`-based target that has an `in{}`
prerequisite and also depends on the project manifest:

```
lib{hello}: {hxx cxx}{** -version} hxx{version}

hxx{version}: in{version} $src_root/file{manifest}
```

Inside the template (`version.hxx.in`), substitutions use `$...$` syntax.
The first component after the opening `$` must be the project name or a
dependency name from the manifest:

```
#define LIBHELLO_VERSION     $libhello.version.project_number$ULL
#define LIBHELLO_VERSION_STR "$libhello.version.project$"
```

For dependencies, special substitution forms are available:

```
$<name>.version$                           # textual version constraint
$<name>.condition(<VERSION>[,<SNAPSHOT>])$ # numeric satisfaction condition
$<name>.check(<VERSION>[,<SNAPSHOT>])$     # numeric satisfaction check
```

The `check` substitution generates a `#error` directive when the version
requirement is not met. The `condition` substitution gives the raw numeric
expression for custom error messages.

## Usage Examples

Typical `bootstrap.build` for a versioned project:

```
project = hello

using version
using config
using test
using install
```

Use version components in a buildfile:

```
cxx.poptions += "-DHELLO_VERSION=$version.project_number$ULL"
```

Check build2 version from manifest automatically:

```
# manifest
depends: * build2 >= 0.13.0
```

Generate a version header with a dependency check:

```
# version.hxx.in

#define LIBHELLO_VERSION     $libhello.version.project_number$ULL
#define LIBHELLO_VERSION_STR "$libhello.version.project$"

#include <libprint/version.hxx>

$libprint.check(LIBPRINT_VERSION)$
```

Dependency version constraint in manifest:

```
depends: libprint ^2.3.0
```

## See Also

- [build2 core modules: config, test, install](build2-modules-core.md)
- [build2 misc modules](build2-modules-misc.md)
