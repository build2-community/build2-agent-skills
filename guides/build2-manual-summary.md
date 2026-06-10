# build2 Build System -- Introduction and Tutorial

## What is build2

build2 is a native, cross-platform build system with a terse, mostly
declarative description language, a conceptual model of build, and a uniform
interface with consistent behavior across platforms and compilers.

build2 borrows the fundamental DAG-based build model from `make` and many
conceptual extensions from GNU `make`. Unlike `make`, build2 is designed to
handle the demands of modern cross-platform C/C++ development without magic
or black boxes. It is not specific to C/C++ -- the build model is general
enough to handle any DAG-based operations.

The build system is part of a larger toolchain that includes package manager
(`bpkg`) and project dependency manager (`bdep`), but it does not depend on
them and can be used standalone.

---

## Core concepts

### Targets and target types

A **target** is something the build system knows how to produce or track. A
**target type** classifies targets and determines which rules apply to them,
how file extensions are resolved, and where targets are installed. Target type
names are always written with trailing `{}`, for example `exe{}`.

Common target types:

| Target type | Meaning |
|-------------|---------|
| `exe{}` | Executable binary |
| `lib{}` | Library group (builds both static and shared members) |
| `liba{}` | Static library (`.a`, `.lib`) |
| `libs{}` | Shared library (`.so`, `.dll`, `.dylib`) |
| `libue{}` | Utility library for an executable primary target |
| `libul{}` | Utility library for a library primary target |
| `cxx{}` | C++ source file |
| `hxx{}` | C++ header file |
| `ixx{}` | C++ inline file |
| `txx{}` | C++ template file |
| `c{}` | C source file |
| `h{}` | C header file |
| `in{}` | Input template file (processed by the `in` module) |
| `dir{}` | Directory alias target |
| `alias{}` | Generic alias target |
| `file{}` | Generic file target |
| `doc{}` | Documentation file |
| `man{}` | Man page file |
| `fsdir{}` | Filesystem directory (creates directories) |
| `testscript{}` | build2 Testscript file |
| `manifest{}` | Package manifest file |

Target types form a hierarchy. For example, `dir{}` derives from `alias{}`.
Platform-specific file name details (extensions, prefixes, suffixes) are
handled by the type and the rule, not spelled out in buildfiles.

### The build graph

build2 uses a **DAG** (directed acyclic graph) where each node is a target
and edges represent prerequisite relationships. When building a target,
build2 recursively updates all prerequisites first.

A **dependency declaration** states a target and its prerequisites:

```
exe{hello}: cxx{hello}
```

A **rule** determines _how_ to update a target given its prerequisites. Rules
are matched based on target type and prerequisite types. Rules come from the
build system core or from build system modules (e.g., the `cxx` module
provides rules for compiling and linking C++ code).

### Buildfiles and project structure

#### Simple project layout

A simple project requires only a single `buildfile`:

```
hello/
+-- hello.cxx
+-- buildfile
```

`buildfile` contents:

```
using cxx

cxx{*}: extension = cxx
hxx{*}: extension = hxx

exe{hello}: cxx{hello}
```

Simple projects cannot be imported by other projects and do not support the
`config` module (no persistent configuration). They are suitable only for
minimal use cases.

#### Standard project layout

```
hello/
+-- build/
|   +-- bootstrap.build
|   +-- root.build
+-- hello/
|   +-- hello.cxx
|   +-- buildfile
+-- buildfile
+-- manifest
```

The standard project is what you use for real development. The `build/`
directory houses project-wide build system information.

**`build/bootstrap.build`** -- read first, defines the project name and loads
modules that must be available early (e.g., modules that define new
operations). A typical example:

```
project = hello

using version
using config
using test
using install
using dist
```

**`build/root.build`** -- read after bootstrapping, loaded into the project
root scope. Defines project-wide settings, loads language modules, sets
compiler standard and default file extensions. Example:

```
cxx.std = latest

using cxx

hxx{*}: extension = hxx
cxx{*}: extension = cxx
```

**Root `buildfile`** -- declares which subdirectories to build:

```
./: {*/ -build/} doc{README.md LICENSE} manifest
```

**Source subdirectory `buildfile`** -- declares what to build in that
subdirectory:

