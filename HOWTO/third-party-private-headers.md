# Private Implementation Headers in Third-Party Packages

When packaging upstream C/C++ projects for build2, two structural problems
appear frequently:

1. **Cross-target private headers.** Upstream sources in multiple internal
   libraries or executables reach into each other's private `src/`
   subdirectories, relying on a hardcoded source-tree layout
   (e.g., `include_directories(../other-lib/src/)`).

2. **Shared generated config header.** A build-time-generated `config.h` (or
   similar) is an internal implementation detail that must be visible to
   sources across multiple targets in the same project.

build2 does not endorse these patterns, but both are solvable without
restructuring upstream sources.


## Private headers within a single package

The standard `bdep new`-generated scaffold already contains the canonical
template for this pattern (documented in the Packaging Guide,
"Adjust source `buildfile`: build and export options"). The rule is: add
private include paths to `cxx.poptions`/`c.poptions`, never to
`cxx.export.poptions`.

```
# Public headers are declared in include/buildfile and sourced from there.
pub = [dir_path] ../include/
include $pub
pub_hdrs = $($pub/ pub_hdrs)

lib{foo}: $pub/{$pub_hdrs}

# Private headers and sources.
lib{foo}: foo/{hxx ixx txx cxx mxx}{**} $impl_libs $intf_libs

# Build options.
#
# The out_ variants ensure generated headers landing in the output directory
# are found. Remove them if there are no auto-generated headers.
out_pfx_src = [dir_path] $out_root/src/foo
src_pfx_src = [dir_path] $src_root/src/foo
out_pfx_inc = [dir_path] $out_root/include/
src_pfx_inc = [dir_path] $src_root/include/

cxx.poptions =+ "-I$out_pfx_src" "-I$src_pfx_src" \
                "-I$out_pfx_inc" "-I$src_pfx_inc"

# Export only public include paths to consumers.
lib{foo}: cxx.export.poptions = "-I$out_pfx_inc" "-I$src_pfx_inc"

# Do not install private headers.
foo/{hxx ixx txx}{*}: install = false
```

If you only have private auto-generated headers (none in the public tree),
remove `out_pfx_inc` from `cxx.export.poptions` only, keeping it in
`cxx.poptions`. If there are no auto-generated headers at all, remove the
`out_` variants entirely.

For projects that use a combined layout without a separate `include/` tree,
use `$src_base` and `$out_base` directly and export the same paths:

```
cxx.poptions =+ "-I$out_base" "-I$src_base"

lib{foo}: cxx.export.poptions = "-I$out_base" "-I$src_base"
```

For monolithic projects with no install-facing public headers, where sources
across many internal subdirectories include each other freely, enumerate all
internal paths:

```
c.poptions =+ "-I$out_root" "-I$src_root" "-I$src_base" \
              "-I$src_base/port" "-I$src_base/include"
```

The postgresql package (`libpq`, by Karen Arutyunyan) is a real-world example
of this approach.


## Thunk headers and symlinks (cross-package, in-place workaround)

When an executable package accesses a sibling library package's headers using
relative `""` includes such as:

```cpp
#include "../../libfoo/include/foo/util.hpp"  // public header
#include "../../libfoo/src/impl.hpp"          // private header
```

the paths break as soon as packages are separated or the library is installed.
The Packaging Guide ("Adjust source `buildfile`: sources, private headers")
documents two techniques for working around this without patching upstream
source code.

For **public headers**, create a "thunk header" at the path where upstream
expects it, containing only a canonical `<>` re-export:

```cpp
// exe-package/exe/../../libfoo/include/foo/util.hpp
#include <foo/util.hpp>
```

For **private headers**, create a symlink (tracked in git) from the executable
package's source tree to the corresponding file in the library package. This
only works when the symbols accessed through the private header are all
exported by the library; if unexported symbols are required, the executable
must link the static variant (which includes all object files and therefore
all internal symbols, unlike the shared variant).

Add such symlinks as `adhoc` prerequisites so build2 tracks them without
treating them as compilation inputs:

```
exe{foo}: exe/{hxx cxx}{**} lib{foo} testscript
exe{foo}: exe/impl.hxx: include = adhoc  # symlink to libfoo/src/impl.hpp
```

The zstd package (by Boris Kolpackov, and cited in the Packaging Guide) is
the canonical real-world example of both techniques. In that repository's
`zstd/zstd/` source directory:

- `lib/zstd.h` is a thunk: `#include <zstd.h>`
- `lib/common/pool.c` is a symlink to `../../../../upstream/lib/common/pool.c`
- `programs` is a directory symlink to `../../upstream/programs`

