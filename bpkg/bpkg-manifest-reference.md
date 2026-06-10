# bpkg Package Manifest Reference

## Overview

A package manifest is a UTF-8 encoded text file named `manifest` that lives in
the package root directory. It describes a `bpkg` package: its identity,
version, dependencies, build configuration, and metadata. The manifest is
consumed by `bpkg` during packaging, publishing, and dependency resolution.

Every package archive submitted to a `pkg` repository must contain a valid
`manifest` file. The manifest header (the fields up to and including `license`)
is itself a valid minimal manifest. All fields beyond the header are optional.


## Manifest Format

A manifest is a list of name-value pairs, one per line:

```
<name>: <value>
```

Rules:

- Names are case-sensitive, lower-case, and use `-` to separate words.
- Leading and trailing whitespace around name and value is ignored.
- A `#` at the start of a line (outside multi-line mode) is a comment.
- A line ending with `\` (backslash) is continued on the next line. Both the
  backslash and the newline are removed, not replaced with a space. To include
  a literal trailing backslash, write `\\`.
- The first name-value pair must have an empty name. Its value is the manifest
  format version, which must currently be `1`:

```
: 1
name: libfoo
version: 1.2.3
```

- Multiple manifests in one file are separated by a bare `:` line.

**Multi-line values** are entered by following the `:` with a backslash on its
own line (the multi-line mode terminator is also a lone backslash line):

```
description:
\
First paragraph.
#
Second paragraph.
\
```

In multi-line mode, `#` and newlines are treated as ordinary characters. Long
lines can still be split with a trailing `\`.

**Inline comments** are permitted on certain fields by appending `;` followed
by free text. Such comments are part of the value and should be full sentences:

```
email: foo-users@example.com ; Public mailing list.
```

Non-comment semicolons in such fields must be escaped with `\`.

**Name suffixes** used by convention:

| Suffix | Meaning |
|--------|---------|
| `-file` | value is a path to a file in the package |
| `-url` | value is a URL |
| `-email` | value is an email address |


## Package Version Format

```
[+<epoch>-]<upstream>[-<prerel>][+<revision>][#<iteration>]
```

| Component | Description |
|-----------|-------------|
| `epoch` | Integer. Changed when versioning scheme is incompatible. Defaults to `1` (or `0` for stubs). |
| `upstream` | Upstream software version. Alphanumeric characters and `.` only. `.` separates components. |
| `prerel` | Pre-release marker (same format as upstream). Absent means final/maximum release. Empty (`1.2.3-`) means minimum/earliest release. |
| `revision` | Integer. Versions the packaging of a given upstream release. Defaults to `0`. |
| `iteration` | Integer. Managed internally by `bpkg` for external packages. Cannot be set by the user. |

Version `0` (or `0+N`) is a **stub**: a package with no source code that can
only be satisfied by a system package manager.

When displaying or deriving file names, the default epoch, zero revision, and
zero iteration are omitted. For example `+1-1.2.3+0` displays as `1.2.3`.

Sorting order: epoch, upstream, prerel, revision, iteration. Components are
compared left to right. A purely numeric component is compared as an integer.
A missing component is treated as `0` (integer) or `""` (string). An absent
`prerel` is always greater than any non-absent prerel, making the final release
greater than any pre-release.

Examples:

```
0+1
+0-20180112
1.2.3
1.2.3-a1
1.2.3-b2
1.2.3-rc1
1.2.3-alpha.1
1.2.3+1
+2-1.2.3
+2-1.2.3-alpha.1+3
```


## Version Constraint Syntax

```
<version-constraint> = <comparison> | <shortcut> | <range>
<comparison>         = ('==' | '>' | '<' | '>=' | '<=') <version>
<shortcut>           = ('^' | '~') <version>
<range>              = ('(' | '[') <version> <version> (')' | ']')
```

`[` and `]` are inclusive bounds. `(` and `)` are exclusive bounds.

The shortcut operators work only with standard versions (semantic versions
without a pre-release part):

```
~X.Y.Z  [X.Y.Z  X.Y+1.0-)    patch-compatible upgrades
^X.Y.Z  [X.Y.Z  X+1.0.0-)    minor-compatible upgrades  (X > 0)
^0.Y.Z  [0.Y.Z  0.Y+1.0-)    patch-compatible when major is 0
```

`X.Y.Z-` means the earliest possible pre-release of `X.Y.Z`.

The special `$` value in a constraint stands for the dependent package's own
version (ignoring revision). Useful for related packages that must track each
other:

```
depends: libsqlite3 == $
```

With shortcut operators, `$` expansion considers whether the version is a
release, a final pre-release, or a snapshot pre-release and adjusts the range
accordingly.


## Required Fields

| Field | Format | Description |
|-------|--------|-------------|
| `name` | `<name>` | Package name. Case-insensitive comparison but original case preserved. Must start with a letter, end with a letter/digit/`+`. At least two characters. |
| `version` | `<version>` | Package version. See version format above. |
| `summary` | `<text>` | Short one-line description of the package. |
| `license` | `<licenses> [; <comment>]` | SPDX license expression or `other:` scheme. Multiple values have OR semantics. Comma-separated names within one value have AND semantics. |


## Package Identity Fields

| Field | Format | Description |
|-------|--------|-------------|
| `upstream-version` | `<string>` | Original upstream version when the bpkg version deviates from it. Informational. |
| `type` | `<name>[,<sub-options>]` | Package type: `exe`, `lib`, or `other`. Sub-option `binless` marks a header-only library. Inferred from name prefix if absent. |
| `language` | `<name>[=impl]` | Programming language (lower-case). Multiple values allowed. Mark implementation-only languages with `=impl`. Defaults to the name extension or `cc`. |
| `project` | `<name>` | Project this package belongs to. Defaults to the package name. Used for grouping in repositories. |
| `priority` | `security \| high \| medium \| low [; <comment>]` | Release priority. Defaults to `low`. |
| `topics` | `<topic> [, <topic>]*` | Up to five multi-word concepts describing the package. |
| `keywords` | `<keyword> [ <keyword>]*` | Up to five space-separated single words. Package name, project name, and summary words are implicit keywords. |


## Source and Documentation Fields

| Field | Format | Description |
|-------|--------|-------------|
| `description` | `<text>` | Detailed description of the project. Inline text. |
| `description-file` | `<path> [; <comment>]` | Path (within the package) to the project description file. Mutually exclusive with `description`. |
| `description-type` | `<text-type>` | MIME type of the description. Auto-detected from file extension if omitted. Supported: `text/plain`, `text/markdown;variant=GFM`, `text/markdown;variant=CommonMark`. |
| `package-description` | `<text>` | Detailed description specific to the package (when package and project are maintained separately). |
| `package-description-file` | `<path> [; <comment>]` | File path for the package description. Recommended names: `PACKAGE-README` or `README-PACKAGE`. |
| `package-description-type` | `<text-type>` | MIME type for the package description. |
| `changes` | `<text>` | Description of changes in this release. Multiple values allowed, concatenated in order (most recent first). |
| `changes-file` | `<path> [; <comment>]` | Path to a changes/NEWS file. Can follow inline `changes` values. |
| `changes-type` | `<text-type>` | MIME type for the changes content. |
| `url` | `<url> [; <comment>]` | Project home page URL. |
| `doc-url` | `<url> [; <comment>]` | Project documentation URL. |
| `src-url` | `<url> [; <comment>]` | Project source repository URL. |
| `package-url` | `<url> [; <comment>]` | Package home page URL. Defaults to `url`. |
| `email` | `<email> [; <comment>]` | Project email address (e.g., support mailing list). |
| `package-email` | `<email> [; <comment>]` | Package email address. Defaults to `email`. |


## Dependency Fields

### `depends`

```
[depends]: [*] <alternatives> [; <comment>]
```

Declares a dependency on one or more packages. `*` marks a build-time
dependency (must be built for the host in cross-compilation). Without `*` it
is a run-time dependency.

Each `depends` value is AND-composed with other `depends` values. Within one
value, alternatives separated by `|` have OR semantics: `bpkg` picks the first
alternative already present or fails asking the user to choose.

**Single-line syntax:**

```
depends: libhello ^1.0.0
depends: * build2 >= 0.15.0
depends: * bpkg >= 0.15.0
depends: libmysqlclient >= 5.0.3 | libmariadb ^10.2.2
depends: libposix-getopt ^1.0.0 ? ($cxx.target.class == 'windows')
```

Group constraints apply to all members without their own constraint:

```
depends: { libboost-any libboost-log libboost-uuid ~1.77.1 } ~1.77.0
```

A dependency alternative can reflect a config variable (single-line form,
one variable only):

```
depends: libposix-regex ^1.0.0 ? ($cxx.target.class == 'windows') \
  config.hello.external_regex=true
```

**Multi-line syntax** adds `enable`, `require`, `prefer`/`accept`, and
`reflect` clauses:

```
depends:
\
libmariadb ^10.2.2
{
  enable ($cxx.target.class != 'windows')

  prefer
  {
    config.libmariadb.cache = true
    config.libmariadb.buffer = ($config.libmariadb.buffer < 4096 \
                                ? 4096 : $config.libmariadb.buffer)
  }

  accept ($config.libmariadb.buffer >= 4096)

  reflect
  {
    config.hello.buffer = $config.libmariadb.buffer
  }
}
\
```

Clause semantics:

| Clause | Purpose |
|--------|---------|
| `enable <cond>` | Condition expression -- alternative is ignored when false. |
| `require { ... }` | Set one or more `bool` config vars to `true`. Shortcut for prefer/accept when only enabling boolean features. |
| `prefer { ... }` | Buildfile fragment expressing preferred config variable values. |
| `accept (<expr>)` | Condition expression that must evaluate to `true` for the negotiated config to be accepted. Required when `prefer` is used. |
| `reflect { ... }` | Buildfile fragment setting the **dependent's** own config vars for use in subsequent `depends` values or at build time. |

In `prefer`/`reflect` you set the **dependency's** config vars. In `reflect`
you set the **dependent's** config vars.

### `constrains`

```
[constrains]: [*] <dependency-constraint> [; <comment>]
```

Imposes a version constraint and/or configuration on an **indirect**
dependency (one not directly declared). The constraint applies only if the
named package appears in the dependency tree. Does not declare a dependency
itself. Supports the same `enable`, `require`, `prefer`/`accept`, and
`reflect` clauses as `depends`. Must follow all `depends` values.

Example:

```
name: libbar
depends: libfoo
constrains: libmariadb >= 11.0.0 config.libbar.mariadb=true
```

### `requires`

```
[requires]: [*] <alternatives> [; <comment>]
```

Non-package requirements (platform, compiler, C++ standard, system libraries).
Primarily for documentation. Some values are recognized by tooling or build
bots.

```
requires: c++17
requires: linux | windows | macos
requires: libc++ ? ($macos)
requires: libx11 >= 1.7.2
```

Pre-defined names for common requirements:

```
c++98  c++03  c++11  c++14  c++17  c++20  c++23
posix  linux  macos  freebsd  openbsd  netbsd  windows
gcc[_X.Y.Z]  clang[_X.Y]  msvc[_N.U]
bootstrap  host
```

`bootstrap` marks build system modules requiring bootstrapping. `host` marks
packages (such as source code generators) that should be built in a host
configuration.


## Build Configuration Fields

| Field | Format | Description |
|-------|--------|-------------|
| `builds` | `[<class-uset>:] [<class-expr>] [; <comment>]` | Target configuration class expression controlling which automated build configurations are used. Defaults to `default` class. Multiple values are evaluated in order as a single expression. |
| `build-include` | `<config>[/<target>] [; <comment>]` | Wildcard pattern for build configuration names to include. Applied after `builds`. First match wins. |
| `build-exclude` | `<config>[/<target>] [; <comment>]` | Wildcard pattern for build configuration names to exclude. Applied after `builds`. First match wins. `**` matches across name components. |
| `build-auxiliary` | `<config> [; <comment>]` | Wildcard pattern for auxiliary machine configurations (e.g., a database for integration tests). At most 9 allowed. |
| `build-auxiliary-<name>` | `<config> [; <comment>]` | Named auxiliary configuration, for when multiple auxiliary machines are needed. Environment variables for the machine are prefixed with the capitalized name. |
| `build-bot` | `<pub-key>` | PEM public key of a custom build bot. Multiple values allowed. Replaces (not augments) default bots. |
| `build-email` | `<email> [; <comment>]` | Email address for all build result notifications. |
| `build-warning-email` | `<email> [; <comment>]` | Email address for build warning and error notifications only. |
| `build-error-email` | `<email> [; <comment>]` | Email address for build error notifications only. |

**`builds` class expression syntax:**

```
builds: none                        ; No configurations.
builds: all                         ; All configurations.
builds: all : &host                 ; All host configurations.
builds: default                     ; Default configurations (implied if absent).
builds: -windows                    ; Default except Windows.
builds: all : -windows              ; All except Windows.
builds: all : &gcc                  ; All with GCC only.
builds: all : &gcc &( +linux +macos ) ; All GCC on Linux or Mac OS.
```

The optional underlying class set before `:` defines the base. The expression
uses `+` (add), `-` (subtract), `&` (intersect), optionally followed by `!`
to invert. The first `builds` value may specify the underlying set.

**Per-configuration overrides** (`*-build-config`):

```
[*-build-config]: <args> [; <comment>]
[*-builds]: <class-expr> [; <comment>]
[*-build-include]: <config>[/<target>] [; <comment>]
[*-build-exclude]: <config>[/<target>] [; <comment>]
[*-build-auxiliary]: <config> [; <comment>]
[*-build-auxiliary-<name>]: <config> [; <comment>]
[*-build-bot]: <pub-key>
[*-build-email]: <email> [; <comment>]
[*-build-warning-email]: <email> [; <comment>]
[*-build-error-email]: <email> [; <comment>]
```

The `*` in `*-build-config` is the configuration name. The special name
`default` overrides the default (unnamed) configuration. The args are
whitespace-separated (optionally quoted) config variables, options, and
dependency specs, optionally prefixed with a build bot step id to restrict
scope. Per-configuration `*-build-auxiliary` and `*-build-bot` values
**replace** (not extend) the common values.

Examples:

```
network-build-config: config.libfoo.network=true; Enable networking API.
sys-build-config: ?sys:libz; Test with system libz.
network-builds: linux; Only supported on Linux.
```


## Test Package Fields

| Field | Format | Description |
|-------|--------|-------------|
| `tests` | `[*] <name> [<version-constraint>] [? <cond>] [<reflect-var>]` | Separate test package. `*` makes the primary package a build-time dependency for the test package. |
| `examples` | `[*] <name> [<version-constraint>] [? <cond>] [<reflect-var>]` | Separate examples package. |
| `benchmarks` | `[*] <name> [<version-constraint>] [? <cond>] [<reflect-var>]` | Separate benchmarks package. |

These packages are built and tested together with the primary package by
automated build bots. They must be available from the primary package's
repository or its complement repositories (recursively). Recommended naming:
`<primary>-tests`, `<primary>-examples`, `<primary>-benchmarks`.

Test packages themselves do not declare an explicit dependency on the primary
package. They may have their own `builds` constraints.

Version constraints support `$` to reference the primary package version:

```
tests: hello-tests ~$
```

To communicate to a test package which primary package is being tested:

```
tests: hello-tests config.hello_tests.test=hello-foo
```


## File Reference Fields

| Field | Format | Description |
|-------|--------|-------------|
| `build-file` | `<path>` | Path (relative to `build/`) of an additional file included by `root.build` that must be in the package skeleton. Extension must be `.build` (or `.build2`). |
| `bootstrap-build` | `<text>` | Inline content of `build/bootstrap.build`. |
| `root-build` | `<text>` | Inline content of `build/root.build`. |
| `*-build` | `<text>` | Inline content of an additional skeleton file (name prefix is the path relative to `build/` with extension stripped). |
| `bootstrap-build2` | `<text>` | Alternative naming scheme variant of `bootstrap-build`. |
| `root-build2` | `<text>` | Alternative naming scheme variant of `root-build`. |
| `*-build2` | `<text>` | Alternative naming scheme variant of `*-build`. |

If these fields are not specified, `bootstrap.build`, `root.build`, and
`build/config/*.build` files are automatically included in the package
skeleton when the package list manifest is created.

**Binary distribution mapping fields:**

| Field | Format | Description |
|-------|--------|-------------|
| `<dist>-name` | `<name> [<name>...]` | Distribution package name(s) for binary packaging. Auto-derived from bpkg name if absent. |
| `<dist>-version` | `<string>` | Distribution package version. Defaults to `upstream-version` if set, otherwise bpkg version. Use `$` to force bpkg version when `upstream-version` is set. |
| `<dist>-to-downstream-version` | `/<pattern>/<replacement>/` | Regex mapping from distribution version back to bpkg version. |

`<dist>` is `<name>[_<version>]`, for example `debian`, `debian_10`,
`ubuntu_16.04`, `fedora_32`, `windows_10`.


## See Also

- [bpkg SUMMARY](SUMMARY.md)
- [packaging guide](../guides/packaging-guide-summary.md)