```
exe{hello}: {hxx cxx}{**}

cxx.poptions =+ "-I$out_root" "-I$src_root"
```

The `bdep new` command creates standard-layout projects automatically. For
an executable: `bdep new --no-init -l c++,cpp -t exe hello`. For a library:
`bdep new --no-init -l c++ -t lib libhello`.

#### Alternative naming scheme

Every use of the word `build` can be replaced with `build2` throughout a
project (so `build2/`, `bootstrap.build2`, `root.build2`, `build2file`).
This is useful when adding build2 to an existing project where `build/` is
already in use.

### Scopes

The project's directory tree defines a **scope hierarchy**. Each buildfile is
loaded into its corresponding scope. Variables set in a buildfile are set in
that scope. Relative targets in a buildfile are relative to that scope's
directory.

Variable lookup starts in the current scope and walks outward to the global
scope if the variable is not found locally.

Special scope variables set automatically by the build system:

| Variable | Meaning |
|----------|---------|
| `src_root` | Absolute path to the project's source root directory |
| `out_root` | Absolute path to the project's output root directory |
| `src_base` | Absolute path to the current scope's source directory |
| `out_base` | Absolute path to the current scope's output directory |
| `project` | Project name (set in `bootstrap.build`) |

The **global scope** (`/`) is read-only and contains build-wide variables
such as `build.host`, `build.host.class`, `build.host.cpu`, etc.

Scopes can be opened explicitly in buildfiles when needed:

```
hello/
{
  exe{hello}: {hxx cxx}{**}
}
```

### Modules

Modules extend the build system with rules, target types, variables, and
operations. They are loaded with the `using` directive.

| Module | Purpose |
|--------|---------|
| `cxx` | C++ compilation and linking rules |
| `c` | C compilation and linking rules |
| `cc` | C-common shared infrastructure (use instead of `c`/`cxx` in build configurations) |
| `config` | Persistent configuration support (`configure`/`disfigure` meta-operations) |
| `test` | Test execution (`test` operation) |
| `install` | Installation (`install`/`uninstall` operations) |
| `dist` | Source distribution preparation (`dist` meta-operation) |
| `version` | Version management from `manifest` |
| `in` | Generic file preprocessor (template substitution) |
| `bin` | Binary utility rules (used internally by `c`/`cxx`) |

Modules loaded in `bootstrap.build` are loaded early (bootstrapping phase).
Modules loaded in `root.build` are loaded during the project load phase.

### Variables

Variables hold typed or untyped list-of-names values. The fundamental
untyped value is a list of names. Variables can be given static types.

**Assignment forms:**

```
x = value         # Replace (immediate assignment)
x += value        # Append to end
x =+ value        # Prepend to beginning
x ?= value        # Assign only if undefined
```

All assignments are immediate (no deferred evaluation as in GNU make).

**Variable types** (commonly used):

| Type | Example |
|------|---------|
| `bool` | `true`, `false` |
| `uint64` | `42` |
| `string` | `'Hello'` |
| `strings` | `foo bar baz` |
| `path` | `/usr/bin/gcc` |
| `dir_path` | `/usr/include/` |
| `dir_paths` | `/usr/include/ /usr/local/include/` |
| `target_triplet` | `x86_64-linux-gnu` |
| `project_name` | `hello` |

**Variable visibility:** Variables have a default global visibility but can
have `project`, `scope`, `target`, or `prerequisite` visibility.

**Variable expansion:**

```
info $src_root         # Expand variable
info $(src_root)       # Same, using eval context
```

**Target-specific variables:**

```
exe{hello}: cxx.loptions += -static
```

**Target type/pattern-specific variables:**

```
cxx{*}: extension = cxx
exe{*.test}: test = true
```

**Prerequisite-specific variables:**

```
exe{hello}: file{test.out}: test.stdout = true
```

**Compiler/linker option variables** (cc/c/cxx variants available for each):

| Variable | Purpose | make equivalent |
|----------|---------|-----------------|
| `*.poptions` | Preprocessor options | `CPPFLAGS` |
| `*.coptions` | Compile options | `CFLAGS`/`CXXFLAGS` |
| `*.loptions` | Link options | `LDFLAGS` |
| `*.aoptions` | Archive options | `ARFLAGS` |
| `*.libs` | Extra libraries | `LIBS`/`LDLIBS` |