The postgresql package (`psql`, by Karen Arutyunyan) demonstrates using
symlinks for private cross-package config headers. The executable package
places a `downstream/` directory in its source tree and symlinks the library's
private headers into it:

```
downstream/pg_config.h   -> ../../../libpq/libpq/pg_config.h
downstream/pg_config_os.h -> ../../../libpq/libpq/pg_config_os.h
```

The executable's buildfile then adds `-I$src_base/downstream` to its compile
options. This works when both packages live in the same repository and are
always built together; it does not support the case where the library package
is installed independently.


## Generated config header (internal only)

The simplest case: a `config.h` generated at configure time from a `.in`
template via the
[`in` module](../guides/build2-modules-misc.md#in-module):

```
h{config}: in{config}
{
  PACKAGE_NAME  = "\"myproject\""
  HAVE_STRING_H = true
}

lib{foo}: h{config} {hxx cxx}{**}

c.poptions =+ -DHAVE_CONFIG_H "-I$out_base" "-I$src_base"

h{config}: install = false
```

`-I$out_base` is necessary because `h{config}` is generated into the output
directory. Mark the header not installed -- it is an internal build artifact.

The postgresql package (`libpq`, by Karen Arutyunyan) follows this pattern for
its internal version header: `h{version}: in{version} $src_root/manifest`,
with the comment "The version file is an internal one (it is only included from
`pg_config.h`) so we don't distribute nor install it".

