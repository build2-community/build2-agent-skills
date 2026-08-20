# build2 bin Module -- Binary Target Types

_Use for: understanding lib{}/liba{}/libs{}/exe{} target types, utility
libraries, object file types, C++20 module BMI types, and .def files._

## When to use

- You are confused about `lib{}` vs `liba{}` vs `libs{}` and when to use each.
- You need to understand `libue{}`, `libul{}` or other utility library types.
- You are working with C++20 named modules and need `bmi*{}` types.
- You need to declare a Windows `.def` file.

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

## See Also

- [`build2-modules-cc.md`](build2-modules-cc.md) -- cc module: C-common config, DLL export, compilation database
- [`build2-modules-c.md`](build2-modules-c.md) -- c module: C-specific compilation
- [`build2-modules-cxx.md`](build2-modules-cxx.md) -- cxx module: C++ compilation and C++20 modules
- [`build2-targets-variables.md`](build2-targets-variables.md) -- full built-in target type reference
- [`link-prerequisite-order.md`](../HOWTO/link-prerequisite-order.md) -- sources before `$libs` on linked `exe{}` and `libs{}`
- [`match-upstream-library-name.md`](../HOWTO/match-upstream-library-name.md) -- matching upstream SONAME, prefix, and shared-library file names