The `config.cc.*`, `config.c.*`, and `config.cxx.*` sets let users supply
external configuration. Initial values of `cc.*`, `c.*`, and `cxx.*` are
taken from the corresponding `config.*.*` values.

Library export uses `cc.export.*`, `c.export.*`, and `cxx.export.*`.

### Operations and meta-operations

An **operation** is performed on targets. Built-in operations:

- `update` -- build targets (default if no operation is specified)
- `clean` -- remove build output

Module-provided operations:

- `test` -- run tests (performs `update` as a pre-operation)
- `install` -- install build results (performs `update` as a pre-operation)
- `uninstall` -- remove installed files

A **meta-operation** operates on operations+targets. Built-in default:

- `perform` -- simply perform the operation

Module-provided meta-operations:

- `configure` -- save configuration to `build/config.build`
- `disfigure` -- remove persistent configuration
- `dist` -- prepare source distribution
- `create` -- create a build configuration directory

---

## Minimal working example

Complete standard-layout `hello` project:

```
hello/
+-- build/
|   +-- bootstrap.build
|   +-- root.build
+-- hello/
|   +-- hello.cxx
|   +-- buildfile
+-- buildfile
+-- manifest
```

**`build/bootstrap.build`:**

```
project = hello

using version
using config
using test
using install
using dist
```

**`build/root.build`:**

```
cxx.std = latest

using cxx

hxx{*}: extension = hxx
cxx{*}: extension = cxx
```

**`buildfile` (root):**

```
./: {*/ -build/} manifest
```

**`hello/buildfile`:**

```
exe{hello}: {hxx cxx}{**}

cxx.poptions =+ "-I$out_root" "-I$src_root"
```

**`manifest`:**

```
: 1
name: hello
version: 0.1.0
summary: hello C++ executable
```

**`hello/hello.cxx`:**

```cpp
#include <iostream>

int main ()
{
  std::cout << "Hello, World!" << std::endl;
}
```

---

## How to build -- invoking `b`

`b` is the build system driver. The command-line argument is a **buildspec**:
a list of `[meta-op '('] [op ':'] target [')']` entries.

### Basic invocations

```
b                          # Update default target in current directory
b ./                       # Same
b update                   # Same
b update: ./               # Same

b clean                    # Clean current directory
b clean update             # Rebuild

b hello/                   # Build specific directory
b hello/exe{hello}         # Build specific target
b hello/ libhello/         # Build multiple targets
```

### Specifying configuration on the command line

```
b config.cxx=clang++
b config.cxx=clang++ config.cxx.coptions=-g
b config.cxx.coptions=-O3
```

### Persistent configuration

```
b configure config.cxx=clang++ config.cxx.coptions=-g
b                              # Uses saved configuration
b disfigure                    # Remove saved configuration
```

The configuration is saved to `build/config.build`. This file is a buildfile
with variable assignments and can be edited directly.

To reset a single configuration variable to its default:

```
b configure config.config.disfigure=config.cxx
```

### Out of source builds

Syntax: `src/@out/` specifies source and output directories:

```
b hello/@hello-out/                         # Out of source build
b hello/@hello-gcc/    config.cxx=g++
b hello/@hello-clang/  config.cxx=clang++
```

Configure out of source:

```
b configure: hello/@hello-gcc/   config.cxx=g++
b configure: hello/@hello-clang/ config.cxx=clang++

b hello-gcc/      # Build using saved configuration
b hello-clang/
```

#### Forwarded configurations

A source directory can forward to an out-of-source build. When the build
system is invoked from the source directory it builds in the forwarded output
directory and backlinks interesting targets (`exe{}`, `doc{}`) back to the
source directory via symlinks.

```
b configure: hello/@hello-gcc/,forward

cd hello/
b                # Builds in ../hello-gcc/ and symlinks the executable here
```

### Build configurations (shared, amalgamated)

Build configurations are projects that house other projects as subprojects,
giving them a shared compiler/linker configuration and automatic import
resolution.

