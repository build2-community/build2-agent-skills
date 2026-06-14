# libbuild2-hello -- Custom Build2 Module Reference

The `libbuild2-hello` package is the canonical reference implementation for
writing a custom build2 build system module. It demonstrates the minimal
structure a module must have: the C-linkage entry point, the `init()` function,
the symbol-export header, and the two-package (module + tests) layout.

Use this guide when authoring a new module from scratch. For the matching
development environment setup, see
[build2-module-dev-setup.md](build2-module-dev-setup.md).

---

## What a Build2 Module Is

A build2 module is a shared library (`libs{build2-<name>}`) that the build
system loads at configuration time. When a `buildfile` contains:

```
using hello
```

the build system:

1. Locates the `libbuild2-hello` package (installed or via
   `config.import.libbuild2_hello`).
2. `dlopen`s the shared library with a version-qualified suffix (e.g.,
   `libbuild2-hello-0.18.so`).
3. Calls the C entry point `build2_hello_load()`, which returns a
   `module_functions*` table.
4. Looks up the entry named `"hello"` in that table and calls its `init()`
   function.

Once `init()` returns, the module can register rules, declare variables, define
target types, or do anything else the `scope&` API allows.

---

## Package Layout

A module lives in two packages inside the same repository:

```
libbuild2-hello/             # the module library
libbuild2-hello-tests/       # separate test package
```

There is no root `buildfile` glue -- the two packages must be built in
separate build contexts (the module in a `build2`-type configuration, the
tests in a normal C++ configuration). The `packages.manifest` at the root
lists both.

### Module Package Internals

```
libbuild2-hello/
  build/
    bootstrap.build          # project name, using version/config/test/install/dist
    root.build               # cxx.std = latest; using cxx; extension vars
    export.build             # re-exports the built lib{} target
  libbuild2/hello/
    export.hxx               # LIBBUILD2_HELLO_SYMEXPORT macro
    init.hxx                 # declares build2_hello_load()
    init.cxx                 # implements init() and mod_functions[]
    buildfile                # lib{build2-hello} target
  buildfile                  # root: ./ members, doc, legal, manifest
  manifest
```

---

## The Entry Point

The shared library must export exactly one C-linkage function:

```cpp
extern "C" LIBBUILD2_HELLO_SYMEXPORT const module_functions*
build2_hello_load ();
```

It returns a null-terminated array of `module_functions` entries, one per
module name the library provides:

```cpp
static const module_functions mod_functions[] =
{
  {"hello", nullptr, init},
  {nullptr, nullptr, nullptr}
};

const module_functions*
build2_hello_load ()
{
  return mod_functions;
}
```

Each entry is `{name, boot_function, init_function}`. Pass `nullptr` for
`boot_function` if the module does not require bootstrapping (the common case).

---

## The `init()` Function

```cpp
bool
init (scope& rs,
      scope& bs,
      const location& l,
      bool first,
      bool optional,
      module_init_extra& extra)
```

| Parameter | Description |
|-----------|-------------|
| `rs` | Root scope of the project loading the module. Use this to declare project-wide variables and look up config values. |
| `bs` | Base scope -- the scope containing the `using` directive. For a `root.build` load this equals `rs`. |
| `l` | Source location of the `using` directive. Pass to diagnostics (`info(l)`, `fail(l)`). |
| `first` | `true` on the first call for this module in this build context. Use to avoid double-registration of rules or variables. |
| `optional` | `true` when loaded with `using? hello`. The module should not fail if optional functionality is unavailable. |
| `extra` | Reserved for future build system use. Pass through or ignore. |

Return `true` if the module was successfully initialized, `false` if it was
silently skipped (only valid when `optional` is true).

The minimal implementation from `libbuild2-hello`:

```cpp
bool
init (scope&, scope&, const location& l, bool, bool, module_init_extra&)
{
  info (l) << "module hello initialized";
  return true;
}
```

---

## The `boot()` Function

`boot()` is called during the bootstrap phase, before project configuration
is available. Its signature:

```cpp
void
boot (scope& rs, const location& l, module_init_extra& extra)
```

Pass `nullptr` as the boot entry in `mod_functions` if the module does not
need to run at bootstrap. Most modules do not need `boot()`.

