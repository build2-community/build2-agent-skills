# Cross-Compilation

To cross-compile, specify the cross-compiler via `config.cxx` (or `config.c`).
build2 auto-detects the target triplet from the compiler and sets all
`cxx.target.*` variables accordingly.

## Basic cross-compilation

```
$ b config.cxx=aarch64-linux-gnu-g++
```

build2 detects `cxx.target = aarch64-linux-gnu` automatically. No other
options are needed for a standard cross-toolchain.

## With bpkg

Create a dedicated cross configuration:

```
$ bpkg create -d build-arm cc config.cxx=aarch64-linux-gnu-g++
$ cd build-arm
$ bpkg build hello
```

## With bdep

```
$ bdep init -C ../build-arm @arm cc config.cxx=aarch64-linux-gnu-g++
$ bdep update @arm
$ bdep test @arm
```

## Sysroot and pkg-config rewriting

When cross-compiling against a sysroot that contains pkg-config `.pc` files
with absolute paths:

```
$ b config.cxx=aarch64-linux-gnu-g++ \
    config.cc.pkgconfig.sysroot=/opt/sysroot
```

All absolute `-I` and `-L` paths extracted from `.pc` files are prepended
with the sysroot path. See
[`build2-modules-cxx`](../guides/build2-modules-cxx.md#cross-compilation-and-target-configuration)
for the full variable reference.

## Conditional buildfile code for the target platform

Use `cxx.target.class` and `cxx.target.system` to write platform-conditional
buildfiles that work in both native and cross-compilation scenarios:

```
if ($cxx.target.class == 'windows')
  cxx.libs += advapi32.lib
elif ($cxx.target.class == 'linux')
  cxx.libs += -ldl

if ($cxx.target.system == 'mingw32')
  cxx.loptions += -Wl,--export-all-symbols
```

Never use `build.host.*` for target platform detection; always use
`cxx.target.*`.

## See Also

- [`build2-modules-cxx`](../guides/build2-modules-cxx.md#cross-compilation-and-target-configuration) -- target triplet variables and cross-compilation reference
- [`build2-modules-cxx`](../guides/build2-modules-cxx.md#system-library-dependencies-and-pkg-config-integration) -- pkg-config sysroot rewriting