```
b create: build-gcc/,cc   config.cxx=g++
b create: build-clang/,cc config.cxx=clang++

b configure: libhello/@build-gcc/libhello/
b configure: hello/@build-gcc/hello/

b configure: libhello/@build-clang/libhello/
b configure: hello/@build-clang/hello/

b build-gcc/hello/         # Build hello in GCC configuration
b build-clang/             # Build everything in Clang configuration
```

Subprojects inherit the configuration of their amalgamation.

### Verbosity

```
b -v          # Show actual compiler/linker command lines (verbosity 2)
b -V          # Show all actual commands (verbosity 3)
b --verbose 4 # Trace rule matching and out-of-date determination
b -s          # Serial, stop at first error (useful for debugging)
```

---

## Buildfile language reference

### Name patterns

```
{hxx cxx}{*}     # All .hxx and .cxx files in current directory
{hxx cxx}{**}    # Recursive
{hxx cxx}{** -version}   # Exclude version.*
-**.test...      # Exclude files with .test second-level extension
```

### Dependency declaration chains

```
./: exe{hello}: cxx{hello}     # Chain: default target -> exe -> source
```

### Directives

```
using cxx                       # Load module
include hello/buildfile         # Include buildfile
include hello/                  # Same (buildfile implied)
import libs = libhello%lib{hello}  # Import from another project
info $src_root                  # Print value (to stderr with location)
text 'message'                  # Print without info: prefix
warn 'warning message'
fail 'error and exit'
assert ($x != [null]) 'msg'
print "$cxx.id $cxx.target"    # Print to stdout
dump                            # Dump current scope state to stderr
dump exe{hello}                 # Dump specific target
```

### Conditions

```
if ($cxx.target.class == 'linux')
  ...
elif ($cxx.target.class == 'windows')
{
  ...
}
else
  ...

if! $version.pre_release
  ...

ifn $foo    # if $null($foo)
ife $bar    # if $empty($bar)
```

### Pattern matching

```
switch $cxx.target.class, $cxx.target.system
{
  case 'linux'
    info 'linux'

  case 'windows', 'mingw32'
    info 'windows-mingw'

  case 'windows'
    info 'windows-other'

  default
    info 'other'
}

switch $cxx.id
{
  case 'clang' | 'clang-apple'
    ...
}

switch $cxx.target.cpu: regex.match
{
  case 'i[3-6]86'
    ...
  case 'x86_64'
    ...
}
```

### Loops

```
for n: foo bar baz
{
  exe{$n}: cxx{$n}
}

i = [uint64] 0
while ($i != 10)
{
  ...
  i += 1
}

for n: foo bar baz
{
  if (...)
    continue
  if (...)
    break
  ...
}
```

### Eval contexts and function calls

```
info ($src_root != $out_root)
info ($src_root == $out_root ? 'in' : 'out')

macos = ($cxx.target.class == 'macos')
if ($macos || $linux)
  ...

info $empty($x)
info $regex.match($y, '[A-Z]')
info $path.leaf($src_base)
```

### Quoting and escaping

```
x = \$                         # Literal dollar sign
y = 'C:\Program Files'         # Single quote: no expansion
z = "C:\\Program Files"        # Double quote: expansion performed

cxx.poptions =+ "-I$out_root" "-I$src_root"   # Untyped concat (required for -I)
```

---

## Target importation

### Importing from a separate project

```
import libs = libhello%lib{hello}

exe{hello}: {hxx cxx}{**} $libs
```

The `import` directive resolves a project-qualified target to an absolute
target. If `config.import.libhello` is not set, build2 searches:

1. Subprojects of the importing project, then outer amalgamations and their
   subprojects.
2. Rule-specific search (e.g., compiler library search paths for installed
   libraries).

Specify the project location explicitly:

```
b hello/ config.import.libhello=libhello/
b configure: hello/ config.import.libhello=libhello-clang/
```

### Export stub

For a project to be importable it needs `build/export.build`:

```
# build/export.build

$out_root/
{
  include libhello/
}

export $out_root/libhello/$import.target
```

The export stub is loaded in a temporary scope with `src_root`, `out_root`,
and `import.target` set. It opens the exporting project's scope, loads the
appropriate buildfile, and returns the target with `export`.

### Project-local importation

```
import lib = lib{hello}       # No project name = project-local

exe{hello}: {hxx cxx}{**} $lib
```

The target must still appear in the export stub.

