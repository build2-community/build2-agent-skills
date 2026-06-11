# Linking pthread

For modern pthread-based targets (Linux, FreeBSD, macOS, MinGW) add `-pthread`
to [`*.libs`](../guides/build2-modules-cxx.md#build-time-options-affect-this-targets-compilationlinking),
not `-lpthread`. The compiler translates `-pthread` to nothing on platforms
where `pthread` is already part of `libc` (macOS, Linux with glibc >= 2.34):

```
if ($cxx.target.system != 'win32-msvc')
  cxx.libs += -pthread
```

If the `pthread` API or C++11 threading types (`<thread>`, `<mutex>`,
`<condition_variable>`, `<future>`) appear in the library's public interface
(inline or template functions), also add `-pthread` to
[`*.export.libs`](../guides/build2-modules-cxx.md#export-options-propagated-to-consumers-of-a-library):

```
if ($cxx.target.system != 'win32-msvc')
{
  cxx.libs += -pthread

  lib{foo}: cxx.export.libs += -pthread
}
```

## Background

`-pthread` was designed to be passed at both compile and link time. Modern
general-purpose OSes (Linux/glibc, FreeBSD, macOS, MinGW) no longer need the
compile-time macro definitions it used to add, and on some (macOS, Linux/glibc
>= 2.34) `pthread` is part of `libc` so no separate library needs linking
either. Using `-pthread` instead of `-lpthread` lets the compiler translate it
to nothing where appropriate.

## Legacy and high-touch targets

For targets that still require `-pthread` at compile time (legacy POSIX,
Emscripten), the correct approach is for the user to configure their entire
build with `-pthread` as a compiler mode option, not for the library to impose
it via export options:

```
config.cxx="g++ -pthread"
```

## See Also

- [build2-modules-cc.md](../guides/build2-modules-cc.md) -- *.libs variables and link options
- [link-system-library.md](./link-system-library.md)
- [buildfile-compile-options.md](./buildfile-compile-options.md)
