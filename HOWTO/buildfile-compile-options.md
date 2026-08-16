# Compile and Link Options in Buildfiles

Not all options from an upstream build system belong in a build2
[buildfile](../guides/build2-intro-concepts.md#buildfiles-and-project-structure).
An option is appropriate only if it has purely local effect. The general rule:
do not specify options that could prevent the user from controlling overall
build characteristics, require changes in dependent projects, or interfere with
the build system itself.

## Options that are OK

1. Disable specific warnings (`-Wno-XXX`, `/wdXXX`,
   `-D_CRT_SECURE_NO_WARNINGS`). Do not *enable* warning classes like `-Wall`
   or `/W3` since their meaning changes across compiler versions, and do not
   use `-Werror`/`/WX`.

2. Language-feature toggles that only affect individual translation units:
   strict aliasing (`-fno-strict-aliasing`), exceptions
   (`-fno-exceptions`), RTTI (`-fno-rtti`).

3. Standard library feature macros scoped to this library's TUs only
   (`-D_GNU_SOURCE`, `-D_WIN32_WINNT`). Do not use macros that would impose
   expectations on consumers (e.g., `-D_FILE_OFFSET_BITS` when `off_t`
   appears in the public interface).

4. Symbol visibility (`-fvisibility*`).

## Options that do NOT belong

- Warning classes or `-Werror` [breaks user control of diagnostics]
- `-DNDEBUG` [user's choice]
- Sanitizers, stack protection (`-fsanitize*`, `-fstack-protector-all`) [user's choice]
- SIMD flags (`-msse`, `-mavx`) [user's choice]
- `-fPIC` [interferes with build system]
- `/MP`, `-flto-jobs` [parallelism is build system territory]
- Hardcoded search paths (`-I/usr/local/include`, `-L/opt/homebrew/lib`)
- Reproducible-build flags (`-ffile-prefix-map`) [user's choice]

## Export options

The rules for
[`*.export.poptions` and `*.export.loptions`](../guides/build2-modules-cxx.md#export-options-propagated-to-consumers-of-a-library)
are stricter still: do not impose any settings on consumers beyond what
concerns your library's own interface. In particular, do not disable warnings
or set standard library feature macros in export options. Note there are no
`*.export.coptions` for this reason.

## Always append, never assign

Use `+=` or `=+` for
[build-time option variables](../guides/build2-modules-cxx.md#build-time-options-affect-this-targets-compilationlinking).
The user may have pre-populated them via `config.*` counterparts.

## Compile recipe order

The compile command line is assembled as path, `poptions`, `coptions`,
then `*.mode`:

```
$cxx.path $poptions $coptions $cxx.mode -o $o -c $s
```

`poptions` is `$cxx.poptions $cc.poptions`. `coptions` is
`$cc.coptions $cxx.coptions`. Mode options appear last.

`cxx.std` / `c.std` are translated into mode (`-std=`, `/std:c++20`,
`/Zc:__cplusplus`). They are not `coptions`. No `coptions` assignment,
directory, or target can come after that.

`+=` / `=+` and scope (`exe{}` / `lib{}` / `obje{*}`) only reorder
inside one list. They do not move a flag from `coptions` into mode.

This matters when a later option overrides an earlier one. Putting
`/Zc:strictStrings-` in `cxx.coptions` places it before `/std:c++20`.
`/std:c++20` and later enable `/permissive-`, which turns
`/Zc:strictStrings` on, so the earlier disable has no effect. MSVC
then fails with C2440 on writable string literals.

## Put a flag last with cxx.mode

After `using cxx`, root-scope `cxx.mode +=` appends to the same mode
vector the compile and link rules use. The extra flags come after
std-derived options and after configured mode (`config.cxx="cl ..."`).
`cxx.class` and `cxx.target.*` are already set, so the append can be
conditional:

```
# root.build

cxx.std = latest
using cxx

if ($cxx.class == 'msvc')
  cxx.mode += /Zc:strictStrings-
```

Constraints:

- Project root only. The rules do not look up per-target or
  per-directory `cxx.mode`. `obje{*}: cxx.mode +=` and a subdirectory
  `cxx.mode +=` are ignored.
- Use `+=` (append). `=+` prepends onto the already-translated vector
  and would put the flag before `/std:c++20`.
- Do not use `=` after `using cxx`. That replaces the vector and drops
  std and configured mode.
- Do not put the flag in `*.coptions`. That list is always before mode.

Do not write the `if` before `using cxx`. `cxx.class` and
`cxx.target.*` do not exist yet. Do not substitute `build.host.*` for
the compile target (see
[cross-compilation](./cross-compilation.md)).

A different form sets mode *before* `using cxx`. Configured mode is
then appended to that buildfile value. Use it when the project owns
the compiler identity (`-target`, `-nostdinc`), not when the flag must
come last:

```
cxx.std = 20
cxx.mode = -target riscv32-unknown-unknown -nostdinc
using cxx
```

`cxx.std` must be set before the module is loaded so it is translated
into mode.

Ordinary platform-conditional flags that do not need to follow std
stay in `*.coptions` after `using cxx`. The same `c.mode +=` pattern
exists for C.

## pthread

Use `-pthread` in `*.libs`, not `-lpthread`. See
[link-pthread](./link-pthread.md) for details.

## See Also

- [build2-modules-cc.md](../guides/build2-modules-cc.md) -- C-common variables and option groups
- [build2-modules-cxx.md](../guides/build2-modules-cxx.md) -- C++ compilation options reference
- [cross-compilation.md](./cross-compilation.md) -- `cxx.target.*` and `cxx.class` after `using cxx`
- [link-pthread.md](./link-pthread.md)
- [link-system-library.md](./link-system-library.md)
