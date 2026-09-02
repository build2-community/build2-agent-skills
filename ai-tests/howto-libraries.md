# Tests: HOWTO -- libraries

Source documentation: `HOWTO/header-only-library.md`, `HOWTO/library-provides-main.md`, `HOWTO/link-pthread.md`, `HOWTO/third-party-private-headers.md`, `HOWTO/link-prerequisite-order.md`, `HOWTO/match-upstream-library-name.md`, `HOWTO/import-immediate-vs-ordinary.md`


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


## T006 -- Match upstream library output names

**Query:** When packaging a third-party shared library whose file is
opened by a dynamic loader or `dlopen()` by a fixed path, how should the
build2 target name and the generated artifact relate to upstream, and
which knobs change SONAME and the MinGW `lib` prefix?

**Key facts** (all must appear in a correct answer):
- Build2 target identifiers (`lib{MoltenVK}`) are a separate namespace
  from package `name:` and `project:`.
- Prefer matching the upstream target name directly. At minimum, match
  the generated artifact including SONAME, version suffix, and prefix,
  not just the base name.
- Default `bin.lib.version` is a platform-independent suffix and does
  not produce Linux `libhello.so.MAJOR`.
- Linux SONAME uses a `linux@MAJOR.MINOR` or `MAJOR.MINOR.EXTRA` pair
  (MINOR is required). Platform-specific `bin.lib.version` is currently
  implemented only on Linux.
- Unset `bin.lib.prefix` defaults to `lib` on MinGW. An empty assignment
  suppresses that prefix (`vulkan-1.dll` rather than `libvulkan-1.dll`).

**Source:** `HOWTO/match-upstream-library-name.md`


## T007 -- When upstream SONAME matching is unnecessary, and the pre-release guard

**Query:** I'm packaging an ordinary third-party library that will only ever
be consumed as a bpkg dependency, never `dlopen()`'d by a fixed name and
never linked by a non-bpkg consumer. Do I need to override `bin.lib.version`
to match upstream's SONAME? Separately, if I do customize it for another
package, why does the generated default guard on `$version.pre_release`, and
should I keep that guard when I add platform-specific branches?

**Key facts** (all must appear in a correct answer):
- Matching upstream only matters once the produced file is resolved by
  something other than this configuration's own build2/bpkg dependency
  graph. build2's link rule embeds an rpath for every shared library
  dependency, so a library consumed only as a bpkg dependency finds it by
  that recorded path, not by a system-wide SONAME lookup.
- For a library consumed only as a bpkg dependency, with no `dlopen()` by a
  fixed name and no non-bpkg consumer, the generated default `bin.lib.version`
  is fine as is.
- The `if $version.pre_release` branch in the generated default exists so a
  pre-release snapshot's version suffix can never be mistaken for another
  pre-release or the final release.
- That guard must be kept when customizing the other branches for
  upstream/platform matching -- only the `else` (or per-platform `elif`)
  branches should change.

**Source:** `HOWTO/match-upstream-library-name.md`


## T008 -- Immediate import for metadata, ordinary import for linking

**Query:** I use `import? [metadata, rule_hint=c.link] liba = libfoo%liba{foo}`
to query a library's metadata, and I also need to link that library into my
`exe{}`. Can I just add `$liba` as a link prerequisite, and if not, what
should I do instead, especially for the installed case?

**Key facts** (all must appear in a correct answer):
- No: keep the immediate import (`import!`/`import?`) in its own variable
  for metadata or an optional presence probe only. `import?` is always
  immediate; there is no deferred-optional form.
- Issue a second, ordinary (deferred) `import` into `libs` (or
  `intf_libs`/`impl_libs`) for the actual link prerequisite.
- Reaching the installed-library search from an immediate import requires
  `rule_hint=c.link`/`cxx.link`, but that search still runs without a
  consumer, so implementation dependencies and rpath are not attached the
  way they are for an ordinary import matched against the real `exe{}`/`lib{}`.
- Linking the immediate target directly often still works in-tree (the
  export stub carries `$impl_libs`), but breaks in the installed case (no
  export stub, so a static consumer can fail at runtime with an unresolved
  shared dependency).

**Source:** `HOWTO/import-immediate-vs-ordinary.md`
