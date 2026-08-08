# Tests: HOWTO -- build and configuration

Source documentation: `HOWTO/cross-compilation.md`, `HOWTO/generated-headers.md`,
`HOWTO/multiple-configurations.md`, `HOWTO/config-independent-build-graph.md`,
`HOWTO/target-metadata.md`, `HOWTO/for-install-conflicts.md`,
`HOWTO/update-for-test-install.md`


## T001 -- Cross-compilation: detecting the target platform in buildfiles

**Query:** Which variables should you use in a buildfile to write
platform-conditional code that works in both native and cross-compilation
scenarios, and which variables must you NOT use for this purpose?

**Key facts** (all must appear in a correct answer):
- Use `cxx.target.class` or `cxx.target.system` for target platform detection.
- Never use `build.host.*` for target platform detection.
- `cxx.target.class` example values: `'windows'`, `'linux'`.
- `cxx.target.system` example values: `'mingw32'`.

**Source:** `HOWTO/cross-compilation.md`


## T002 -- Auto-generated headers from build2 0.15.0

**Query:** What does build2 do automatically from version 0.15.0 for headers
listed as prerequisites of a library or executable, and what problem does this
prevent?

**Key facts** (all must appear in a correct answer):
- From 0.15.0, all headers listed as prerequisites are pre-generated during the
  match phase, before any source file is compiled.
- Without pre-generation, a compiler encountering a missing header during
  dependency extraction would trigger on-demand generation, which fails or
  produces wrong results in four situations.
- Two of the four mis-inclusion cases that pre-generation avoids: an outdated
  (stale) generated header being included, and the wrong header (from the
  source directory) being picked up before the correct one is generated in the
  output directory.

**Source:** `HOWTO/generated-headers.md`


## T003 -- Creating and targeting a named bdep configuration

**Query:** How do you create a named bdep build configuration, and how do you
later operate on that specific configuration by name?

**Key facts** (all must appear in a correct answer):
- Create a named configuration with `bdep config create -d <dir> @<name>`.
- The `@name` suffix is the short alias assigned to the configuration.
- Operate on a specific named configuration by passing the alias, e.g.,
  `bdep update @gcc`.
- Example creation: `bdep config create -d ../build-gcc @gcc cc config.cxx=g++`.

**Source:** `HOWTO/multiple-configurations.md`


## T004 -- Config-independent build graph: warning and fix

**Query:** What warning does build2 emit when a buildfile violates the
config-independent build graph requirement, and what is the recommended fix?

**Key facts** (all must appear in a correct answer):
- Warning text: `warning: conditional dependency declaration may result in
  incomplete distribution`.
- The warning also advises using the `include` prerequisite-specific variable
  instead of `if` guards on dependency declarations.
- The fix is to declare all targets unconditionally and use
  `include = (<condition>)` to control whether a prerequisite participates in
  the build for a given configuration.
- Example: `exe{hello}: cxx{utility-posix}: include = ($cxx.target.class != 'windows')`.

**Source:** `HOWTO/config-independent-build-graph.md`


## T005 -- export.metadata format and protocol version

**Query:** What is the format of the `export.metadata` variable value for an
installed C/C++ library, and what is the protocol version number?

**Key facts** (all must appear in a correct answer):
- The value has two elements: the protocol version followed by the variable
  name prefix.
- The protocol version is always `1`.
- Example: `export.metadata = 1 libhello`.
- Only variables whose names start with the given prefix are saved to the
  `.pc` pkg-config file.

**Source:** `HOWTO/target-metadata.md`


## T006 -- For-install conflict error: meaning and resolution

**Query:** What does the "already updated but [not] for install" error mean in
build2, and how is it resolved?

**Key facts** (all must appear in a correct answer):
- The error means two targets in the same build require the same dependency in
  incompatible flavours: one for-install and one for-development.
- Example messages: `target is already updated but for install` and `target is
  already updated but not for install`.
- The most common trigger is an executable that is both being installed and run
  as a build tool in the same build.
- The fix is to use a separate build configuration for installation, where the
  executable does not need to be run.

**Source:** `HOWTO/for-install-conflicts.md`


## T007 -- update-for-test and update-for-install vs plain update

**Query:** What do `update-for-test` and `update-for-install` do differently
from plain `update`, and what is an example invocation of each?

**Key facts** (all must appear in a correct answer):
- `update-for-test` builds only what is needed for testing (test executables
  and their dependencies) without actually running the tests.
- `update-for-install` builds only what is needed for installation (the
  for-install variants of libraries and executables) without writing anything
  to the install root.
- Both differ from plain `update` because they request the correct build
  flavour (for-install re-links shared libraries and executables without rpath)
  without the side effects of running tests or installing files.
- Example invocations: `b update-for-test` and `b update-for-install`.

**Source:** `HOWTO/update-for-test-install.md`


## T008 -- runtime test fixtures and test.input

**Query:** How do you make child-process helper executables build under
`update-for-test` for Testscript-driven unit tests, and why is
`test.input = true` the wrong tool for that?

**Key facts** (all must appear in a correct answer):
- Mark fixture exes with `test = false` so they are not run as smoke tests.
- Attach fixtures as `include = adhoc` prerequisites of the test executable,
  not of the testscript (for example
  `exe{unit-foo}: ../resources/exe{helper}: include = adhoc`).
- Giving the testscript its own dependency declaration instead of only
  listing it as a prerequisite (`testscript{name}@./: <target>`) makes it
  an independently-declared target with no `clean` rule, breaking
  `b clean`; `@./` itself is not the cause -- it only pins the target to
  `src`.
- `test.input` is for simple tests only: it updates the prereq and appends
  its path as an extra argv argument. It is not for Testscript path-based
  fixtures.
- Merely listing a `test = false` exe on `./:` is not enough for
  `update-for-test`.

**Source:** `HOWTO/test-runtime-fixtures.md`
