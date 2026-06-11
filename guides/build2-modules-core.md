# build2 Core Modules Reference

This document covers the four core build system modules: `config`, `test`,
`install`, and `version`. These modules are typically loaded in
`build/bootstrap.build` because they define new operations or need early
initialization.

Typical `bootstrap.build`:

```
project = hello

using version
using config
using test
using install
using dist
```

---

## config module

### Overview

The `config` module provides support for persistent build configurations.
Without it, configuration variables must be specified on every invocation.
With it, a project can be configured once and the settings are saved to
`build/config.build`. The module also supports hermetic configurations that
capture and freeze the environment.

### Enabling

Load in `build/bootstrap.build`:

```
using config
```

Simple projects cannot use the `config` module because they do not support
bootstrapping. The module is implicitly available only in standard projects.

### Key Variables

| Variable | Type | Description |
|---|---|---|
| `config.config.hermetic` | `bool` or `null` | `true` saves the relevant environment to `config.config.environment`. `false` clears it. `null`/undefined leaves `config.config.environment` untouched. |
| `config.config.environment` | string list | Low-level variable holding environment variable sets (`name=value`) and unsets (`name`) applied during hermetic builds. |
| `config.config.hermetic.reload` | `bool` | Transient. Re-hermetizes the configuration during reconfigure. Not stored in `config.build`. |
| `config.config.hermetic.environment` | string list | Inclusions (`name`) and exclusions (`name@false`) that adjust which variables are captured during hermetization. |
| `config.config.disfigure` | string | Remove a specific variable from the saved configuration during reconfigure. |

The `config.environment` buildfile directive (not a variable) registers
environment variables that affect the build and should be tracked:

```
config.environment USE_FOO
```

### Hermetic Build Configurations

A hermetic configuration saves environment variables alongside other project
configuration so that subsequent builds see exactly the same environment as
during initial configuration. This is useful when:

- The environment is not generally available after configuration (for example,
  a Visual Studio developer command prompt).
- Parts of the overall result have already been built and installed, as is the
  case with build system modules.

Create a hermetic configuration:

```
$ b configure config.config.hermetic=true
```

After configuration, `build/config.build` will contain something like:

```
config.config.hermetic = true
config.config.environment = CPATH CPLUS_INCLUDE_PATH PATH=...
```

Re-hermetize during reconfigure (transient, not stored):

```
$ b configure config.config.hermetic.reload=true
```

De-hermetize:

```
$ b configure config.config.hermetic=false
```

Adjust which variables are captured:

```
LC_ALL=C b configure \
  config.config.hermetic=true \
  config.config.hermetic.environment="LC_ALL PATH@false"
```

### Usage Examples

Configure a project persistently:

```
$ b configure config.cxx=clang++ config.cxx.std=c++17
$ b            # subsequent builds use saved config
```

Report a manually-tracked environment variable and track it in ad hoc recipes:

```
config.environment USE_FOO

foo = $getenv(USE_FOO)

if ($foo != [null])
  cxx.poptions += "-DUSE_FOO=$foo"
```

Track environment variables in an ad hoc recipe:

```
import! foo = foo%exe{foo}

config.environment FOO BAR

file{output}: file{input} $foo
{{
  diag foo $>
  depdb env FOO BAR
  $foo $path($<[0]) >$path($>)
}}
```

---

## test module

### Overview

The `test` module defines the `test` operation. When `b test` is run, the
module first performs `update` as a pre-operation and then executes the tests.
It supports simple tests (a target-specific `test` variable set to `true`),
Testscript tests (`.testscript` files), and ad hoc test recipes.

### Enabling

Load in `build/bootstrap.build`:

```
using test
```

### Key Variables

| Variable | Type | Description |
|---|---|---|
| `config.test` | string list | Narrows which targets and testscript tests to run. Value is `@`-separated target/id-path pairs. |
| `config.test.timeout` | string | Timeout in seconds with the form `<op-timeout>/<test-timeout>`. Either side may be omitted. `0` clears a previously set timeout. |
| `config.test.runner` | string | Runner program and options in the form `<path> [<options>]`. Applied to simple and Testscript tests automatically. |
| `test.runner.path` | path or null | Path component of `config.test.runner`. `null` when no runner is set. Used in ad hoc recipes. |
| `test.runner.options` | string | Options component of `config.test.runner`. Used in ad hoc recipes. |

The target-specific `test` variable (bool) marks a target as testable. Setting
`test = true` on an `exe{}` makes `b test` execute it.

### config.test Syntax

The value contains `@`-separated pairs: the left side is a target, the right
side is a testscript id path. Either can be omitted along with `@`.

If a value contains a target type or ends with a directory separator, it is
treated as a target name. Otherwise it is treated as an id path.

Targets are resolved relative to the root scope where `config.test` is set.

A directory target without an explicit target type (for example, `foo/`) enables
all tests at and under that directory.

### Testscript Integration

Testscript files (`.testscript`) are automatically associated with their target
by the test module. See the testscript manual for full details on test commands,
groups, and the `timeout` builtin.

### Usage Examples

Run only a specific target:

```
$ b test config.test=foo/exe{driver}
```

Run only a specific testscript test case:

```
$ b test config.test=bar/baz
```

Run a specific target with a specific testscript test:

```
$ b test config.test=foo/exe{driver}@bar
```

Multiple id paths for one target using pair generation:

```
$ b test config.test=foo/exe{driver}@{bar baz}
```

Set timeouts:

```
$ b test config.test.timeout=20     # whole test operation
$ b test config.test.timeout=20/5   # operation and per-test
$ b test config.test.timeout=/5     # per-test only
```

Use a runner program:

```
$ b test config.test.runner="valgrind -q"
```

Ad hoc recipe that handles the runner explicitly:

