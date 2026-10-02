# Test an Installed `import!` Locally

The in-tree case of `import! [metadata]` can pass while the installed case
fails: there is no export stub, metadata lives in the `.pc` file, and the
link rule's installed search has to find that file. cppget.org's
`test-installed` phase is the CI version of this check. The recipe below
is the local equivalent against a real prefix, without waiting on CI.

This is not the `sys:` scheme. `sys:` tells bpkg to treat a dependency as
already provided by the system package manager and does not set `-I`/`-L`.
See [sys-build-config.md](./sys-build-config.md) and
[importation of installed libraries](../guides/build2-modules-cc.md#importation-of-installed-libraries).

## Recipe

Install the dependency into a prefix, then consume it from a second
configuration that has no in-tree copy.

```
prefix=/tmp/libfoo-prefix

bpkg create -d cfgA cc config.install.root=$prefix
bpkg build -d cfgA libfoo
bpkg install -d cfgA libfoo

bpkg create -d cfgB cc \
  config.cc.loptions+=-L$prefix/lib \
  config.cc.poptions+=-I$prefix/include \
  config.bin.rpath=$prefix/lib
```

Point cfgB at a scratch consumer whose buildfile does the `import!` you
want to verify:

```
import! [metadata, rule_hint=cxx.link] foo = libfoo%lib{foo}

print $($foo: libfoo.rpath)

import libs = libfoo%lib{foo}
exe{driver}: cxx{driver} $libs
```

Then build that consumer inside cfgB (`bpkg build` of the scratch
package, or `b` in its out-of-tree output). If the metadata query prints
the prefix path and the binary links, the installed protocol works.

On MSVC, DLL lookup uses `PATH` instead of rpath, and the linker flag is
`/LIBPATH:` rather than `-L`. See
[packaging-guide-testing.md](../guides/packaging-guide-testing.md#step-9-test-the-package)
for the Windows form of the same prefix test.

## Why `-L` is required, and when `PKG_CONFIG_PATH` is not

Installed-library search (the link rule, which `import!` reaches only with
`rule_hint=c.link` / `cxx.link`) builds its directory list from the
compiler's system library dirs plus `-L` in `*.loptions`. In each
directory it looks for the binary, then for a `.pc` file in that
directory's `pkgconfig/` subdirectory (plus a few platform-specific
siblings such as `share/pkgconfig` on Linux).

A normal `b install` / `bpkg install` into `$prefix` puts the library in
`$prefix/lib` and the `.pc` in `$prefix/lib/pkgconfig`. `config.cc.loptions+=-L$prefix/lib`
is therefore enough for build2 to find both, on a GCC/Clang target.

On MSVC, `-L` does nothing here: `msvc_extract_library_search_dirs()`
(`libbuild2/cc/msvc.cxx`) only recognizes `/LIBPATH:<dir>` (or
`-LIBPATH:<dir>`) when building this search list, unlike `cl.exe` itself,
which separately accepts `-I` as an alias for `/I`. A `-L$prefix/lib`
override is silently ignored, not rejected: no error names the option,
the directory is simply never added to the search, and `import` then
fails with the generic `unable to import target` diagnostic (see
[troubleshooting.md](./troubleshooting.md#error-unable-to-import-target-target))
with no hint that the loption's own syntax was the problem. Use
`config.cc.loptions+=/LIBPATH:$prefix\lib` instead, matching the form
already used for the linker flag in
[packaging-guide-testing.md](../guides/packaging-guide-testing.md#step-9-test-the-package).

`PKG_CONFIG_PATH` is what the bundled libpkgconf error text suggests when
*it* cannot find a `.pc`. Set it when the `.pc` is not next to the
library (a split Debian-style layout, a Homebrew keg whose `.pc` is not
under the `-L` directory). It is not an extra requirement on top of `-L`
for a prefix that follows the layout above.

## `import` vs `import! [metadata]`

A plain deferred `import` can succeed on `-L`/`-I` alone if the shared or
static binary is in that search path. The `.pc` is then optional for
finding the file.

`import! [metadata]` still needs the `.pc`. For an installed library,
`export.metadata` is stored there. Without it the import fails even if
`-L` found the `.so`, typically with `unable to import target` or a
missing-metadata diagnostic.

That is why this recipe exists as a separate check from "the tests
subproject builds against the installed library" in
[packaging-guide-testing.md](../guides/packaging-guide-testing.md#step-9-test-the-package).
The in-package `tests/` recipe may never execute the metadata protocol
against a `.pc`.

## See Also

- [troubleshooting.md](./troubleshooting.md#error-static-variant-of-target-is-not-available):
  the pkg-config runtime allowlist, and why a strict static-only consumer
  can still fail here even after the `.pc` resolves correctly
- [target-metadata.md](./target-metadata.md): authoring `export.metadata`
  and `.for_install`
- [import-immediate-vs-ordinary.md](./import-immediate-vs-ordinary.md):
  do not link the immediate target
- [rpath-unlinked-dependency.md](./rpath-unlinked-dependency.md):
  `bin.rpath` from that same metadata path
- [ci-results.md](./ci-results.md): how `test-installed` appears on
  cppget.org
- [sys-build-config.md](./sys-build-config.md): `sys:` on CI does not
  set these search paths