A module that uses `boot()` must be loaded in `build/bootstrap.build` rather
than `build/root.build`. See [Bootstrap Modules](#bootstrap-modules) below.

---

## Symbol Export Header

Every module library needs a symbol-export header (`export.hxx`). It defines
a single macro (`LIBBUILD2_HELLO_SYMEXPORT`) whose value depends on how the
library is built or consumed:

| Macro defined by consumer/build | Expansion |
|---------------------------------|-----------|
| `LIBBUILD2_HELLO_STATIC` | empty (using static lib) |
| `LIBBUILD2_HELLO_STATIC_BUILD` | empty (building static lib) |
| `LIBBUILD2_HELLO_SHARED` | `__declspec(dllimport)` on Windows, empty elsewhere |
| `LIBBUILD2_HELLO_SHARED_BUILD` | `__declspec(dllexport)` on Windows, empty elsewhere |
| none of the above | empty (fallback, works but non-optimal on Windows) |

The four macros are set automatically by the `buildfile` via
`cxx.poptions` on the `obja{}` and `objs{}` targets:

```
obja{*}: cxx.poptions += -DLIBBUILD2_HELLO_STATIC_BUILD
objs{*}: cxx.poptions += -DLIBBUILD2_HELLO_SHARED_BUILD
```

Export to consumers is propagated via `cxx.export.poptions`:

```
liba{build2-hello}: cxx.export.poptions += -DLIBBUILD2_HELLO_STATIC
libs{build2-hello}: cxx.export.poptions += -DLIBBUILD2_HELLO_SHARED
```

---

## Library Buildfile

The module library `buildfile` follows a fixed pattern:

```
import impl_libs += build2%lib{build2}  # link against build2 core

lib{build2-hello}: {hxx ixx txx cxx}{**} $impl_libs

cxx.poptions =+ "-I$out_root" "-I$src_root"

obja{*}: cxx.poptions += -DLIBBUILD2_HELLO_STATIC_BUILD
objs{*}: cxx.poptions += -DLIBBUILD2_HELLO_SHARED_BUILD

lib{build2-hello}:
{
  cxx.export.poptions = "-I$out_root" "-I$src_root"
  cxx.export.libs = $intf_libs
}

liba{build2-hello}: cxx.export.poptions += -DLIBBUILD2_HELLO_STATIC
libs{build2-hello}: cxx.export.poptions += -DLIBBUILD2_HELLO_SHARED
```

### Load Suffix

The shared library must embed the build system interface version as a load
suffix so it is only loaded by a compatible build system:

```
# Get the interface version from lib{build2}, falling back to the running version.
iv = ($project($libbuild2) == [null]     \
      ? $($libbuild2: interface_version) \
      : [null])

ifn $iv
  iv = $build.version.interface

libs{build2-hello}: bin.lib.load_suffix = "-$iv"
```

### Library Version

Follow the standard pre-release vs release library versioning convention:

```
if $version.pre_release
  lib{build2-hello}: bin.lib.version = "-$version.project_id"
else
  lib{build2-hello}: bin.lib.version = "-$version.major.$version.minor"
```

### Install Path

Headers install into `include/libbuild2/hello/` preserving subdirectory
structure:

```
{hxx ixx txx}{*}:
{
  install         = include/libbuild2/hello/
  install.subdirs = true
}
```

---

## Manifest Requirements

```
: 1
name: libbuild2-hello
version: 0.1.0
summary: My custom build system module
license: MIT
depends: * build2 >= 0.18.0-
depends: * bpkg >= 0.18.0-
tests: * libbuild2-hello-tests == $
```

The `build2` and `bpkg` constraints use the open lower bound (`>=
0.18.0-`) to include pre-release builds. The `tests:` field links to the
separate test package and causes CI to build both together.

Do not add `builds: host` -- modules are automatically configured for the
host platform by the `--type build2` configuration (see
[build2-module-dev-setup.md](build2-module-dev-setup.md)).

---

## Loading the Module in a Project

A project that uses the module loads it in `build/root.build` (for normal
modules) or `build/bootstrap.build` (for bootstrap modules):

```
# build/root.build
using hello
```

To make loading optional (no error if the module is absent):

```
using? hello
```

During development, the module location is supplied via an import variable:

```
b configure: . config.import.libbuild2_hello=/path/to/build/
```

Or globally in `~/.build2/b.options`:

```
!config.import.libbuild2_hello=/home/.../libbuild2-hello-build/module/
```

---

## Bootstrap Modules

A bootstrap module must be loaded in `build/bootstrap.build`. Its `boot()`
function is called before any project configuration is loaded.

Design constraints for bootstrap modules:

- No access to `config.*` variables (not yet loaded).
- Non-global variable overrides (`config.import.*` set via `bdep init`) have
  no effect at bootstrap time. Use the global `b.options` override instead.
- Mark the module with `requires: bootstrap` in its `manifest` so CI and
  `--no-external-modules` handling work correctly.
- The `--no-external-modules` option omits all external module loads; a
  bootstrap module must tolerate this gracefully (the build system uses it
  when preparing distributions or running `info` queries).
- Strive to do only work that genuinely requires bootstrap timing -- leave
  everything else to `init()`.

---

## See Also

- [build2-module-dev-setup.md](build2-module-dev-setup.md) -- development environment setup
- [build2-intro-concepts.md](build2-intro-concepts.md) -- targets, scopes, modules, variables
- [build2-modules-core.md](build2-modules-core.md) -- config, test, install modules
- [build2-projects-advanced.md](build2-projects-advanced.md) -- importation and library metadata
- [HOWTO/toolchain-dev-setup.md](../HOWTO/toolchain-dev-setup.md) -- setting up build2 for toolchain development
