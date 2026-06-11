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

## pthread

Use `-pthread` in `*.libs`, not `-lpthread`. See
[link-pthread](./link-pthread.md) for details.

## See Also

- [build2-modules-cc.md](../guides/build2-modules-cc.md) -- C-common variables and option groups
- [build2-modules-cxx.md](../guides/build2-modules-cxx.md) -- C++ compilation options reference
- [link-pthread.md](./link-pthread.md)
- [link-system-library.md](./link-system-library.md)
