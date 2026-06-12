# build2 Build System -- Introduction and Core Concepts

_Use for: understanding what build2 is, targets and target types, the build
graph, buildfile and project structure, scopes, modules, variables, and
operations vs meta-operations._

## When to use

- You are new to build2 and need foundational concepts.
- You need to understand the target type system, scopes, or variable semantics.
- You need to know what modules are available and when to load them.
- You are setting up a new standard-layout project.

---

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

## See Also

- [`build2-buildfile-language.md`](build2-buildfile-language.md) -- minimal example, invoking b, full buildfile language reference
- [`build2-projects-advanced.md`](build2-projects-advanced.md) -- target importation, library projects, testing, installation
- [`build2-targets-variables.md`](build2-targets-variables.md) -- complete built-in target type and variable reference
- [`build2-modules-cc.md`](build2-modules-cc.md) -- cc module: compile/link option configuration
- [`b/README.md`](../b/README.md) -- b driver overview and common invocations
- [`HOWTO/README.md`](../HOWTO/README.md) -- practical recipes
