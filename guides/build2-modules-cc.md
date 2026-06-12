# build2 cc Module -- C-Common Compilation Infrastructure

_Use for: C-common configuration variables, compiler mode cross-hinting,
binary-specific compile options, h{}/pc{} target types, internal scope,
automatic DLL symbol exporting, predefined macro extraction, installed library
importation, compilation database, and GCC/Clang/MSVC toolchain notes._

## When to use

- You need to set compiler or linker options (`cc.poptions`, `cc.coptions`,
  `cc.loptions`) or understand how they propagate.
- You are configuring DLL symbol exporting on Windows.
- You need a compilation database for a language server or static analyzer.
- You are importing installed system libraries or pkg-config packages.
- You need to understand compiler toolchain detection (GCC, Clang, MSVC).

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

## See Also

- [`build2-modules-bin.md`](build2-modules-bin.md) -- bin module: binary target type hierarchy
- [`build2-modules-c.md`](build2-modules-c.md) -- c module: C-specific compilation
- [`build2-modules-cxx.md`](build2-modules-cxx.md) -- cxx module: C++ compilation, cross-compilation, options reference
- [`build2-modules-core.md`](build2-modules-core.md) -- core modules (config, test, install, dist)
