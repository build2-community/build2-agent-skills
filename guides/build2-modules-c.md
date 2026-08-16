# build2 c Module -- C Compilation

_Use for: C compilation configuration variables, C target types, Objective-C
compilation, assembler with C preprocessor, and C predefined macros._

## When to use

- You are setting up C compilation in a buildfile (`using c`).
- You need to configure `config.c` or `c.std`.
- You are compiling Objective-C (`c.objc`) or assembler files (`c.as-cpp`).
- You want to extract predefined compiler macros (`c.predefs`).

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

To append a C compile flag after `c.std` (which is folded into
`c.mode`), use `c.mode +=` at project root after `using c`. See
[`buildfile-compile-options.md`](../HOWTO/buildfile-compile-options.md#put-a-flag-last-with-cxxmode).

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

### Platform multi-dot sources

Upstream often ships pairs such as `clock.posix.c` / `clock.windows.c`. Use
trailing `...` in the name pattern so intermediate dots stay part of the
name, and gate participation with `include`:

```
lib{foo}: c{*.windows...}: include = ($c.target.class == 'windows')
lib{foo}: c{*.posix...}:   include = ($c.target.class != 'windows')
```

See [name patterns](build2-directives-patterns.md) (multi-dot names section)
for details.

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

## See Also

- [`build2-modules-cc.md`](build2-modules-cc.md) -- cc module: C-common infrastructure, DLL export, toolchain detection
- [`build2-modules-bin.md`](build2-modules-bin.md) -- bin module: binary target type hierarchy
- [`build2-modules-cxx.md`](build2-modules-cxx.md) -- cxx module: C++ compilation
