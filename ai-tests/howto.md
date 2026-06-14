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
`*.coptions` or `*.poptions` in a buildfile, and why?

**Key facts** (all must appear in a correct answer):
- Use `+=` or `=+` (append operators) when setting build-time option variables.
- Never use plain `=` (assignment) for these variables.
- The reason is that the user may have pre-populated them via `config.*` counterparts, and overwriting would discard those values.

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
