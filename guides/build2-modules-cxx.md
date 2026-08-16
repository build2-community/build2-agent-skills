# build2 cxx Module -- C++ Compilation, Modules, and Cross-Compilation

_Use for: C++ compilation configuration, C++20 named modules, Objective-C++,
cxx predefined macros, cross-compilation setup, compiler/linker options
reference, and pkg-config integration._

## When to use

- You are configuring C++ compilation (`using cxx`, `cxx.std`, `config.cxx`).
- You are working with C++20 named modules (`cxx.features.modules`).
- You need to set up cross-compilation with a cross-compiler or sysroot.
- You need the compiler/linker options variable quick-reference table.
- You are integrating with system libraries via pkg-config.

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

### Compiler mode

Set `cxx.std` and any unconditional base `cxx.mode` before
`using cxx`. Configured mode (the extra words in `config.cxx`) is
then appended to the buildfile value. `cxx.std` is translated into
mode (`-std=`, `/std:c++20`, `/Zc:__cplusplus`). The mode list
appears last on the compile line, after `poptions` and `coptions`.

To append a flag after those std-derived options, use `cxx.mode +=`
at project root after `using cxx`. `cxx.class` and `cxx.target.*`
are available then. See
[`buildfile-compile-options.md`](../HOWTO/buildfile-compile-options.md#put-a-flag-last-with-cxxmode).

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
| `cxx.export.libs` | Libraries consumers need to link |

`cxx.export.coptions` does not exist by design: a library cannot impose
compiler flags on its consumers. If consumers need a specific compiler option
(for example, an ISA flag required by unconditionally-included SIMD headers),
they must set it themselves in their own `root.build`.

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
  Importation of Installed Libraries section in
  [build2-modules-cc.md](build2-modules-cc.md)).

Variables relevant to `pkg-config` integration:

- `config.cc.pkgconfig.sysroot` -- prepend this path to all absolute `-I`/
  `-L` paths from `.pc` files (for sysroot-relocated libraries).

For build2-built libraries, `pkg-config` files (`pc{}`, `pca{}`, `pcs{}`) are
generated and installed automatically with the appropriate `Cflags`, `Libs`,
and custom `cxx.*` variables for C++ modules support.

## See Also

- [`build2-modules-cc.md`](build2-modules-cc.md) -- cc module: C-common infrastructure, DLL export, compilation database
- [`build2-modules-c.md`](build2-modules-c.md) -- c module: C-specific compilation
- [`build2-modules-bin.md`](build2-modules-bin.md) -- bin module: binary target type hierarchy
- [`HOWTO/disable-shared-lib-per-platform.md`](../HOWTO/disable-shared-lib-per-platform.md) -- disabling the shared library variant per platform
