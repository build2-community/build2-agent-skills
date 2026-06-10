# build2 C/C++ Compilation Modules: bin, cc, c, cxx

This guide covers the build2 modules that handle binary targets and C-family
compilation: `bin`, `cc`, `c`, and `cxx`. It is derived from the build2 build
system manual.

---

## bin Module

The `bin` module provides binary target types and rules for building archives,
shared libraries, executables, and their associated artifacts. It is loaded
automatically by the `c` and `cxx` modules, but can also be loaded explicitly
with `using bin`.

### Binary Target Type Hierarchy

```
             target----------------.
               |                   |
              ...                  |
               |                   |
.------------file-----------.    lib
|      |      |     |     |  |    libul
|    libue  obje  bmie  hbmie def   obj
liba  libua  obja  bmia  hbmia      bmi
libs  libus  objs  bmis  hbmis      hbmi
```

### lib{}, liba{}, libs{}

`liba{}` and `libs{}` represent static (archive) and shared library targets,
respectively.

`lib{}` is a group containing `liba{}` and/or `libs{}` members. A rule that
encounters a `lib{}` prerequisite selects the member appropriate for the target
being built, or builds all members according to the `bin.lib` variable.

File extensions are assigned automatically by the matching rules based on the
target platform.

### libul{}, libue{}, libua{}, libus{}

The `libu*{}` types represent utility libraries -- static libraries whose
object files are appropriate for linking into a specific output type.

- `libue{}` -- object files suitable for linking into an executable
- `libua{}` -- object files suitable for linking into a static library
- `libus{}` -- object files suitable for linking into a shared library
- `libul{}` -- group with `libua{}` and/or `libus{}` members

Where possible, utility libraries are built in thin archive mode. The correct
member is selected automatically when a `libul{}` is encountered as a
prerequisite.

### obj{}, obje{}, obja{}, objs{}

The `obj*{}` types represent compiled object files.

- `obje{}` -- for linking into an executable
- `obja{}` -- for linking into a static library
- `objs{}` -- for linking into a shared library
- `obj{}` -- group that selects the appropriate member automatically

build2 uses distinct object files for executables, static libraries, and shared
libraries. The distinction between static and shared accommodates requirements
such as position-independent code (`-fPIC`) in shared libraries.

### bmi{}, bmie{}, bmia{}, bmis{}

The `bmi*{}` types represent binary module interfaces (BMI) for C++20 named
modules.

- `bmie{}` -- BMI for linking into an executable
- `bmia{}` -- BMI for linking into a static library
- `bmis{}` -- BMI for linking into a shared library
- `bmi{}` -- group that selects the appropriate member automatically

### hbmi{}, hbmie{}, hbmia{}, hbmis{}

The `hbmi*{}` types represent binary module interfaces for C++20 header units.
They follow the same pattern as `bmi*{}`.

### def{}

The `def{}` target type represents Windows module definition files and has the
fixed default extension `.def`.

---

## cc Module

The `cc` module provides the common compilation and linking framework for all
C-family languages. The `c` and `cxx` modules are built on top of it. Most
configuration and compilation logic lives in `cc` rather than the
language-specific modules.

### C-Common Configuration Variables

The following variables can be set before loading a `cc`-based module. The
`config.*` variants are the user-facing configuration variables. The shorter
names are the effective (read-only after load) variables derived from them.

```
config.c
config.cxx
  cc.id             # Compiler family ID (gcc, clang, msvc, ...)

  cc.target         # Full target triplet (e.g. x86_64-linux-gnu)
  cc.target.cpu
  cc.target.vendor
  cc.target.system
  cc.target.version
  cc.target.class   # Simplified class: linux, windows, macos, ...

config.cc.poptions
  cc.poptions       # Preprocessor options (-I, -D, ...)

config.cc.coptions
  cc.coptions       # Compiler options (-O2, -Wall, ...)

config.cc.loptions
  cc.loptions       # Linker options (-L, -Wl,...)

config.cc.aoptions
  cc.aoptions       # Archiver options

config.cc.libs
  cc.libs           # Additional libraries to link (-lfoo, ...)

config.cc.internal.scope
  cc.internal.scope # Controls which headers are treated as internal

config.cc.reprocess
  cc.reprocess      # Force reprocessing of compiler mode options

config.cc.pkgconfig.sysroot  # Sysroot for rewriting pkg-config -I/-L paths

config.cc.compiledb           # Simplified compilation database control
config.cc.compiledb.name      # Database name(s) and path(s)
config.cc.compiledb.filter    # Enable/disable writing to databases
config.cc.compiledb.filter.input   # Filter by input target type
config.cc.compiledb.filter.output  # Filter by output target type
```

