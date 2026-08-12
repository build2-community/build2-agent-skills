# bdep-new layouts: what common option combinations create

Use this page to pick a `bdep new` type and source layout. For flags and
sub-option details see [bdep-new](bdep-new.md).

Trees show the source layout only, matching `bdep-new(1)`. A generated
project also includes `build/`, `README.md` (unless `no-readme`), `tests/`
(unless `no-tests`), and VCS files (unless `--vcs none`). Those are omitted
so the layout choice stays visible.

Pass `-l c++,cpp` if you prefer `.hpp` / `.cpp` names instead of `.hxx` /
`.cxx`.

Headers are included with the source subdirectory (if any) as a prefix.
Different prefix and `subdir` combinations can share a physical tree but
still produce different include paths.


## Chooser

| When to pick it | Command | Source layout |
|---|---|---|
| Single executable | `-t exe hello` | `hello/hello/` |
| Single library | `-t lib libhello` | `libhello/libhello/` |
| Header-only library | `-t lib,binless libhello` | `libhello/libhello/` without a compiled source |
| Multi-package project | `-t empty` then `--package` | sibling package directories plus `packages.manifest` |
| One package, several source dirs | `-t bare` then `--source` | sibling source directories, one `manifest` |
| Combined library with a shorter include prefix | `-t lib,subdir=hello libhello` | `libhello/hello/` |
| Sources under `src/` | `-t exe,prefix=src hello` | `hello/src/hello/` |
| Split public headers and sources | `-t lib,split libhello` | `libhello/{include,src}/libhello/` |
| No source subdirectory under a prefix | `-t exe,prefix=src,no-subdir hello` | `hello/src/` |
| Everything in the project root | `-t lib,no-subdir,no-version,no-tests libhello` | `libhello/` |


## Project types and modes

### Executable (default type)

```
$ bdep new -l c++ -t exe hello
```

```
hello/
  hello/
    hello.cxx
    buildfile
  buildfile
  manifest
```

### Library

```
$ bdep new -l c++ -t lib libhello
```

```
libhello/
  libhello/
    hello.hxx
    hello.cxx
    buildfile
  buildfile
  manifest
```

### Header-only library (binless)

```
$ bdep new -l c++ -t lib,binless libhello
```

```
libhello/
  libhello/
    hello.hxx
    buildfile
  buildfile
  manifest
```

There is no compiled source and no `export.hxx`. See
[`header-only-library`](../HOWTO/header-only-library.md).

### Empty project plus packages

Use `-t empty` when the repository will hold more than one package. Then add
each package with `--package`. The empty project itself is not a package. It
starts with `README.md` and `repositories.manifest` only.

```
$ bdep new -t empty hello
$ cd hello
$ bdep new --package -l c++ -t lib libhello
$ bdep new --package -l c++ -t exe hello
```

```
hello/
  hello/
    hello/
      hello.cxx
      buildfile
    buildfile
    manifest
  libhello/
    libhello/
      hello.hxx
      hello.cxx
      buildfile
    buildfile
    manifest
  packages.manifest
```

The project root also gets a glue `buildfile` that builds the packages.

### Bare project plus source subdirectories

Use `-t bare` when you want one package and several source directories.
`--source` copies only the source subdirectory of a temporary project into
the current project.

```
$ bdep new -l c++ -t bare hello
$ cd hello
$ bdep new --source -l c++ -t lib libhello
$ bdep new --source -l c++ -t exe hello
```

```
hello/
  hello/
    hello.cxx
    buildfile
  libhello/
    hello.hxx
    hello.cxx
    buildfile
  buildfile
  manifest
```


## Common layout options

The `new` command splits the path to source code into a project/package
root, an optional source prefix, and a source subdirectory:

```
libhello/{include,src}/hello/
    ^         ^          ^
    |         |          |
 project/   source    source
 package    prefix  subdirectory
  root
```

`split` is a shortcut for `prefix-include=include,prefix-source=src`.

### Combined with an alternative subdirectory

```
# libhello/hello/

$ bdep new -l c++ -t lib,subdir=hello libhello
```

```
libhello/
  hello/
    hello.hxx
    hello.cxx
```

### Combined with a source prefix

```
# hello/src/hello/

$ bdep new -l c++ -t exe,prefix=src hello
```

```
hello/
  src/
    hello/
      hello.cxx
```

### Split headers and sources

```
# libhello/{include,src}/libhello/

$ bdep new -l c++ -t lib,split libhello
```

```
libhello/
  include/
    libhello/
      hello.hxx
  src/
    libhello/
      hello.cxx
```

### Header prefix only

```
# libhello/{include,.}/libhello/

$ bdep new -l c++ -t lib,prefix-include=include libhello
```

```
libhello/
  include/
    libhello/
      hello.hxx
  libhello/
    hello.cxx
```

### No source subdirectory

```
# hello/src/

$ bdep new -l c++ -t exe,prefix=src,no-subdir hello
```

```
hello/
  src/
    hello.cxx
```

### All source in the project root

This layout does not support a generated version header or the default test
setup, so those features are turned off.

```
# libhello/

$ bdep new -l c++ -t lib,no-subdir,no-version,no-tests libhello
```

```
libhello/
  hello.cxx
  hello.hxx
```

### Split, no subdirectory on the source side

```
# libhello/{include/hello,src}/

$ bdep new -l c++ -t lib,split,subdir=hello,no-subdir-source libhello
```

```
libhello/
  include/
    hello/
      hello.hxx
  src/
    hello.cxx
```

### Buildfiles in the prefix (third-party packaging)

A common packaging starting point is a split layout with `buildfile` in each
prefix directory rather than inside the source subdirectory. After that, add
the upstream project as a `git` submodule and replace the source
subdirectories with symlinks into it.

```
# hello/libhello/{include,src}/hello/
# hello/libhello/{include,src}/buildfile

$ bdep new -l c -t empty hello
$ bdep new -d hello --package \
    -l c \
    -t lib,split,subdir=hello,no-version,no-symexport,buildfile-in-prefix \
    libhello
```

```
hello/
  libhello/
    include/
      buildfile
      hello/
        hello.h
    src/
      buildfile
      hello/
        hello.c
```

Rarer layouts (Boost-style prefixes, include-inside-src, several
independently split components) are in the SOURCE LAYOUT section of
`bdep-new(1)`.


## See Also

- [bdep-new](bdep-new.md): flags, sub-options, hooks
- [`header-only-library`](../HOWTO/header-only-library.md): binless libraries
- [packaging-guide-summary](../guides/packaging-guide-summary.md): third-party `bdep new` workflow
- [package-naming](../HOWTO/package-naming.md): naming packages in an empty project
