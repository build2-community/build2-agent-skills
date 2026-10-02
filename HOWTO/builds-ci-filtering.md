# Filtering automated CI builds with builds:, build-include:, and build-exclude:

The `builds:`, `build-include:`, and `build-exclude:` manifest fields control
which automated build bot configurations are used for a package. `builds:`
specifies the initial set via class expressions. `build-include:` and
`build-exclude:` then apply wildcard patterns to refine it.

For the full field reference see `bpkg/bpkg-manifest-reference.md`. For the
complete list of available configurations and class names on cppget.org, see
https://ci.cppget.org/?build-configs=all.

The bare `?build-configs` URL (no query value) defaults to the `default`
class only, silently hiding every `clang`, macOS, Windows, FreeBSD, Fedora,
RHEL, and Ubuntu bot. Always use `?build-configs=all`, and the result is
itself paginated (`&p=1`, `&p=2`, ...): page through every `&p=N` link before
concluding that a bot class or platform does not exist on the deployment.


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


## Exclude only the bindist variant of a distro

A single bot configuration can carry more than one class at once. On
cppget.org some bots carry both `sys` and `bindist` (for example
`linux_debian_12-gcc_12-bindist`), so a class expression aimed at "every
Debian bot except the one generating binary distribution packages" should
subtract the class, not the configuration name:

```
debian-builds: sys -static -bindist
```

This stays correct even if a future non-`bindist` Debian bot of the same
distro appears: it is included automatically because it is not excluded by
name, only by the `bindist` class it happens not to carry. Excluding by
matching the `-bindist` suffix in a `build-exclude:` name pattern instead
would miss that future bot, or (worse) any present/future bot whose name
happens to share the pattern for unrelated reasons.


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


## Tracing a wildcard pattern against a bot name by hand

There is no tool to test a `build-include`/`build-exclude` pattern against a
hypothetical bot name short of submitting a real `bdep ci` request. The
matching itself (see `dash_components_to_path()` and the constraint-matching
loop in `build2-brep`'s `mod/build-target-config.cxx`) can be traced by hand:

1. Every dash (`-`) in both the bot name and the pattern becomes a path
   separator. A single `*` matches within one such component only (it does
   not cross a dash). `**` matches across component boundaries (zero or more
   whole components).
2. `build-include:`/`build-exclude:` entries are checked in the order
   written, combined into one list. The **first** entry whose pattern matches
   the bot name (and target, if given) decides the outcome: an include entry
   means built, an exclude entry means excluded. If nothing in the list
   matches, the package is built.

Example: a package wants to build only on macOS with Clang, so it writes

```
macos-clang-build-include: macos_*-clang
macos-clang-build-exclude: **
```

Trace it against the real bot name `macos_14.5-clang_17-O3`:

| Step | Value |
|------|-------|
| Bot name as path | `macos_14.5/clang_17/O3/` |
| `macos_*-clang` as path | `macos_*/clang/` |
| Component 1 | `macos_14.5` matches `macos_*` |
| Component 2 | `clang_17` vs `clang` -- **no match**, `clang` has no trailing wildcard to absorb the `_17` compiler-version suffix |

The include pattern does not match this bot at all, so the loop falls
through to `build-exclude: **`, which matches everything -- the bot is
**excluded**. Since every real macOS Clang bot name carries a version suffix
after `clang`, this whitelist silently builds on zero macOS bots. The fix is
a trailing `**` (or an explicit version wildcard) on the include pattern:

```
macos-clang-build-include: macos_*-clang**
```

Re-tracing: `macos_*-clang**` becomes the path pattern
`macos_*/clang*/**/*/`. Component 2 is now `clang*`, a within-component
wildcard that does match `clang_17` (`clang` plus `*` absorbing `_17`), and
the trailing `**`/`*` absorb whatever component(s) follow (here `O3`, but
equally zero or several). This is the same class of gap `?build-configs=all`
pagination hides (see above): a filtering mistake looks identical to "no
matching bots exist" until traced or tested directly.


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

- `HOWTO/troubleshooting.md#error-static-variant-of-target-is-not-available` -- `error: static variant of <target> is not available`, when excluding a build class is the only option
- `bpkg/bpkg-manifest-reference.md` -- full field reference, grammar, and wildcard rules
- https://ci.cppget.org/?build-configs -- complete configuration and class list for cppget.org
- `HOWTO/sys-build-config.md` -- requesting system-provided libraries on specific CI bots with the `sys` class
- `HOWTO/ci-results.md` -- how `test-installed` appears on the cppget.org results page