Do not compute a compiler-conditional capability macro (`HAVE_FOO`-style,
gated on which compiler or target is in play) as a hand-rolled expression
in this block. `$c.class`/`$cc.class` is exactly two-valued (`gcc`,
`msvc`) and tracks command-line syntax, not compiler identity or which
preprocessor macros a compiler defines for its target -- see [Compiler
Class vs. Compiler ID vs. Target
Class](../guides/build2-modules-cc.md#compiler-class-vs-compiler-id-vs-target-class)
for the full distinction. For example, `$c.class != 'msvc'` does not
exclude every Clang that defines `_MSC_VER`: vanilla Clang invoked through
its native, gcc-compatible driver stays class `gcc` even when its target
triple is `*-windows-msvc`.

Probe the actual macro instead: either extract it with `c.predefs` (see
[Capability detection as `-D`
flags](#capability-detection-as--d-flags) below), or write a dedicated
`autoconf` project check gated on the macro directly, e.g. a
`build/autoconf/checks/HAVE_STDNORETURN_H.h` guarding on `_MSC_VER` rather
than on `$c.class` (see
[Project-specific checks](../guides/build2-autoconf-project-checks.md)).

## Generated config header (installed as part of the public API)

Some config headers contain architecture-specific information (pointer sizes,
endianness, feature availability) that consumers of the library also need to
read. Such headers should be installed using the `include_arch` location
(documented in the build2 manual, "Install Module") rather than `include`,
because `include_arch` can be redirected by the user to an
architecture-qualified path (e.g., `/usr/include/x86_64-linux-gnu/`) on
multi-architecture systems:

```
h{*}:      install = include/libhello/
h{config}: install = include_arch/libhello/
```

The generated `pkg-config` file records `install.include` as the header search
path by default. If `install.include_arch` differs (as it does on multi-arch
systems), add it explicitly with `cxx.pkgconfig.include`:

```
lib{foo}: cxx.pkgconfig.include = include/libfoo/ include_arch/libfoo/
```


## Capability detection as `-D` flags

When a generated config header only defines capability macros (`HAVE_FOO`,
`HAVE_BAR`, etc.), consider passing them as `-D` flags instead of generating
a header at all. This is the cleanest approach: it avoids all installed-header
mis-inclusion problems and requires no include path adjustments.

For statically known platform differences, pass the flags directly:

```
c.poptions =+ \
  -DHAVE_USLEEP=1 \
  -DHAVE_STRING_H=1
```

The sqlite package (`libsqlite3`, by Karen Arutyunyan) uses this approach for
all of its capability and feature-enable macros.

For capabilities that must be probed at build time (compiler intrinsics, system
header availability, etc.), use the `autoconf` module's `c.predefs` rule to
detect macro values and source them into the buildfile.

This requires `c.predefs` to already be loaded in `root.build`, after the
C/C++ compiler module. See
[build2-autoconf-buildfile.md](../guides/build2-autoconf-buildfile.md)
(Step 2: Load the `c.predefs` submodule) for the exact `using` lines needed.

```
using autoconf

h{mylib-autoconf}: in{mylib-autoconf}
{
  install = false
  autoconf.aliases = HAVE_ALTERNATIVE_NAME@HAVE__INTERNAL_NAME
}

[rule_hint=c.predefs] buildfile{mylib-autoconf}: h{mylib-autoconf}
{
  c.predefs.poptions = false
  c.predefs.macros = HAVE_ATTRIBUTE_PACKED HAVE_SOME_HEADER
}

# Safe defaults for non-perform operations (configure, info, etc.).
HAVE_ATTRIBUTE_PACKED = [bool] false
HAVE_SOME_HEADER      = [bool] false

if ($build.meta_operation == 'perform')
{
  update buildfile{mylib-autoconf}
  source $path(buildfile{mylib-autoconf})

  HAVE_ATTRIBUTE_PACKED = ($HAVE_ATTRIBUTE_PACKED == 1 ? true : false)
  HAVE_SOME_HEADER      = ($HAVE_SOME_HEADER      == 1 ? true : false)
}

cxx.poptions += \
  ($HAVE_ATTRIBUTE_PACKED ? -DHAVE_ATTRIBUTE_PACKED :) \
  ($HAVE_SOME_HEADER      ? -DHAVE_SOME_HEADER      :)
```

The `if ($build.meta_operation == 'perform')` guard is required because the
generated buildfile fragment exists only during an actual build. The
`autoconf.aliases` attribute remaps macro names that differ between the `.in`
template and the autoconf check result.

The `autoconf` module ships as part of the standard pre-installed build2
toolchain, so `using autoconf` alone is correct and complete here. No
`depends:` entry is needed for it in the package manifest.

The icu package (`libicuuc`, by Karen Arutyunyan) uses this technique to detect
target endianness: the `h{endian}: in{endian}` / `c.predefs` pair extracts the
endianness character into the buildfile, which then drives a metadata export
and controls which binary data archive is linked.


## Cross-package generated file paths (metadata approach)

When a build-time-generated file -- such as a generated data archive or, in
advanced cases, a generated config header -- produced by one package must be
consumed by another, and the consuming package must work both during an
in-tree development build and against an installed copy of the producing
package, use the target metadata protocol to export the file's path.

The general pattern: the producing package exports a `[path, null]` metadata
variable on a target. The value is `null` during development (signalling the
consumer to import the target directly) and resolves to an installed path
after installation (signalling the consumer to create a local `file{}`
target from it).

The icu package (by Karen Arutyunyan) is the authoritative real-world example
of this pattern. The `icu-tools` package exports the path to a generated binary
data archive via executable metadata:

```
# In icu-tools: exe{genccode} exports the data archive path.
exe{genccode}:
{
  export.metadata = 1 genccode
  genccode.datfile_l_path = [path, null]
  genccode.datfile_b_path = [path, null]
  genccode.datfile_l_path.for_install = \
    [path] ($install.root != [null] ? ... : .)
}
```

The consuming `libicuuc` package imports the metadata and branches:

```
import! [metadata] genccode = icu-tools%exe{genccode}
datfile_path = $($genccode: genccode.datfile_$(icu_data_char)_path)

if $null($datfile_path)
  import! datfile = icu-tools%file{icudt$(icu_data_char).dat}
else
  datfile = file{$datfile_path}
```

The same technique applies to a generated config header shared across packages
in a multi-package repository. The producing package exports a `[path, null]`
metadata variable pointing to the generated header; the consumer branches on
null (in-tree import) vs. non-null (installed file path). See
[target-metadata](./target-metadata.md) for the full protocol, including how
`.for_install` interacts with `install.resolve`.

## See Also

- [`generated-headers`](./generated-headers.md) -- pre-generation ordering and the dummy header technique
- [`target-metadata`](./target-metadata.md) -- exporting metadata from executables and libraries across packages
- [`packaging-guide-summary`](../guides/packaging-guide-summary.md) -- full third-party packaging workflow and buildfile scaffold
- [`build2-modules-misc`](../guides/build2-modules-misc.md) -- in module for .in template preprocessing
- [`build2-modules-autoconf`](../guides/build2-modules-autoconf.md) -- autoconf module for capability detection via c.predefs
- [`build2-modules-cc.md`](../guides/build2-modules-cc.md#compiler-class-vs-compiler-id-vs-target-class) -- cc.class (gcc/msvc only, command-line syntax) vs cc.id vs cc.target.class
