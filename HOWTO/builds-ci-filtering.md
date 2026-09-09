# Filtering automated CI builds with builds:, build-include:, and build-exclude:

The `builds:`, `build-include:`, and `build-exclude:` manifest fields control
which automated build bot configurations are used for a package. `builds:`
specifies the initial set via class expressions. `build-include:` and
`build-exclude:` then apply wildcard patterns to refine it.

For the full field reference see `bpkg/bpkg-manifest-reference.md`. For the
complete list of available configurations and class names on cppget.org, see
https://ci.cppget.org/?build-configs.


## Disable all automated CI builds

```
builds: none
```

Use when the package is not ready for automated testing or is intentionally
excluded from CI.


## Build only on one platform (whitelist)

```
build-include: linux**
build-exclude: ** ; Only supported on Linux.
```

Do not add `builds: default` -- it is redundant when `build-exclude: **`
is present. The catch-all `build-exclude: **` excludes every configuration
that did not match the preceding `build-include:` pattern. The comment on
the exclusion line is displayed by brep in the web interface.

Replace `linux**` with `windows**` or `macos**` for other platforms.


## Exclude one platform (blacklist)

```
builds: -windows
```

This subtracts the `windows` class from the `default` underlying set. Use
`builds: all : -windows` to subtract from all configurations instead.

Note: blacklist recipes are not future-safe. If a new default configuration
appears on the excluded platform after the package was published, the package
will not be built there. Prefer the whitelist approach when only one or a
small number of platforms are supported.


## Only default configurations for a specific platform

```
builds: -windows
```

This uses the implicit `default` underlying set. To be explicit:

```
builds: default : -windows
```

To include all (not just default) configurations except Windows:

```
builds: all : -windows
```


## Exclude a specific compiler version

Use `build-exclude:` with a wildcard matching the configuration name and an
optional target triplet component:

```
build-exclude: *-msvc_14**/i?86-** ; Linker crash.
```

The `**` in the config component matches across name component boundaries
(for example it matches `windows_10-msvc_14.0-O2`). The `/i?86-**` target
component restricts the exclusion to 32-bit x86 targets.


## Restrict to one compiler family

```
builds: all : &gcc
```

Intersects all configurations with the `gcc` class. Combine with platform
restrictions:

```
builds: all : &gcc &( +linux +macos )
```


## Multiple builds: lines for individual comments

```
builds: default experimental ; Only modern compilers are supported.
builds: -gcc                 ; GCC is not supported.
builds: -clang               ; Clang is not supported.
```

Multiple `builds:` values are evaluated as one expression in order. Only the
first value may specify the underlying class set.


## Per named configuration override

To pass extra configuration variables to a specific named build configuration:

```
network-build-config: config.libfoo.network=true ; Enable networking API.
network-builds: linux ; Only supported on Linux.
```

The `*-builds`, `*-build-include`, and `*-build-exclude` per-configuration
variants follow the same syntax as the common fields.


## Exclude static when tests import libs

A tests or companion package that imports a specific `lib{}` group member
(usually `libs{}`, via the metadata protocol) hard-fails on configurations
that build only the static member (`config.bin.lib=static`). The shared
file does not exist, and the diagnostic is a generic `unable to import
target` with no hint that a build-class exclusion is missing.

```
builds: -static  ; Tests import libs{}, absent when only static is built.
```

Put this on the tests/companion package's own manifest, not only on the
primary. `static` is a deployment-defined class on cppget.org (see
https://ci.cppget.org/?build-configs), not one of the five pre-defined
names.

ODB's own manifests use `builds: -static` because plugin implementations
need `-fPIC` / a shared member. Same class, analogous "this member does
not exist under static" reason, not the identical metadata-import failure.


## See also

- `bpkg/bpkg-manifest-reference.md` -- full field reference, grammar, and wildcard rules
- https://ci.cppget.org/?build-configs -- complete configuration and class list for cppget.org
- `HOWTO/sys-build-config.md` -- requesting system-provided libraries on specific CI bots with the `sys` class
- `HOWTO/ci-results.md` -- how `test-installed` appears on the cppget.org results page
