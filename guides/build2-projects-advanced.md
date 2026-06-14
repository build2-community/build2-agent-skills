# build2 Advanced Projects -- Importation, Libraries, Testing, Installation

_Use for: importing targets from other projects, library metadata protocol,
static vs shared control, shared library versioning, testscript basics,
install locations, subprojects and amalgamations, and build diagnostics._

## When to use

- You need to import a library from another project (`import libs = ...`).
- You are writing a library and need to configure `cxx.export.*` variables.
- You need to control static vs shared library builds or versioning.
- You are adding testscript-based tests to a project.
- You need to configure install locations for headers, binaries, or docs.
- You are working with subprojects or amalgamations.
- You need diagnostics tools (`b --dump`, `-s`, `--trace-execute`).

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

## See Also

- [`build2-intro-concepts.md`](build2-intro-concepts.md) -- foundational concepts: targets, scopes, modules, variables
- [`build2-buildfile-language.md`](build2-buildfile-language.md) -- language syntax reference
- [`guides/testscript-summary.md`](testscript-summary.md) -- full testscript language reference
- [`HOWTO/header-only-library.md`](../HOWTO/header-only-library.md) -- binless (header-only) libraries
- [`HOWTO/library-provides-main.md`](../HOWTO/library-provides-main.md) -- library that provides main()
- [`build2-module-hello.md`](build2-module-hello.md) -- authoring a custom build2 module (the natural next step after importation)
- [`HOWTO/target-metadata.md`](../HOWTO/target-metadata.md) -- exporting metadata with targets
- [`HOWTO/for-install-conflicts.md`](../HOWTO/for-install-conflicts.md) -- resolving for-install build conflicts