### Compiler Mode Option Cross-Hinting

Mode options are cross-hinted between `config.c` and `config.cxx`: if one is
specified but not the other, mode options from the specified one are added to
the absent one automatically. This is appropriate for architecture flags but
may not be appropriate for runtime flags:

```
# Ok -- architecture flag applies to both:
$ b config.cxx="g++ -m32"

# Not OK -- stdlib flag is compiler-specific:
$ b config.cxx="clang++ -stdlib=libc++"
```

### Binary-Specific Compile Options

Compile options (`*.poptions`, `*.coptions`) can be set on `exe{}` or `lib{}`
targets. They propagate to synthesized `obj{}`/`bmi{}` targets for the binary's
source prerequisites. This propagation does not apply to explicit (non-
synthesized) `obj{}`/`bmi{}` prerequisites.

```
exe{foo}: cxx{foo} obj{common}
{
  cc.poptions += -DFOO
}

exe{bar}: cxx{bar} obj{common}
{
  cc.poptions += -DBAR
}

obj{common}: cxx{common}
{
  cc.poptions += -DCOMMON
}
```

In this example, `cxx{foo}` is compiled with `-DFOO`, `cxx{bar}` with `-DBAR`,
and `cxx{common}` with `-DCOMMON`.

If a source prerequisite is shared between several binaries, the propagated
compile option values must match, otherwise the build fails.

Example showing static/shared library builds with distinct macros:

```
./: lib{foo}: {hxx cxx}{*-foo}
./: lib{bar}: {hxx cxx}{*-bar}

cxx.poptions =+ "-I$out_root" "-I$src_root"

lib{foo}:
{
  cxx.poptions += -DFOO
  cxx.export.poptions = "-I$out_root" "-I$src_root"
}

liba{foo}:
{
  cxx.poptions += -DLIBFOO_STATIC_BUILD
  cxx.export.poptions += -DLIBFOO_STATIC
}

libs{foo}:
{
  cxx.poptions += -DLIBFOO_SHARED_BUILD
  cxx.export.poptions += -DLIBFOO_SHARED
}
```

Note that target type/pattern-specific assignments for `obj{}` do not apply to
options set on `lib{}`/`exe{}`. To ensure the pattern applies to both, include
both types:

```
{obj exe}{*}: cxx.poptions += -DTARGET
```

### C-Common Target Types

Every `cc`-based module defines these target types in addition to the
language-specific ones:

```
.--file--.
|        |
h       pc
         |
        pca
        pcs
```

`h{}` represents a C header file. Because virtually all C-family compilation
involves C headers, this type is defined by all `cc`-based modules.

#### pc{}, pca{}, pcs{}

The `pc*{}` types represent `pkg-config` files used for library metadata
export.

- `pc{}` -- common file, fixed default extension `.pc`
- `pca{}` -- static library file, fixed default extension `.static.pc`
- `pcs{}` -- shared library file, fixed default extension `.shared.pc`

### Compilation Internal Scope

The `cc`-based modules have a notion of a project's internal scope. During
compilation, a header search path (`-I`) exported by a library that is outside
the internal scope is treated as external, and the corresponding `-I` option is
translated to an external header search path option:

- GCC/Clang: `-isystem`
- MSVC 16.10+: `/external:I` (with `/external:W0` added automatically)

This suppresses compiler warnings from external headers.

The internal scope is set with `cxx.internal.scope` (or `c.internal.scope`)
before loading the module, and can be overridden by the user with
`config.cxx.internal.scope`:

