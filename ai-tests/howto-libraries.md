# Tests: HOWTO -- libraries

Source documentation: `HOWTO/header-only-library.md`, `HOWTO/library-provides-main.md`, `HOWTO/link-pthread.md`, `HOWTO/third-party-private-headers.md`, `HOWTO/link-prerequisite-order.md`


## T001 -- Binless library system dependencies in both *.libs and *.export.libs

**Query:** A binless (header-only) library depends on a system library such as
`-lm`. Where must that dependency be listed, and why?

**Key facts** (all must appear in a correct answer):
- The dependency must appear in both `*.libs` and `*.export.libs`.
- `*.export.libs` propagates the dependency to consumers of the library.
- `*.libs` is needed when linking the static variant of the binless library,
  because the static variant has no binary of its own and the linker must be
  told about the system library explicitly at that point.

**Source:** `HOWTO/header-only-library.md`


## T002 -- Library that provides main(): variant, variable, and why not shared

**Query:** How does a build2 library supply an optional `main()` implementation
to consumers, which variable controls the linking behaviour, and why is the
shared library variant not recommended for this purpose?

**Key facts** (all must appear in a correct answer):
- The `main()` implementation is placed in a static library (`liba{}`).
- The static library must be linked in whole-archive mode: `bin.whole = true`.
- Shared libraries providing `main()` are not recommended due to
  platform-specific complications.

**Source:** `HOWTO/library-provides-main.md`


## T003 -- Linking pthread: correct flag, variables, and when to export

**Query:** How should a build2 library add pthread support on Linux and macOS:
which compiler flag, which variable(s), and when must the flag also be
propagated to consumers?

**Key facts** (all must appear in a correct answer):
- Use `-pthread`, not `-lpthread`.
- Add `-pthread` to `*.libs` (e.g., `cxx.libs += -pthread`).
- The compiler translates `-pthread` to nothing on platforms where `pthread`
  is already part of `libc` (macOS, Linux with glibc >= 2.34).
- If the pthread API or C++11 threading types (`<thread>`, `<mutex>`,
  `<condition_variable>`, `<future>`) appear in the library's public interface
  (inline or template functions), also add `-pthread` to `*.export.libs`.

**Source:** `HOWTO/link-pthread.md`


## T004 -- Private headers that must not appear in the installed include tree

**Query:** How does a build2 buildfile handle private implementation headers
that should be visible during the build but must not be installed or exposed
to consumers of the library?

**Key facts** (all must appear in a correct answer):
- Private include paths are added to `cxx.poptions` (or `c.poptions`), never
  to `cxx.export.poptions`.
- `cxx.export.poptions` carries only the public include paths that consumers
  need.
- Private header targets are marked `install = false` so they are not copied
  into the install tree.

**Source:** `HOWTO/third-party-private-headers.md`


## T005 -- Link-rule prerequisite order on exe{} and libs{}

**Query:** Why does `exe{x}: $libs cxx{x}` fail with undefined references
under GNU ld when `$libs` is a static archive, what is the correct
prerequisite order, and does the same order bug apply to `liba{}`?

**Key facts** (all must appear in a correct answer):
- Prerequisite order on a linked `exe{}` or `libs{}` is link-line order.
- List object and source prerequisites before `$libs`.
- GNU ld is single-pass on static archives.
- Split declarations that list `$libs` first then the source are the same bug.
- `liba{}` is archived, so this failure mode does not apply there.

**Source:** `HOWTO/link-prerequisite-order.md`