### Ad hoc importation

```
import pkgs = */              # Import all packages in sibling directories

./: $pkgs
```

Ad hoc importation uses absolute or relative directory paths. It does not
require an export stub.

---

## Library projects

### Library metadata protocol

When a library is imported, importers need to know its include paths and
transitive link requirements. This information is carried in
`cxx.export.*` target-specific variables.

**Classifying dependencies:**

- **Interface dependency** -- a library whose headers appear in your library's
  public headers or whose functions are called from your inline/template code.
  Must be listed in both prerequisites and `cxx.export.libs`.
- **Implementation dependency** -- used only in `.cxx` files. Listed only in
  prerequisites.

```
import intf_libs = libformat%lib{format}
import impl_libs = libprint%lib{print}

lib{hello}: ... $impl_libs $intf_libs

lib{hello}:
{
  cxx.export.poptions = "-I$out_root" "-I$src_root"
  cxx.export.libs = $intf_libs
}

liba{hello}: cxx.export.poptions += -DLIBHELLO_STATIC
libs{hello}: cxx.export.poptions += -DLIBHELLO_SHARED
```

### Static vs shared library control

```
b config.bin.lib=shared          # Build only shared library
b config.bin.lib=static          # Build only static library
b config.bin.lib=both            # Build both (default)
b config.bin.exe.lib=static      # Link executables to static libraries
```

### Shared library versioning

```
lib{hello}: bin.lib.version = "-$version.major.$version.minor"
```

Platform-independent version is embedded as a suffix. Platform-specific
versions can also be supplied (currently only implemented on Linux):

```
lib{hello}: bin.lib.version = -1.2 linux@3
```

---

## Testing

### Simple tests

```
exe{hello}: test = true
exe{hello}: test.arguments = 'World'
exe{hello}: file{test.out}: test.stdout = true
```

Run tests:

```
b test
```

### Testscript-based tests

List `testscript` as a prerequisite:

```
exe{hello}: {hxx cxx}{**} testscript
```

Example `testscript`:

```
: basics
:
$* 'World' >'Hello, World!'

: missing-name
:
$* 2>>EOE != 0
error: missing name
EOE
```

---

## Installation

```
b install config.install.root=/tmp/install/
b uninstall config.install.root=/tmp/install/
```

Install locations (all relative to `config.install.root`):

| Name | Default path |
|------|-------------|
| `bin` | `exec_root/bin/` |
| `lib` | `exec_root/lib/` |
| `include` | `data_root/include/` |
| `doc` | `share/doc/<project>/` |
| `pkgconfig` | `lib/pkgconfig/` |

Set installation location for headers:

```
hxx{*}:
{
  install         = include/libhello/
  install.subdirs = true
}
```

Disable installation of a target:

```
tests/: install = false
doc{INSTALL}@./: install = false
```

---

## Subprojects and amalgamations

A project can contain other projects. The outer project is the
**amalgamation** and the inner ones are **subprojects**.

build2 automatically searches for subprojects in the root directory of a
project. To place a subproject elsewhere, declare it explicitly:

```
# bootstrap.build
project = hello
subprojects = extras/libhello/
```

Subprojects inherit the configuration of their amalgamation. The subproject's
`build/config.build` records only local overrides and references the parent.

Import resolution searches the current project's subprojects and amalgamation
chain automatically, so `config.import.*` does not need to be set when
building within an amalgamation.

---

## Diagnostics and debugging

```
b --dump match              # Dump build state after rule matching
b --dump load               # Dump build state after loading
b --dump-scope /tmp/hello/hello/  # Limit dump to a specific scope
b --dump-target exe{hello}  # Limit dump to a specific target

b -s                        # Serial execution, stop at first error
b -s -v                     # Serial + show logical commands
b -s -V                     # Serial + show actual commands
b -s --verbose 4            # Serial + rule matching trace

b --trace-execute 'obje{hello}'   # Show dependency chain for target
b --mtime-check                   # Diagnose spurious rebuilds
b --stat                          # Execution statistics
```

Within buildfiles:

```
info $x               # Print variable value
dump                  # Dump current scope
dump exe{hello}       # Dump specific target
info $(obj{main}: cxx.poptions)  # Print target-specific variable
```