```
# root.build

cxx.std = latest
cxx.internal.scope = current

using cxx
```

Valid values:

```
current  -- current root scope (where variable is assigned)
base     -- target's base scope
root     -- target's root scope
bundle   -- target's bundle amalgamation
strong   -- target's strong amalgamation
weak     -- target's weak amalgamation
global   -- global scope (everything is internal)
```

Priority order (highest first):
1. `config.cxx.internal.scope`
2. `config.cc.internal.scope`
3. Effective scope from bundle amalgamation
4. `cxx.internal.scope`
5. `cc.internal.scope`

To whitelist specific libraries (always treat as internal regardless of
location):

```
# root.build

cxx.std = latest
cxx.internal.scope = current
cxx.internal.libs = foo 'bar-*'

using cxx
```

### Automatic DLL Symbol Exporting

The `bin.def` module (auto-loaded by `c` and `cxx` for `*-win32-msvc` targets)
generates symbol-exporting `.def` files. Recommended arrangement:

```
lib{foo}: libul{foo}: {hxx cxx}{**} ...

libs{foo}: def{foo}: include = ($cxx.target.system == 'win32-msvc')
def{foo}: libul{foo}

if ($cxx.target.system == 'mingw32')
  cxx.loptions += -Wl,--export-all-symbols
```

This uses `.def` for MSVC (including Clang targeting MSVC) and
`--export-all-symbols` for MinGW.

### Compiler Predefined Macro Extraction

Load `*.predefs` after the main module to extract predefined compiler macros:

```
# root.build

using c
using c.predefs
```

```
# buildfile

[rule_hint=c.predefs] h{predefs}:           # Pure predefs.
[rule_hint=c.predefs] h{predefs}: h{config} # Custom predefs.
```

Output can be a C header, a JSON file, or a buildfile:

```
c.predefs.poptions = true

[rule_hint=c.predefs] h{predefs}:         h{config}
[rule_hint=c.predefs] json{predefs}:      h{config}
[rule_hint=c.predefs] buildfile{predefs}: h{config}
{
  c.predefs.macros = FOO BAR BAZ BIZ
}
```

Variables controlling the rule:

- `[bool] *.predefs.poptions` -- include `*.poptions` in compiler invocation
- `[string] *.predefs.default` -- default value for macros with no value
- `[string_map] *.predefs.macros` -- macros to extract (with optional rename)

Example rename syntax: `c.predefs.macros = FOO __SIZEOF_SIZE_T__@SIZEOF_SIZE_T`

### Importation of Installed Libraries

Build2 integrates installed library search into target importation. Example:

```
import libs = libbar%lib{Xfoo}
```

The search algorithm:
1. Combines compiler system library directories with user directories (from
   `-L` options in `*.loptions`) to build an ordered search list.
2. Searches for `libXfoo.so` and `libXfoo.a` (on Linux) in each directory. If
   only one variant is found, the other is assumed unavailable. If neither is
   found, the directory is checked for a `pkg-config` file to detect a binless
   (header-only) library.
3. Searches the `pkgconfig/` subdirectory for the `.pc` file. Looks for
   `.static.pc` or `.shared.pc` first, falling back to the common `.pc`.

`pkg-config` file name resolution order (for import `libbar%lib{Xfoo}`):
1. `libXfoo.pc`
2. `Xfoo.pc`
3. `libxfoo.pc` (lowercase)
4. `xfoo.pc` (lowercase)
5. `libbar.pc` (project name; only if project-qualified)

The last entry is an escape hatch for libraries with unrelated `.pc` file
names, such as zlib:

```
import libs = zlib%lib{z}
```

#### Sysroot Rewriting for Installed Libraries

For cross-compilation scenarios where libraries are installed into a sysroot:

```
config.cc.pkgconfig.sysroot = /opt/target
```

When set, all absolute paths in `-I` and `-L` options extracted from `.pc`
files are rewritten to start with the specified sysroot. This is roughly
equivalent to the `PKG_CONFIG_SYSROOT_DIR` environment variable.

