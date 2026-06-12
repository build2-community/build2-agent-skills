# bpkg -- Package Name, Version, and Constraints

This guide covers the rules governing package names, the full bpkg version
format and its comparison semantics, version constraint syntax including the
`~` and `^` shortcut operators and the `$` incomplete constraint, and the
package build system skeleton. For the manifest fields that carry these
values see [bpkg-manifest-reference.md](../bpkg/bpkg-manifest-reference.md).


## Package Name

A bpkg package name may contain:

- ASCII alphabetic characters (`[a-zA-Z]`)
- Digits (`[0-9]`)
- Underscores (`_`)
- Plus and minus characters (`+-`)
- Dots/periods (`.`)

The name must be at least two characters long with these additional rules:

1. It must start with an alphabetic character.
2. It must end with an alphabetic character, a digit, or a `+` character.
3. It must not be any of the following reserved names:

```
build
con prn aux nul
com1 com2 com3 com4 com5 com6 com7 com8 com9
lpt1 lpt2 lpt3 lpt4 lpt5 lpt6 lpt7 lpt8 lpt9
```

The reserved names listed above are Windows device names and are excluded to
ensure the package name can always be used as a file system path component.

### Discouraged Characters

The `+` character is discouraged in package names because plus signs are
encoded in URLs, making it cumbersome to reference such packages in repository
URLs.

The `.` character is discouraged except when distinguishing implementations of
the same functionality for different languages. For example, `libfoo` is the
C++ implementation and `libfoo.bash` is the Bash implementation.

### Case Sensitivity

Package name comparison is case-insensitive, but the original case must be
preserved for display purposes and in file names. The reason for
case-insensitive comparison is Windows file system behaviour.

### Library Naming Convention

If a package is a library, it is strongly recommended to start its name with
the `lib` prefix, for example `libfoo`. Some package repositories enforce this
as a submission requirement.

If a library supports multiple incompatible major versions in use within the
same project, it is recommended to append the major version number to the
package name starting from version `2.0.0`. For example:

- `libfoo` -- used before `2.0.0`
- `libfoo2` -- used for the `2.Y.Z` series
- `libfoo3` -- used for the `3.Y.Z` series


## Package Version

The full bpkg version format is:

```
[+<epoch>-]<upstream>[-<prerel>][+<revision>][#<iteration>]
```

If you are starting a new project with the build2 toolchain, use the standard
versioning scheme (a strictly defined subset of semantic versioning) rather
than the general format. Standard versioning enables automation of version
management tasks. See [build2-module-version.md](build2-module-version.md)
for details.

### Components

**Epoch**

The epoch must be an integer. It allows switching to a new versioning scheme
that would sort incompatibly with the old one. If not specified, the epoch
defaults to `1`, except for a stub version (see below) where it defaults to
`0`. Specifying epoch `0` explicitly signals that the current versioning scheme
(for example, date-based) is known to be temporary.

**Upstream**

The upstream part is the upstream software version the package is based on. It
may only contain alphanumeric characters and `.`. The `.` character separates
the version into components.

**Prerel**

The prerel part is the upstream pre-release marker (alpha, beta, release
candidate, etc.) with the same format as upstream. Two special values exist:

- Absent prerel (for example `1.2.3`) signifies the maximum or final release.
- Empty prerel (for example `1.2.3-`) signifies the minimum or earliest
  possible release. This form is intended for use in version constraints (for
  example `libfoo < 1.2.3-`) rather than actual releases.

**Revision**

The revision must be an integer. It is used to version package releases that
are based on the same upstream version. If not specified, revision defaults to
`0`.

**Iteration**

The iteration is an integer managed internally by `bpkg`. It automatically
versions modifications to packaging information (package manifest and
lockfile) in external packages that share the same upstream version and
revision. The iteration cannot be set by the user. It appears in `bpkg` output
(for example, the `pkg-status` command) to distinguish between otherwise
identical versions. The iteration is relative to the `bpkg` configuration, so
two configurations can observe the same package state as two different
iterations.

Package iterations support package development without requiring the developer
to manually increment the version or revision after each modification to the
packaging information. The mechanism is analogous to automatic commit
versioning provided by the standard version module, but limited to packaging
information and applicable even to uncommitted changes.

### Reserved and Special Versions

Version `+0-0-` (the least possible version) is reserved. Specifying it
explicitly is illegal. Internally it is used as a special empty-version
sentinel.

Version `0` (with an optional revision such as `0+1` or `0+2`) is a **stub
package**: a package containing no source code that can only be satisfied by
an external source such as a system package manager. At some point a stub may
be converted into a full-fledged package, at which point it receives a real
version that is always greater than any stub version. The epoch of a stub
defaults to `0`.

### Display and File Naming

