# Migrating from CMake to build2

This guide maps common CMake patterns to their build2 equivalents. It assumes
a standard build2 project layout. Run `bdep new -l c++ -t exe myproject` to
generate the skeleton.

## Project structure

| CMake | build2 |
|---|---|
| `CMakeLists.txt` | `buildfile` per directory |
| `CMakeCache.txt` | `build/config.build` |
| `cmake_minimum_required` | Version is implicit in the toolchain install |
| `project(foo VERSION 1.2.3)` | `name: foo` + `version: 1.2.3` in `manifest` |

## Adding an executable

```cmake
# CMake
add_executable(hello hello.cpp)
```

```
# buildfile (build2)
exe{hello}: cxx{hello}
```

## Adding a library

```cmake
# CMake
add_library(mylib STATIC src/mylib.cpp)
target_include_directories(mylib PUBLIC include/)
```

```
# buildfile (build2)
lib{mylib}: {hxx cxx}{**}
lib{mylib}:
{
  cxx.export.poptions = "-I$out_root" "-I$src_root"
}
```

## Compile options

```cmake
# CMake
target_compile_options(hello PRIVATE -Wall -O2)
```

```
# buildfile (build2) -- use += to preserve user-supplied options
exe{hello}: cxx{hello}
exe{hello}: cxx.coptions += -Wall
```

See [`buildfile-compile-options`](./buildfile-compile-options.md) for which
options are appropriate in buildfiles.

## Find and link a system library

```cmake
# CMake
find_package(Threads REQUIRED)
target_link_libraries(hello Threads::Threads)
```

```
# buildfile (build2)
if ($cxx.target.class != 'windows')
  cxx.libs += -pthread
```

## Find and link an installed library (pkg-config)

```cmake
# CMake
find_package(ZLIB REQUIRED)
target_link_libraries(hello ZLIB::ZLIB)
```

```
# buildfile (build2)
import libs = zlib%lib{z}
exe{hello}: cxx{hello} $libs
```

build2 uses the `zlib.pc` file to find include paths and link flags
automatically. No `find_package` equivalent is needed.

## Conditional compilation

```cmake
# CMake
if(WIN32)
  target_compile_definitions(hello PRIVATE _WIN32_WINNT=0x0601)
endif()
```

```
# buildfile (build2)
if ($cxx.target.class == 'windows')
  cxx.poptions += -D_WIN32_WINNT=0x0601
```

## Install rules

```cmake
# CMake
install(TARGETS hello DESTINATION bin)
install(FILES include/hello.h DESTINATION include)
```

```
# buildfile (build2) -- install module handles this automatically
# Headers install to include/, binaries to bin/ by default.
# Customize with the install variable:
hxx{*}:
{
  install         = include/hello/
  install.subdirs = true
}
```

## See Also

- [`build2-intro-concepts`](../guides/build2-intro-concepts.md) -- foundational concepts
- [`build2-buildfile-language`](../guides/build2-buildfile-language.md) -- full buildfile syntax
- [`build2-projects-advanced`](../guides/build2-projects-advanced.md) -- library metadata protocol
- [`link-system-library`](./link-system-library.md) -- linking system libraries
- [`packaging-guide-summary`](../guides/packaging-guide-summary.md) -- packaging for distribution
