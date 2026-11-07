# Linking System Libraries

System libraries (`-lm`, `-ldl`, `advapi32.lib`, `ws2_32.lib`, etc.) are not
importable targets. List them in the appropriate
[`*.libs` variable](../guides/build2-modules-cxx.md#system-library-dependencies-and-pkg-config-integration)
instead:

```
if ($c.target.class != 'windows')
  c.libs += -lm
```

```
if ($cxx.target.class == 'windows')
{
  if ($cxx.target.system == 'mingw32')
    cxx.libs += -ladvapi32
  else
    cxx.libs += advapi32.lib
}
```

If the system library is an interface dependency of your library (i.e.,
consumers also need to link it), list it in
[`*.export.libs`](../guides/build2-modules-cxx.md#export-options-propagated-to-consumers-of-a-library)
as well. See [library projects](../guides/build2-projects-advanced.md#library-projects)
for background on interface vs implementation dependencies:

```
if ($c.target.class != 'windows')
{
  c.libs += -lm
  lib{hello}: c.export.libs = -lm
}
```

For a [binless (header-only) library](./header-only-library.md) you still need
`*.libs` in addition to `*.export.libs` because `*.libs` is used when linking
the static variant of the binless library.

## Windows import library missing from the pkg-config allowlist

An installed library's `.pc` file is read back by every consumer,
including the package's own `test-installed` step. Under a strict
`config.bin.exe.lib=static` consumer, each bare name in it must either be
on the hardcoded Windows runtime list in `libbuild2/cc/pkgconfig.cxx` or
resolve to a static archive (see
[troubleshooting](./troubleshooting.md#error-static-variant-of-target-is-not-available)).
A system import library such as `tdh.lib` is on neither, and every
buildfile placement of the name ends up in the `.pc`:

- `*.export.libs` (or an `import` of a stub `lib{tdh}`) is written to
  `Libs`.
- `*.libs` alone does not avoid it. A consumer of the static archive must
  link the archive's implementation dependencies too, so
  `pkgconfig_save()` (`libbuild2/cc/pkgconfig.cxx`) writes `*.libs` to
  the static `.pc`'s `Libs.private`. It only works in tree.

When the system library is only needed to link the package's own
objects, keep the name out of the build system and let the objects carry
it:

1. Do not list the name in `cxx.libs` or `cxx.export.libs`, and do not
   `import` it.
2. Add a package-owned header that names the library with the MSVC
   linker comment:
   ```
   #pragma once

   #pragma comment(lib, "tdh.lib")
   ```
   The directive is recorded in every object file compiled with the
   header. The linker picks it up when it links the DLL, and when a
   consumer links the static archive, with no `.pc` entry.
3. Force-include the header on `win32-msvc`. The option spelling depends
   on the compiler class, not the target. clang++ targeting
   `*-windows-msvc` has `cxx.id` `clang` and `cxx.class` `gcc` but
   `cxx.target.system` `win32-msvc`, while `cl` and `clang-cl` have class
   `msvc` (`libbuild2/cc/guess.cxx`):
   ```
   if ($cxx.target.system == 'win32-msvc')
   {
     if ($cxx.class == 'gcc')
       cxx.poptions += -include $src_base/tdh-libs.h
     else
       cxx.poptions += /FI $src_base/tdh-libs.h
   }
   ```
   Do not pass `/FI<path>` to clang++. It is not an option there, and
   clang++ tries to read a file named `/FI...`. Keep the assignment in
   file-scope `cxx.poptions`, not `cxx.export.poptions`. Consumers do not
   need it because the directive is already in the objects.
4. Make the header a prerequisite so it is distributed, with a condition
   instead of an `if` around the declaration (see
   [config-independent-build-graph](./config-independent-build-graph.md)):
   ```
   lib{hello}: hxx{tdh-libs}: include = ($cxx.target.system == 'win32-msvc')
   ```
   A `dist` from a non-Windows host still ships it, because
   `dist_include()` turns an excluded prerequisite into an ad hoc one.
   `$windows` is not a build2 builtin, so spell the condition out or
   define the variable yourself.
5. Give the file the project's `hxx{*}: extension`. With
   `hxx{*}: extension = h` the file must be `tdh-libs.h`, not
   `tdh-libs.hxx`.

For a C library, use `c.poptions`, `$c.class`, and `h{}` instead.

This does not help when the name must appear in the `.pc` because
consumers call the system library themselves (an interface dependency).
The durable fix there is adding the name to the list in `pkgconfig.cxx`
upstream ([build2/build2#557](https://github.com/build2/build2/issues/557)
is precedent).

## See Also

- [`troubleshooting`](./troubleshooting.md#error-static-variant-of-target-is-not-available) -- `error: static variant of <target> is not available` when the same system library is instead reached through an installed `.pc` file
- [`link-prerequisite-order`](./link-prerequisite-order.md) -- sources before `$libs` on `exe{}` and `libs{}`
- [`link-pthread`](./link-pthread.md) -- special case: linking pthread portably
- [`windows-resource-file`](./windows-resource-file.md): embedding a Windows `.rc` resource in a DLL
- [`header-only-library`](./header-only-library.md) -- binless library dependency considerations for *.libs
- [`build2-modules-cxx`](../guides/build2-modules-cxx.md) -- cxx.libs, cxx.export.libs, and pkg-config integration
- [`build2-projects-advanced`](../guides/build2-projects-advanced.md) -- library interface vs implementation dependencies