When displaying the package version or deriving a file name from it, the
default epoch value, zero revision, and zero iteration are omitted even if
they were explicitly specified in the manifest. For example, `+1-1.2.3+0`
is rendered as `1.2.3` and `libfoo-1.2.3` as the archive name.

### Version Examples

```
0+1
+0-20180112
1.2.3
1.2.3-a1
1.2.3-b2
1.2.3-rc1
1.2.3-alpha1
1.2.3-alpha.1
1.2.3-beta.1
1.2.3+1
+2-1.2.3
+2-1.2.3-alpha.1+3
+2.2.3#1
1.2.3+1#1
+2-1.2.3+1#2
```

### Comparison Semantics

Versions are sorted by epoch, then upstream, then prerel, then revision, then
iteration. The upstream and prerel parts are compared left to right, one
component at a time.

To compare two components, the type of each is determined first. A component
consisting entirely of digits is an integer. Otherwise it is a string. Two
integer components are compared numerically. Otherwise they are compared
lexicographically and case-insensitively (for Windows file name compatibility).

A non-existent component is treated as `0` if the other component is an
integer, or as an empty string if the other component is a string. For
example, in `1.2` vs `1.2.0`, the missing third component equals `0` and the
two versions are equal.

As a special exception, an absent prerel is always greater than any
non-absent prerel, ensuring the final release sorts above any pre-release of
the same upstream version.

This algorithm produces correct ordering for most common versioning schemes:

```
1.2.3 < 12.2
1.alpha < 1.beta
20151128 < 20151228
2015.11.28 < 2015.12.28
```

One notable scheme where this does not give the correct result is hex numbers
(consider `A` vs `1A`). The simplest workaround is to convert hex numbers to
decimal, or to use zero-padded fixed-width hex values such as `00A` vs `01A`.

### Canonical Representation

The upstream and prerel parts can be converted to a canonical representation
that allows correct ordering when compared lexicographically and as a whole
(useful when storing versions in a database without a custom collation).

To canonicalize one of these parts, all string components are converted to
lower case and all integer components are zero-padded to exactly 16 characters,
with all trailing zero-only components removed. The 16-character limit was
chosen to accommodate components in `YYYYMMDDhhmmss` form with room to spare.

As special cases:

- The absent prerel is represented as `~` (ASCII value greater than any
  character appearing in prerel, so the string always sorts last).
- The empty prerel is represented as an empty string.

Note that reverse conversion is not possible without potential loss (consider
`01.AA.BB`), so the original parts must also be stored when needed for display
or for deriving package archive names.


## Package Version Constraint

A version constraint may follow a package name in manifest fields and on the
`bpkg` command line to restrict the set of allowed versions.

### Syntax

```
<version-constraint> = <comparison> | <shortcut> | <range>
<comparison>         = ('==' | '>' | '<' | '>=' | '<=') <version>
<shortcut>           = ('^' | '~') <version>
<range>              = ('(' | '[') <version> <version> (')' | ']')
```

In ranges, `[` and `]` are inclusive bounds and `(` and `)` are exclusive
bounds.

### Comparison Operators

The comparison operators `==`, `>`, `<`, `>=`, and `<=` each take a single
concrete version and select packages whose version satisfies the relation.

### Range Operator

A range constraint specifies a lower and upper bound. For example:

```
[1.2.0 2.0.0)
```

This matches any version from `1.2.0` (inclusive) up to but not including
`2.0.0`.

### Shortcut Operators

The shortcut operators `~` (tilde) and `^` (caret) may only be used with
standard versions (a semantic version without a pre-release part is a standard
version). They expand to the following ranges, where `X.Y.Z-` denotes the
earliest possible pre-release of `X.Y.Z`:

```
~X.Y.Z  [X.Y.Z  X.Y+1.0-)
^X.Y.Z  [X.Y.Z  X+1.0.0-)    when X > 0
^0.Y.Z  [0.Y.Z  0.Y+1.0-)    when X == 0
```

The tilde allows upgrades to any further patch version. The caret also allows
upgrades to any further minor version, making it equivalent to tilde when the
major version is zero (following the convention that zero-major versions treat
minor as major during early development).

The shortcut operators require the full three-component `X.Y.Z` form. There
is no support for two-component `^X.Y` or one-component `~X` semantics. Where
that functionality is needed, use explicit ranges.

Pre-releases work naturally with shortcut operators. For example, if a package
is usable starting with the second beta of `2.0.0`:

```
libfoo ^2.0.0-b.2
```

### Incomplete Version Constraint (`$`)

Instead of a concrete version, the constraint version may be specified as `$`
to represent the version of the dependent package (the package placing the
constraint), ignoring its revision. A constraint containing `$` is called
incomplete. This mechanism is primarily useful when developing related packages
that must track each other's versions exactly or closely.

