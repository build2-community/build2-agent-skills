# Tests: HOWTO -- practical recipes

Source documentation: `HOWTO/alias-targets.md`, `HOWTO/buildfile-compile-options.md`,
`HOWTO/link-system-library.md`, `HOWTO/package-naming.md`, `HOWTO/assert-in-tests.md`,
`HOWTO/optional-library-components.md`


## T001 -- alias{} as PHONY equivalent

**Query:** What is the build2 equivalent of a PHONY target, how must you invoke
it, and what happens if you omit the target type?

**Key facts** (all must appear in a correct answer):
- The PHONY equivalent in build2 is a target with the `alias{}` target type.
- You must invoke it by specifying the type explicitly, e.g. `b alias{upload}`.
- Without the type, the name is treated as an operation name, not a target.

**Source:** `HOWTO/alias-targets.md`


## T002 -- Compile option variable assignment operators

**Query:** Which assignment operators must and must not be used when setting
`*.coptions`, `*.poptions`, or `bin.rpath` in a buildfile, how does that
differ for `*.export.*`, and why?

**Key facts** (all must appear in a correct answer):
- Use `+=` or `=+` for accumulated lists (`*.poptions`, `*.coptions`,
  `*.libs`, `bin.rpath`, and similar). Never use plain `=` as the only
  write. A target-specific `=` replaces the outer value, including
  `config.*`.
- `bin.rpath` is the same append class: `config.bin.rpath` is merged into
  the root-scope `bin.rpath` list.
- `*.export.poptions`, `*.export.loptions`, and `*.export.libs` have no
  `config.*` counterpart. The first write is `=`. Later split writes use
  `+=`.

**Source:** `HOWTO/buildfile-compile-options.md`


## T003 -- System library variables

**Query:** Which variable holds a build-time-only system library dependency,
which additional variable is needed when it is also an interface dependency,
and what does a concrete example look like?

**Key facts** (all must appear in a correct answer):
- A build-time-only system dependency is listed in `*.libs` (e.g. `c.libs += -lm`).
- When the system library is also an interface dependency (consumers must link it too), it must also be listed in `*.export.libs`.
- Example: `c.libs += -lm` and `lib{hello}: c.export.libs = -lm` together cover both cases.

**Source:** `HOWTO/link-system-library.md`


## T004 -- Library package naming and the split convention

**Query:** What prefix is recommended for library packages, and how should a
project that provides both a library and an executable be split?

**Key facts** (all must appear in a correct answer):
- Library packages should use the `lib` prefix to avoid future name conflicts with executables.
- A project providing both should be split: the library package gets the prefix and the executable package keeps the bare name.
- Concrete example from the docs: the `lz4` project is split into `liblz4` (library package) and `lz4` (executable package) inside a single `lz4` git repository.
- The `lib` prefix must be added even if only the library is packaged initially, because removing it later is disruptive.

**Source:** `HOWTO/package-naming.md`


## T005 -- assert() in tests when NDEBUG is defined

**Query:** What two steps ensure assert() works in test code even when NDEBUG
is defined, and what ordering rule applies?

**Key facts** (all must appear in a correct answer):
- Step 1: `#undef NDEBUG` immediately before including `<cassert>`.
- Step 2: include `<cassert>` last, after all other headers.
- The ordering rule: other headers included before `<cassert>` should still see `NDEBUG` with its normal effect, so `<cassert>` must come last.

**Source:** `HOWTO/assert-in-tests.md`


## T006 -- Optional component strategies

**Query:** What are the three strategies for optional library components, what
is the preferred order among them, and when is each appropriate?

**Key facts** (all must appear in a correct answer):
- Strategy 1 (most preferred): include the component unconditionally -- appropriate when it is not large and has no additional dependencies, since the static linker drops unused components automatically.
- Strategy 2 (preferred over config variables): factor the component into a separate library (or package) -- appropriate when the component requires additional dependencies.
- Strategy 3 (last resort): use configuration variables to gate the component -- appropriate only when factoring into a separate library is not possible, e.g. when packaging a third-party project.

**Source:** `HOWTO/optional-library-components.md`


## T007 -- Compile recipe order

**Query:** In what order does build2 assemble the C++ compile command line,
where does `cxx.std` end up, and can a `coptions` assignment come after that?

**Key facts** (all must appear in a correct answer):
- The compile command line order is path, `poptions`, `coptions`, then `*.mode`.
- Mode options appear last.
- `cxx.std` is translated into mode (`-std=`, `/std:c++20`, `/Zc:__cplusplus`).
- No `coptions` assignment, directory, or target can come after mode.

**Source:** `HOWTO/buildfile-compile-options.md`


## T008 -- Place a flag last with cxx.mode

**Query:** How do you append a compiler flag so it appears after `/std:c++20`,
including when the flag is platform-conditional, and which operators and
scopes must you not use?

**Key facts** (all must appear in a correct answer):
- After `using cxx`, append at project root with `cxx.mode +=`.
- `cxx.class` and `cxx.target.*` are available after `using cxx`, so the
  append can be wrapped in `if ($cxx.class == 'msvc')` or a `cxx.target.*`
  check.
- Use `+=` (append). Do not use `=+` (that prepends and would put the flag
  before `/std:c++20`). Do not use `=` after `using cxx` (that replaces the
  vector and drops std and configured mode).
- Do not put the flag in `*.coptions` (that list is always before mode).
- Do not use `build.host.*` for the compile target.

**Source:** `HOWTO/buildfile-compile-options.md`


## T009 -- Repository vs project: vs package name case

**Query:** When packaging a third-party project whose upstream repository
name has mixed case (for example MoltenVK), what case convention applies
to the git repository name, the manifest `project:` field, and the
package `name:` field?

**Key facts** (all must appear in a correct answer):
- The git repository name mirrors the upstream repository name exactly,
  including case (example: `MoltenVK`).
- Manifest `project:` is lowercase even when the repository is mixed
  case (example: `project: moltenvk`).
- Package `name:` is lowercase by default (example: `libmoltenvk`).
- This is convention, not a parser rule: nothing rejects
  `project: MoltenVK`.
- The packaging guide's Qt rows (`Qt5Moc`, `libQt5Core`) are the
  documented exception when mixed case is the upstream identifier.

**Source:** `HOWTO/package-naming.md`