This is a workaround for third-party `.pc` files that do not handle
relocation. For build2-generated `.pc` files, use a relocatable installation
instead.

### Compilation Database

The `cc`-based modules can generate and maintain a
[JSON Compilation Database](https://clang.llvm.org/docs/JSONCompilationDatabase.html)
for use with static analyzers, language servers, and IDEs.

Simplified interface -- one database per project:

```
$ bdep init @gcc config.cc.compiledb=libhello
```

Place database in project source directory as `compile_commands.json`:

```
$ bdep init @gcc config.cc.compiledb=./
```

This shortcut treats `./` as equivalent to:

```
config.cc.compiledb=<dir>@.../<dir>/compile_commands.json
```

Dump to stdout (forces recompilation of all targets):

```
$ b -n hello/ libhello/ config.cc.compiledb=- >/tmp/compiledb.json
```

Lower-level interface for multiple databases and filtering:

```
config.cc.compiledb.name           =  <name>[@<path>]...
config.cc.compiledb.filter         =  [<name>@]<bool>...
config.cc.compiledb.filter.input   =  [<name>@]<target-type>...
config.cc.compiledb.filter.output  =  [<name>@]<target-type>...
```

Filter out `obja{}` entries for libraries (keep only `obje{}` and `objs{}`):

```
$ bdep init @gcc               \
  config.cc.compiledb=libhello \
  config.cc.compiledb.filter.output='obje objs'
```

Keep only C and C++ source entries:

```
$ bdep init @gcc               \
  config.cc.compiledb=libhello \
  config.cc.compiledb.filter.input='c cxx'
```

### GCC Compiler Toolchain

The GCC compiler id is `gcc`.

### Clang Compiler Toolchain

- Vanilla Clang id: `clang` (including when targeting MSVC runtime)
- Apple Clang id: `clang-apple`
- Clang's `cl` compatibility driver id: `msvc-clang`

On Windows, `cc` searches for Clang in the following order:
1. `PATH` environment variable or absolute path
2. Bundled with the current Visual Studio command prompt (`%VCINSTALLDIR%\Tools\Llvm\bin`)
3. Latest installed Visual Studio

Default mode (32 or 64-bit) depends on Clang configuration. Override with
`-m32`/`-m64`:

```
> b "config.cxx=clang++ -m64"
```

Default MSVC runtime is multi-threaded shared (`/MD`). To select an
alternative runtime manually:

```
> b "config.cxx=clang++ -nostdlib -D_MT" ^
    config.cc.libs=/DEFAULTLIB:libcmt
```

### MSVC Compiler Toolchain

The MSVC compiler id is `msvc`.

MSVC binaries are target-specific (no `-m32`/`-m64`). Mode is selected by
which `cl.exe` binary is invoked.

Specifying the compiler:
- `config.cxx=cl` with `cl` in `PATH` -- uses the current VS command prompt
  environment
- `cl` not in `PATH` -- auto-detects latest Visual Studio, uses 64-bit mode
- Absolute path to `cl.exe` -- detects the VS installation and mode from the
  path

```
> b "config.cxx='...\MSVC\14.23.28105\bin\Hostx64\x86\cl'"
```

Auto-detection is only available for Visual Studio 15 (2017) and later.

Default MSVC runtime is multi-threaded shared (`/MD`). To select an
alternative:

```
> b "config.cxx=cl /MT"
```

---

## c Module

The `c` module provides C compilation and linking support. Most functionality
is provided by the `cc` module. Load with:

```
using c
```

### C Configuration Variables

```
config.c
  c.path
  c.mode

config.c.id
  c.id          # Compiler family: gcc, clang, msvc, ...
  c.id.type
  c.id.variant
  c.class

config.c.version
  c.version
  c.version.major
  c.version.minor
  c.version.patch
  c.version.build

config.c.target
  c.target          # Full target triplet
  c.target.cpu
  c.target.vendor
  c.target.system
  c.target.version
  c.target.class    # linux, windows, macos, ...

config.c.std
  c.std             # C standard: c99, c11, c17, latest, ...

config.c.poptions
  c.poptions        # Preprocessor options

config.c.coptions
  c.coptions        # Compiler options

config.c.loptions
  c.loptions        # Linker options

config.c.aoptions
  c.aoptions        # Archiver options

config.c.libs
  c.libs            # Additional libraries

config.c.internal.scope
  c.internal.scope  # Internal scope for warning suppression
```

### C Target Types

```
.--file--.
|   |    |
c   m    S
h
```

- `c{}` -- C source file, default extension `.c`
- `h{}` -- C header file, default extension `.h`
- `m{}` -- Objective-C source file (requires `c.objc` submodule)
- `S{}` -- Assembler with C preprocessor file (requires `c.as-cpp` submodule)

Extensions can be customized with the `extension` variable.

### Objective-C Compilation

Load the `c.objc` submodule after `c`:

```
# root.build

using c
using c.objc
```

```
# buildfile

lib{hello}: {h c}{*}
lib{hello}: m{*}: include = ($c.target.class == 'macos')
```

Linking Objective-C targets uses the C compiler driver. No Objective-C runtime
library (such as `-lobjc`) is linked automatically.

### Assembler with C Preprocessor Compilation

Load the `c.as-cpp` submodule after `c`:

```
# root.build

using c
using c.as-cpp
```

```
# buildfile

assembler = ($c.class == 'gcc' && $c.target.cpu == 'x86_64')

exe{hello}: S{hello}: include = $assembler
exe{hello}: c{hello}: include = (!$assembler)
```

The default extension for `S{}` is `.S` (uppercase). `*.coptions` are passed
to the compiler when compiling assembler files. To pass additional options:

```
obj{hello}:
{
  c.poptions += -DHELLO_RESULT=1
  c.coptions += -Wa,--no-pad-sections
}
```

### C Predefined Macros

Load `c.predefs` after `c`. See the cc module section for full details.

```
using c
using c.predefs
```

```
[rule_hint=c.predefs] h{predefs}:
```

---

## cxx Module

The `cxx` module provides C++ compilation and linking support. Most
functionality is provided by the `cc` module. Load with:

```
using cxx
```

### C++ Configuration Variables

```
config.cxx
  cxx.path
  cxx.mode

config.cxx.id
  cxx.id          # Compiler family: gcc, clang, msvc, ...
  cxx.id.type
  cxx.id.variant
  cxx.class

config.cxx.version
  cxx.version
  cxx.version.major
  cxx.version.minor
  cxx.version.patch
  cxx.version.build

config.cxx.target
  cxx.target          # Full target triplet
  cxx.target.cpu
  cxx.target.vendor
  cxx.target.system
  cxx.target.version
  cxx.target.class    # linux, windows, macos, ...

config.cxx.std
  cxx.std             # C++ standard: c++14, c++17, c++20, latest, ...

config.cxx.poptions
  cxx.poptions        # Preprocessor options

config.cxx.coptions
  cxx.coptions        # Compiler options

config.cxx.loptions
  cxx.loptions        # Linker options

config.cxx.aoptions
  cxx.aoptions        # Archiver options

config.cxx.libs
  cxx.libs            # Additional libraries

config.cxx.internal.scope
  cxx.internal.scope  # Internal scope for warning suppression

config.cxx.translate_include
  cxx.translate_include  # Header unit translation map
```

### C++ Target Types

```
.--file--.
|        |
cxx     mm
hxx
ixx
txx
mxx
```

- `cxx{}` -- C++ source file, default extension `.cxx`
- `hxx{}` -- C++ header file, default extension `.hxx`
- `ixx{}` -- C++ inline file, default extension `.ixx`
- `txx{}` -- C++ template file, default extension `.txx`
- `mxx{}` -- C++ module interface file, default extension `.mxx`
- `mm{}` -- Objective-C++ source file (requires `cxx.objcxx` submodule)

Extensions can be customized with `extension`:

```
using cxx

cxx{*}: extension = cpp
hxx{*}: extension = hpp
mxx{*}: extension = cppm
```

### C++20 Modules Support

C++ modules must be explicitly enabled:

```
# root.build

cxx.std = latest
cxx.features.modules = true

using cxx

mxx{*}: extension = mxx
cxx{*}: extension = cxx
```

#### Building Modules

Module interface units are listed as prerequisites alongside source files:

```
exe{hello}: cxx{main} {mxx cxx}{hello}
```

Or with wildcards:

```
exe{hello}: {mxx cxx}{*}
```

Modules in a library:

```
exe{hello}: cxx{main} lib{hello}
lib{hello}: {mxx cxx}{hello}
```

If a library consists only of module interface units, it is by default binful
(because compiling a module interface always produces an object file). To
request binless treatment:

```
lib{hello}: mxx{hello}
{
  bin.binless = true
}
```

Build2 resolves module imports automatically by guessing which interface file
implements a module name based on a fuzzy match. All of the following file
names resolve to `hello.core`:

```
hello-core.mxx
hello_core.mxx
HelloCore.mxx
hello/core.mxx
```

To specify the module name explicitly when the file name cannot be guessed:

```
mxx{foobar}@./: cxx.module_name = hello
```

Standard library modules (`std` and `std.compat`) are resolved in a
compiler-specific manner.

#### Module Symbol Exporting

For shared libraries on Windows, symbols must be explicitly exported. With
modules, enable managed symbol exporting:

```
cxx.std = latest
cxx.features.modules = true
cxx.features.symexport = true

using cxx
```

Once enabled, build2 defines `__symexport` to the appropriate value for each
build type. Use it in module interface units:

```
export module hello;

import std;

export __symexport void say_hello (const std::string&);
```

#### Module Installation

Binary module interfaces are not installed. Instead, module interface sources
are installed (by default to the same location as headers). The library's
`.pc` file lists exported modules in `<name>=<path>` form:

```
cxx.modules = hello.core=/usr/include/hello/core.mxx \
              hello.extra=/usr/include/hello/extra.mxx
```

Module partition names encode `:` as `..`:

```
cxx.modules = hello..core=/usr/...
```

Additional module properties in the `.pc` file:

```
cxx.module_symexport.hello.core = true
cxx.module_preprocessed.hello.core = all
```

Valid `preprocessed` values: `none`, `includes`, `modules`, `all`.

#### Modules Design Guidelines

- Prefer modules of conceptually-related, commonly-used entities over mega-
  modules or mini-modules.
- Use a separate module implementation unit unless the implementation is mostly
  inline/template to avoid unnecessary recompilations and to maximize build
  parallelism.
- Place `#include` directives in the global module fragment (before the module
  declaration), not in the module purview.
- Import other modules in the module purview.
- Only re-export the minimum necessary. Re-export when building aggregate
  modules out of submodules, or when one module extends another.
- Name public modules starting with the library's namespace name.
- Prefix all public `bash` module functions with the library name to avoid
  clashes.

Module interface unit template:

```
// Module interface unit.

module;                    // Start of global module fragment.

<header includes>

export module <name>;      // Start of module purview.

<module imports>

<special header includes>  // Configuration, export, etc.

<module interface>

<inline/template includes>
```

Module implementation unit template:

```
// Module implementation unit.

module;                    // Start of global module fragment.

<header includes>

module <name>;             // Start of module purview.

<extra module imports>     // Only additional to interface.

<module implementation>
```

### Objective-C++ Compilation

Load the `cxx.objcxx` submodule after `cxx`:

```
# root.build

using cxx
using cxx.objcxx
```

```
# buildfile

lib{hello}: {hxx cxx}{*}
lib{hello}: mm{*}: include = ($cxx.target.class == 'macos')
```

Linking Objective-C++ targets uses the C++ compiler driver. No Objective-C
runtime library (such as `-lobjc`) is linked automatically.

### C++ Predefined Macros

Load `cxx.predefs` after `cxx`. See the cc module section for full details.

```
using cxx
using cxx.predefs
```

```
[rule_hint=cxx.predefs] hxx{predefs}:
```

---

## Cross-Compilation and Target Configuration

The `config.c` / `config.cxx` variables accept a compiler path plus optional
mode flags. The compiler is used to auto-detect the target triplet and all
derived `*.target.*` variables.

Key target information variables (shown for `cxx`; same pattern for `c`):

| Variable | Example value | Meaning |
|---|---|---|
| `cxx.target` | `x86_64-linux-gnu` | Full target triplet |
| `cxx.target.cpu` | `x86_64` | CPU architecture |
| `cxx.target.vendor` | `pc` | Vendor component |
| `cxx.target.system` | `linux-gnu` | OS/ABI component |
| `cxx.target.class` | `linux` | Simplified OS class |
| `cxx.id` | `gcc` | Compiler family |
| `cxx.id.type` | `gcc` | Base compiler type |
| `cxx.id.variant` | `` | Variant (e.g. `apple` for Apple Clang) |
| `cxx.version.major` | `13` | Compiler major version |
| `cxx.version.minor` | `2` | Compiler minor version |

To cross-compile, specify the cross-compiler:

```
$ b config.cxx=aarch64-linux-gnu-g++
```

For sysroot with pkg-config rewriting:

```
$ b config.cxx=aarch64-linux-gnu-g++ \
    config.cc.pkgconfig.sysroot=/opt/sysroot
```

The `config.cc.reprocess` variable can be set to force reprocessing of
compiler mode options when they affect the compiler identity or target.

---

## Compiler and Linker Options: Variables at a Glance

### Build-time Options (affect this target's compilation/linking)

| Variable | Applies to | Purpose |
|---|---|---|
| `cc.poptions` | All cc-based | Preprocessor options (-I, -D) |
| `cc.coptions` | All cc-based | Compiler options (-O2, -g, ...) |
| `cc.loptions` | All cc-based | Linker options (-L, -Wl,...) |
| `cc.aoptions` | All cc-based | Archiver options |
| `cc.libs` | All cc-based | Extra link libraries |
| `c.poptions` | C only | C preprocessor options |
| `c.coptions` | C only | C compiler options |
| `c.loptions` | C only | C linker options |
| `c.libs` | C only | C extra libraries |
| `cxx.poptions` | C++ only | C++ preprocessor options |
| `cxx.coptions` | C++ only | C++ compiler options |
| `cxx.loptions` | C++ only | C++ linker options |
| `cxx.libs` | C++ only | C++ extra libraries |

### Export Options (propagated to consumers of a library)

| Variable | Purpose |
|---|---|
| `cxx.export.poptions` | Preprocessor options consumers need |
| `cxx.export.coptions` | Compiler options consumers need |
| `cxx.export.loptions` | Linker options consumers need |
| `cxx.export.libs` | Libraries consumers need to link |

Typical library `buildfile` pattern:

```
lib{hello}: {hxx cxx}{**}
{
  cxx.export.poptions = "-I$out_root" "-I$src_root"
}

liba{hello}:
{
  cxx.poptions += -DLIBHELLO_STATIC_BUILD
  cxx.export.poptions += -DLIBHELLO_STATIC
}

libs{hello}:
{
  cxx.poptions += -DLIBHELLO_SHARED_BUILD
  cxx.export.poptions += -DLIBHELLO_SHARED
}
```

---

## System Library Dependencies and pkg-config Integration

Build2 uses `pkg-config` to find metadata for installed libraries. Key
integration points:

- Build2 looks for `.static.pc`, `.shared.pc`, and common `.pc` files in
  `pkgconfig/` subdirectories.
- The search directories combine compiler system directories with user-
  specified `-L` paths from `*.loptions`.
- Five alternative `.pc` file base names are tried in order (see the
  Importation of Installed Libraries section above).

Variables relevant to `pkg-config` integration:

- `config.cc.pkgconfig.sysroot` -- prepend this path to all absolute `-I`/
  `-L` paths from `.pc` files (for sysroot-relocated libraries).

For build2-built libraries, `pkg-config` files (`pc{}`, `pca{}`, `pcs{}`) are
generated and installed automatically with the appropriate `Cflags`, `Libs`,
and custom `cxx.*` variables for C++ modules support.