```
libfoo == $
```

In comparison operators and explicit ranges, `$` is simply replaced with the
dependent's version (revision excluded).

For shortcut operators, the dependent version must be a standard version. The
expansion depends on the nature of the dependent version:

**Release version** (`1.2.1`): the min version patch is set to zero, and for
`^` the minor version is also set to zero unless the major is zero (which
reduces to `~` semantics). The max version follows standard shortcut logic:

```
~$:  1.2.0 -> [1.2.0 1.3.0-)
     1.2.1 -> [1.2.0 1.3.0-)
     1.2.2 -> [1.2.0 1.3.0-)

^$:  1.0.0 -> [1.0.0 2.0.0-)
     1.1.1 -> [1.0.0 2.0.0-)
```

**Final pre-release version**: if the patch component for `~`, or the minor
and patch components for `^`, are non-zero, a compatible release already exists
and the pre-release part is ignored (same as the release case). If they are
zero, no final release may exist yet and the range starts from the first alpha:

```
~$:  1.2.0-a.1 -> [1.2.0-a.1 1.3.0-)
     1.2.0-b.2 -> [1.2.0-a.1 1.3.0-)
     1.2.1-a.1 -> [1.2.0     1.3.0-)
     1.2.2-b.2 -> [1.2.0     1.3.0-)

^$:  1.0.0-a.1 -> [1.0.0-a.1 2.0.0-)
     1.0.0-b.2 -> [1.0.0-a.1 2.0.0-)
     1.0.1-a.1 -> [1.0.0     2.0.0-)
     1.1.0-b.2 -> [1.0.0     2.0.0-)
```

**Snapshot pre-release version**: two sub-cases are distinguished.

- Patch snapshot (patch component is non-zero): treated the same as the final
  pre-release case, on the assumption that the dependency is developed
  independently.
- Major/minor snapshot (patch component is zero): all packages are assumed to
  be developed in lockstep at the same `X.Y.0` version. The range starts from
  the earliest possible version in the snapshot series and ends before the next
  iteration or pre-release step. In this case `~` and `^` behave identically:

```
1.2.0-a.0.nnn -> [1.2.0-a.0.1 1.2.0-a.1)
2.0.0-b.2.nnn -> [2.0.0-b.2.1 2.0.0-b.3)
```


## Package Build System Skeleton

### Purpose

There are situations where `bpkg` must evaluate `buildfile` expressions before
committing to a particular package version and before unpacking the package
archive. For example, `bpkg` may need to evaluate a condition in a conditional
dependency, or negotiate configuration among several dependents of a package,
which requires knowing that package's configuration variable types and default
values.

To solve this chicken-and-egg problem, `bpkg` includes a minimal subset of the
build system files together with the package's standard metadata in the
repository's `packages.manifest`. This subset is called the package build
system skeleton, or package skeleton for short.

### Contents

The skeleton always includes, when present:

- `build/bootstrap.build` (or its alternative naming scheme variant)
- `build/root.build` (or its alternative naming scheme variant)
- Any files in `build/config/*.build` (or their alternative naming scheme
  variants)

If `root.build` sources files other than those in `build/config/*.build`, each
such file must be listed explicitly in the package manifest using the
`build-file` field.

### The `build.mode` Variable

Inside a buildfile loaded as part of a skeleton, the variable `build.mode` is
set to the string `skeleton`. Normal loads have a different value. Use this
variable to guard anything that must not run during a skeleton load.

The most important use is to skip loading of build system modules that are
listed as package dependencies and are therefore not yet available during the
skeleton load. Built-in modules and standard pre-installed modules may be
loaded unconditionally:

```
# root.build

using cxx       # Ok, built-in module.
using autoconf  # Ok, standard pre-installed module.

if ($build.mode != 'skeleton')
  using hello
```

The `build.mode` check can also omit expensive evaluation that is only
required during an actual build:

```
# root.build

using cxx

# Determine the GCC plugin directory, but skip during skeleton load.
#
if ($build.mode != 'skeleton')
{
  if ($cxx.id != 'gcc')
    fail 'this project can only be built with GCC'

  # If plugin support is disabled, -print-file-name prints the name
  # as passed (a real plugin directory will always be absolute).
  #
  plugin_dir = [dir_path] \
    $process.run($cxx.path -print-file-name=plugin)

  if ("$plugin_dir" == plugin)
    fail "$recall($cxx.path) does not support plugins"

  plugin_dir = $normalize($plugin_dir)
}
```


## See Also

- [bpkg manifest reference](../bpkg/bpkg-manifest-reference.md)
- [bpkg dependency configuration negotiation](../bpkg/bpkg-dependency-negotiation.md)
- [build2 version module](build2-module-version.md)