```
exe{hello}:
% test
{{
  diag test $>

  cmd = ($test.runner.path == [null] \
    ? $> \
    : $test.runner.path $test.runner.options $path($>))

  $cmd 'World' >>>?'Hello, World!'
}}
```

---

## install module

### Overview

The `install` module defines the `install` and `uninstall` operations. It
models a UNIX-like installation layout with a customizable directory tree
rooted at `config.install.root`. The `install` operation automatically
performs `update` as a pre-operation.

Target types have built-in installability defaults: `exe{}` goes to `bin/`,
`doc{}` goes to `share/doc/<project>/`, `file{}` is not installed. These
defaults can be overridden per-target with the `install` target-specific
variable.

### Enabling

Load in `build/bootstrap.build`:

```
using install
```

### Installation Layout

The install module defines a tree of named locations. Each location has a
default path derived from its parent and can be overridden by the user with
the corresponding `config.install.*` variable.

```
name          default                                 config.install.*
----          -------                                 ----------------
root                                                  c.i.root

data_root     root/                                   c.i.data_root
exec_root     root/                                   c.i.exec_root

bin           exec_root/bin/                          c.i.bin
sbin          exec_root/sbin/                         c.i.sbin
lib           exec_root/lib/<private>/                c.i.lib
libexec       exec_root/libexec/<private>/<project>/  c.i.libexec
pkgconfig     lib/pkgconfig/                          c.i.pkgconfig

etc           data_root/etc/                          c.i.etc
include       data_root/include/<private>/            c.i.include
include_arch  include/                                c.i.include_arch
share         data_root/share/                        c.i.share
data          share/<private>/<project>/              c.i.data
buildfile     share/build2/export/<project>/          c.i.buildfile

doc           share/doc/<private>/<project>/          c.i.doc
legal         doc/                                    c.i.legal
man           share/man/                              c.i.man
man<N>        man/man<N>/                             c.i.man<N>
```

The `<project>`, `<version>`, and `<private>` placeholders are substituted
with the project name, version, and private subdirectory, respectively. If
any is empty, the corresponding directory component is omitted.

`include_arch` is for architecture-specific headers (for example, configuration
headers). It defaults to the same path as `include` but can be set independently
on multi-arch systems.

`buildfile` is for exported buildfiles from `build/export/`. Files matching
`**.build` in that directory are installed here automatically.

### Key Variables

| Variable | Type | Description |
|---|---|---|
| `config.install.root` | dir_path | Root installation directory. Required to run `install`. |
| `config.install.sudo` | string | Program to use for privileged file operations (for example, `sudo`). Only actual copy/remove commands are wrapped. |
| `config.install.private` | rel dir_path | Optional private subdirectory inserted into `lib`, `libexec`, `include`, and `data` paths. |
| `config.install.relocatable` | `bool` | Generate a relocatable installation that can be moved preserving its internal directory structure. |
| `config.install.filter` | string | Key-value pairs controlling which filesystem entries are included or excluded during install/uninstall. |
| `config.install.manifest` | path | If set, write an installation manifest to this path. In relocatable installs, manifest paths are relative to the manifest file. |
| `config.install.chroot` | dir_path | Prefix all installation paths with this directory (useful for staged installs). |
| `install` | string or `false` | Target-specific variable. Set to `false` to suppress installation or to a named-location-relative path to override the default destination. |
| `install.subdirs` | `bool` | Target-specific. When `true`, recreates the source directory hierarchy under the installation directory. |

### Relocatable Installation

A relocatable installation can be moved as a whole to a different directory.
RPATHs use `$ORIGIN`/`@loader_path`, pkg-config files use `${pcfiledir}`, and
manifest paths are made relative automatically.

```
$ b install \
    config.install.root=/tmp/install \
    config.install.relocatable=true
```

If a project embeds its own installation paths and cannot support relocation,
assert this early:

```
assert (!$install.relocatable) 'relocatable installation not supported'
```

Compute a library directory relative to the executable directory:

```
plugin_dir = $install.resolve($install.lib, $install.bin)
```

### Installation Filtering

Users can filter what gets physically copied without affecting what is built
for install or the pkg-config output:

```
$ b install config.install.filter='include/@false "*.a"@false'
```

Filter syntax: each entry is `<path-or-pattern>@<true|false>[,symlink]`. The
first matching entry wins. A leading `!` negates the entire filter list. If no
entry matches, the file is included.

### Usage Examples

Basic install:

```
$ b install config.install.root=/tmp/install/
```

Install to a system directory using sudo:

```
$ b install \
    config.install.root=/usr/local/ \
    config.install.sudo=sudo
```

Configure once, install/uninstall repeatedly:

```
$ b configure config.install.root=/usr/local/
$ b install
$ b uninstall
```

Install with a private subdirectory and rpath:

```
$ b install \
    config.install.root=/usr/local/ \
    config.install.private=hello/ \
    config.bin.rpath=/usr/local/lib/hello/
```

In a buildfile, suppress installation of a subtree and set header location:

```
tests/: install = false

hxx{*}:
{
  install         = include/libhello/
  install.subdirs = true
}

h{*}:      install = include/libhello/
h{config}: install = include_arch/libhello/
```

See [third-party-private-headers](../HOWTO/third-party-private-headers.md) for
when to use `include_arch` versus `install = false` for generated config headers
in third-party packaging, and for `cxx.pkgconfig.include` when `include_arch`
diverges from `include` on multi-arch systems.

```
```

## See Also

- [build2 version module](build2-module-version.md)
- [build2 manual summary](build2-intro-concepts.md)
- [build2 cc modules](build2-modules-cc.md)
- [build2 miscellaneous modules](build2-modules-misc.md)
- [third-party-private-headers](../HOWTO/third-party-private-headers.md)
