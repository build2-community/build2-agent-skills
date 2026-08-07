# build2 Packaging -- Common Antipatterns and Upstream Patching

This guide describes common anti-patterns in `build2` packaging along with the
recommended alternative approaches, and provides detailed instructions for
patching upstream source code when unavoidable.

See [packaging-guide-summary.md](packaging-guide-summary.md) for the full
packaging workflow context and concepts.


## What Not to Do

### Don't write `buildfiles` from scratch, use `bdep-new`

Unless you have good reasons not to, create the initial project layout
automatically using `bdep-new`, then tweak it if necessary and fill it with
upstream source code.

The main rationale is that there are many nuances in getting the build right
and auto-generated `buildfiles` had years of refinement and fine-tuning. The
familiar structure also makes it easier for others to understand your build,
for example while reviewing your package submission or helping out with the
package maintenance.

The `bdep-new` command supports a wide variety of source layouts. While it may
take a bit of time to understand the customization points necessary to achieve
the desired layout for your first package, this will pay off when you work on
converting subsequent packages.

When editing scaffold files after generation, make only package-specific
adjustments: fill in placeholders, add symlinks, list sources, set include and
install paths, declare dependencies. Do not restructure sections, remove
generated comments, or add new sections unless they serve a clear and direct
purpose. The generated layout and phrasing are what reviewers expect to see,
and deviations increase review burden and maintenance cost. In particular, do
not change the generated `depends: * build2 >= X.Y.Z` and `depends: * bpkg
>= X.Y.Z` manifest values -- they match the toolchain that generated the
scaffold and should stay as generated (see
[packaging-guide-summary.md](packaging-guide-summary.md#step-3-write-the-package-manifest)).


### Avoid fixing upstream issues in the `build2` package

Any deviations from upstream make the `build2` package more difficult to
maintain. In particular, if you make a large number of changes to the upstream
source code, releasing a new version will require a lot of work. As a result,
it is recommended to avoid fixing upstream issues in the `build2` package.
Instead, try to have the issues fixed upstream and wait for them to be released
as a new version.

Sometimes, however, you may have no choice. For example, upstream is inactive
or has no plans to release a new version with your fixes any time soon. Or you
may want to add support for a platform or compiler that upstream is not willing
or capable of supporting.

Note that even if you do fix some issues in the `build2` package directly, try
hard to also incorporate them upstream so that you do not need to maintain the
patches forever.

See also [Avoid changing upstream source code layout](#avoid-changing-upstream-source-code-layout)
and [How do I patch upstream source code?](#how-do-i-patch-upstream-source-code).


### Avoid changing upstream source code layout

It is a good idea to stay as close to the upstream's source code layout as
possible. This keeps the overlay between `build2` build files and upstream
source code transparent and makes future version upgrades straightforward.


### Don't make library header-only if it can be compiled

Some libraries offer two alternative modes: header-only and compiled. Unless
there are good reasons not to, a `build2` build of such a library should use
the compiled mode.

> Some libraries use the "precompiled" term to describe the non-header-only
> mode. We do not recommend using this term in the `build2` package since it
> has a strong association with precompiled headers and can therefore be
> confusing. Use the "compiled" term instead.

The main rationale is that a library would not be offering a compiled mode if
there were no benefits (usually faster compile times of library consumers) and
there is no reason not to take advantage of it in the `build2` package.

There are, however, valid reasons why a compiled mode cannot be used, the most
common of which are:

- The compiled mode is not well maintained or tested by upstream and therefore
  offers inferior user experience.
- The compiled mode does not work on some platforms, usually Windows due to the
  lack of symbol export support (but see the build2 documentation on Automatic
  DLL Symbol Exporting).
- Use of the compiled version of the library requires changes to the library
  consumers, for example, inclusion of different headers.

If a compiled mode cannot always be used, then it may be tempting to support
both modes by making the mode user-configurable. Unless there are strong reasons
to, you should resist this temptation and, if the compiled mode is not
universally usable, then use the header-only mode everywhere.

The main rationale is that variability adds complexity which makes the result
more prone to bugs, more difficult to use, and harder to review and maintain.
If you really want to have the compiled mode, then the right way to achieve it
is to work with upstream to fix any issues that prevent its use in `build2`.

There are, however, valid reasons why supporting both modes may be needed, the
most common of which are:

- The library is widely used in both modes but switching from one mode to the
  other requires changes to the library consumers (for example, inclusion of
  different headers). In this case only supporting one mode would mean not
  supporting a large number of library consumers.
- The library consists of a large number of independent components while it is
  common for applications to only use a small subset of them, and compiling all
  of them in the compiled mode takes a substantial amount of time. Note that
  this can alternatively be addressed by making the presence of optional
  components user-configurable.


### Don't bundle dependencies

Sometimes third-party projects bundle their dependencies with their source
code (also called vendoring). For example, a C++ library may bundle a testing
framework. This is especially common with `catch2` where one often encounters a
comical situation with only a few kilobytes of library source code and over
600 KB of `catch2.hpp`.

The extra size, while wasteful, is not the main issue, however. The bigger
problem is that if a bug is fixed in the bundled dependency, then to propagate
the fix we will need to release a new version (or revision) of each package
that bundles it. This is not scalable.

While this does not apply to testing frameworks, an even bigger issue with
bundling of dependencies in general is that two libraries that bundle the same
dependency (potentially of different versions) may not be able to coexist in
the same build, with symptoms ranging from compile errors to subtle runtime
issues that are hard to diagnose.

As a result, it is strongly recommended that you unbundle any dependencies that
upstream may have bundled. In case of testing frameworks, see the HOWTO entry
"How do I handle tests that have extra dependencies?" for the recommended way
to deal with such cases.

> One special case where a bundled dependency may be warranted is a small
> utility that is completely inline/private to the implementation and where
> making it an external dependency may lead to a less performant result (due to
> the inability to inline without resorting to LTO). The `xxhash` implementation
> in `libzstd` is a representative example of this situation.


### Don't build your main targets in the root `buildfile`

It may be tempting to have your main targets (libraries, executables) in the
root `buildfile`, especially if it allows you to symlink entire directories
from `upstream/` (which is not possible if you have to have a `buildfile`
inside). However, this is not recommended except for the simplest of projects.

Firstly, this quickly gets messy since you have to combine managing `README`,
`LICENSE`, etc., and subdirectories with your main target builds. More
importantly, this also means that when your main target is imported (and thus
the `buildfile` that defines this target must be loaded), your entire project
will be loaded, including any `tests/` and `examples/` subprojects, and that
is wasteful.

If you want to continue symlinking entire directories from `upstream/` but
without moving everything to the root `buildfile`, the recommended approach is
to simply add another subdirectory level. Consider a package that uses a
combined layout (no header/source split) and where the library target is in
the root `buildfile`:

```
libigl-core/
├── igl/ -> ../upstream/igl/
├── tests/
└── buildfile                        # Defines lib{igl-core}.
```

Here is the alternative structure where we have added the extra `libigl-core`
subdirectory with its own `buildfile`:

```
libigl-core/
├── libigl-core/
│   ├── igl/ -> ../../upstream/igl/
│   └── buildfile                    # Defines lib{igl-core}.
├── tests/
└── buildfile
```

Below is the `bdep-new` invocation that can be used to automatically create
this alternative structure:

```
$ bdep new \
 --type lib,prefix=libigl-core,subdir=igl,buildfile-in-prefix \
 libigl-core
```

For the split layout, a slightly different set of `bdep-new` sub-options is
needed. Here is the layout which matched upstream exactly:

```
$ bdep new --type lib,split,subdir=foo,no-subdir-source libfoo
$ tree libfoo
libfoo/
├── include/
│   └── foo/
│       ├── buildfile
│       └── ...
└── src/
    ├── buildfile
    └── ...
```

With this layout we cannot symlink the entire `include/foo/` and `src/`
subdirectories because there are `buildfiles` inside. To fix this we can move
the `buildfiles` out of source subdirectory `foo/` and into prefixes
(`include/` and `src/`) using the `buildfile-in-prefix` sub-option. And since
`src/` does not have a source subdirectory, we have to invent one:

```
$ bdep new --type lib,split,subdir=foo,buildfile-in-prefix libfoo
$ tree libfoo
libfoo/
├── include/
│   ├── foo/ -> ../../upstream/include/foo/
│   └── buildfile
└── src/
    ├── foo/ -> ../../upstream/src/
    └── buildfile
```


### Don't make extensive changes in a revision

Unlike a new version, a revision replaces the previous revision of the same
version and as a result must be strictly backwards-compatible in all aspects
with what it replaces. If you make extensive changes in a revision, it becomes
difficult to guarantee that this requirement is satisfied. As a result, you
should refrain from making major changes, like substantially altering the
build, in a revision, instead delaying such changes until the next version.

The recommendation is to limit revision changes to bug fixes and preferably
only in the package infrastructure (`buildfiles`, `manifest`, etc.). Fixes to
upstream source code should be limited to critical bugs and be preferably
backported from upstream. To put it another way, changes in a revision should
have an even more limited scope than a patch release.


## How Do I Deal with Bad Header Inclusion Practice?

Libraries whose public headers have no library-name prefix (e.g.,
`#include <util.h>`) cannot coexist when installed or used together in the
same build. Such packages cannot be published to cppget.org without fixing the
inclusion scheme.

> `sys:` substitution is unavailable after the fix (the system-installed version
> still uses the unqualified scheme). Check Debian/Fedora first: if they already
> install headers into a subdirectory, adopt the same prefix. If the library is
> widely considered to "own" its unqualified names, get in touch before
> packaging.

**Layout.** Add a library-name directory level and symlink upstream headers
into it (`bdep new` sub-options `split`, `subdir=`, `buildfile-in-prefix`
generate this directly):

```
libfoo/
├── include/
│   └── libfoo/
│       └── util.h  ->  ../../../upstream/include/util.h
└── src/
    └── ...          ->  ../../upstream/src/...
```

**Header `buildfile`.** Install into the added subdirectory:

```
{hxx ixx txx}{*}:
{
  install         = include/libfoo/
  install.subdirs = true
}
```

**Source `buildfile`.** The `_unq` paths let upstream sources keep writing
`#include <util.h>` internally. They must appear only in `cxx.poptions`, never
in `cxx.export.poptions`, so consumers are forced to use the prefixed form:

```
out_pfx_inc     = [dir_path] $out_root/include/
src_pfx_inc     = [dir_path] $src_root/include/
out_pfx_src     = [dir_path] $out_root/src/
src_pfx_src     = [dir_path] $src_root/src/
out_pfx_inc_unq = [dir_path] $out_root/include/libfoo/
src_pfx_inc_unq = [dir_path] $src_root/include/libfoo/

cxx.poptions =+ "-I$out_pfx_src" "-I$src_pfx_src" \
                "-I$out_pfx_inc" "-I$src_pfx_inc" \
                "-I$out_pfx_inc_unq" "-I$src_pfx_inc_unq"

lib{foo}:
{
  cxx.export.poptions = "-I$out_pfx_inc" "-I$src_pfx_inc"  # qualified only
  cxx.export.libs     = $intf_libs
}
```

**Dual inclusion (optional).** To also support consumers that still write
`#include <util.h>`, export the unqualified paths and add them to the generated
`pkg-config` files. This re-introduces the co-existence problem within a build,
so only do this for compelling backwards-compatibility reasons:

```
lib{foo}:
{
  cxx.export.poptions = "-I$out_pfx_inc" "-I$src_pfx_inc" \
                        "-I$out_pfx_inc_unq" "-I$src_pfx_inc_unq"
  cxx.export.libs     = $intf_libs
}

lib{foo}: cxx.pkgconfig.include = include/ include/libfoo/
```


## How Do I Patch Upstream Source Code?

If you need to change something in the upstream source code, there are several
options. You can make a copy of the upstream source file and make the
modifications there. While straightforward, this approach has one major
drawback: you will have to keep re-applying the changes for every subsequent
version unless and until upstream incorporates your changes. The other two
options try to work around this drawback.

The first alternative option is to modify the upstream source code
automatically during the build, typically using an ad hoc recipe. This
approach works best when the changes are regular and can be applied
mechanically with something like the `sed` builtin.

The second alternative option is to use the C/C++ preprocessor to make the
necessary changes to the upstream source code during compilation. Unlike the
first alternative, this approach does not have a prescribed way to apply it in
every situation and often requires some imagination. Note that it also has the
tendency to quickly get out of hand, at which point it is wise to keep it
simple and use the first option (manual modification).

The following sections examine each approach in detail.


### Modifying upstream source code manually

As an illustration of this approach, let's say we need to patch `src/foo.cpp`
in our `libfoo` example. The recommended sequence of steps is as follows:

1. Rename the upstream symlink to `.orig`:

   ```
   $ cd libfoo/src/
   $ mv foo.cpp foo.cpp.orig
   ```

2. Make a deep copy of `.orig`:

   ```
   $ cp -H foo.cpp.orig foo.cpp
   ```

3. Make any necessary modifications in the deep copy:

   ```
   $ edit foo.cpp
   ```

4. Create a patch for the modifications:

   ```
   $ diff -u foo.cpp.orig foo.cpp >foo.cpp.patch
   ```

The presence of the `.orig` and `.patch` files makes it clear that the
upstream code was modified. They are also useful when re-applying the changes
to the new version of the upstream source code. The recommended sequence of
steps for this task is as follows:

1. After the `upstream` submodule update, the `.orig` symlink points to the
   new version of the upstream source file.

2. Overwrite the old modified version with a deep copy of the new `.orig`:

   ```
   $ cp -H foo.cpp.orig foo.cpp
   ```

3. Apply old modifications to the new deep copy:

   ```
   $ patch <foo.cpp.patch
   ```

   If some hunks of the patch could not be applied, manually resolve any
   conflicts.

4. If in the previous step the patch did not apply cleanly, regenerate it:

   ```
   $ diff -u foo.cpp.orig foo.cpp >foo.cpp.patch
   ```


### Modifying upstream source code during build

As an illustration of this approach, let's say upstream is using the `${VAR}`
style variable substitutions in their `config.h.cmake` instead of the more
traditional `@VAR@` style:

```
/* config.h.cmake */

#define FOO_VERSION "${PROJECT_VERSION}"
```

The `${VAR}` style is not supported by the `build2` `autoconf` module which
means we cannot use the upstream `config.h.cmake` as is. While we could patch
this file manually to use `@VAR@` instead, this is a pretty mechanical change
that can be easily made with a simple ad hoc recipe during the build, freeing
us from manually applying the same changes in subsequent versions. For example:

```
using autoconf

h{config}: in{config.h.in}
{
  autoconf.flavor = cmake
  PROJECT_VERSION = $version
}

in{config.h.in}: file{config.h.cmake}
{{
  sed -e 's/\$\{(.+)\}/@\1@/g' $path($<) >$path($>)
}}
```


### Modifying upstream source code with C/C++ preprocessor

A good illustration of this approach is adding the `build2` metadata to an
executable. Let's say we have a symlink to upstream's `main.c` that implements
the executable's `main()` function and we need to add a snippet of code at the
beginning of this function that handles the `--build2-metadata` option. While
manually modifying `main.c` is not a wrong approach, we can try to be clever
and do it automatically with the preprocessor.

Specifically, we can create another file next to the `main.c` symlink, calling
it, for example, `main-build2.c`, with the following contents:

```c
/* Handle --build2-metadata in main() (see also buildfile). */

#define main xmain
#include "main.c"
#undef main

#include <stdio.h>
#include <string.h>

int main (int argc, const char** argv)
{
  if (argc == 2 && strncmp (argv[1], "--build2-metadata=", 18) == 0)
  {
    printf ("# build2 buildfile foo\n");
    printf ("export.metadata = 1 foo\n");
    printf ("foo.name = [string] foo\n");
    ...
    return 0;
  }

  return xmain (argc, argv);
}
```

The idea is to rename the original `main()` with the help of the C preprocessor
and provide our own `main()` which, after handling `--build2-metadata`, calls
the original. One notable deal-breaker for this approach would be a C++
implementation of `main()` that does not have an explicit `return`. There is
also a better chance in C++ for the `main` macro to replace something
unintended.

To complete this we also need to modify our `buildfile` to exclude `main.c`
from compilation (since it is compiled as part of `main-build2.c` via the
preprocessor inclusion). For example:

```
exe{foo}: {h c}{** -main}
exe{foo}: c{main}: include = adhoc  # Included in main-build2.c.
```


## See Also

- [packaging-guide-summary.md](packaging-guide-summary.md)
- [packaging-guide-testing.md](packaging-guide-testing.md)
- [packaging-guide-review.md](packaging-guide-review.md)
- [packaging-guide-version-management.md](packaging-guide-version-management.md)
