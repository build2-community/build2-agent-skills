# Tests: HOWTO -- build and configuration

Source documentation: `HOWTO/cross-compilation.md`, `HOWTO/generated-headers.md`,
`HOWTO/multiple-configurations.md`, `HOWTO/config-independent-build-graph.md`,
`HOWTO/target-metadata.md`, `HOWTO/for-install-conflicts.md`,
`HOWTO/update-for-test-install.md`, `HOWTO/test-runtime-fixtures.md`,
`HOWTO/conditional-dependency-config.md`, `HOWTO/exclude-test-data-from-dist.md`


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


## T009 -- bdep init -C: cfg-args vs pkg-args for conditional dependencies

**Query:** When using `bdep init -C` to create a build configuration, where must
a package config variable like `config.libfoo.cuda=true` be placed if it is
needed to activate a conditional `depends:` entry, and what happens if it is
placed in the wrong position?

**Key facts** (all must appear in a correct answer):
- `bdep init -C` splits arguments into `<cfg-args>` (before `--`) and `<pkg-args>`
  (after `--`).
- `<cfg-args>` are forwarded to `bpkg cfg-create`; `<pkg-args>` are forwarded to
  `bpkg pkg-build`.
- Package config variables (e.g. `config.libfoo.cuda=true`) must go in `<pkg-args>`,
  after `--`.
- If placed in `<cfg-args>`, `bpkg cfg-create` has no schema for them and silently
  drops them; no error or warning is emitted.
- The conditional dependency then evaluates to the declared default (usually
  `false`) and the optional feature is not installed.
- When there are no `<cfg-args>` but there are `<pkg-args>`, two `--` separators
  are required.

**Source:** `HOWTO/conditional-dependency-config.md`


## T010 -- source-tree test data vs NEWS fsdir{}

**Query:** How do you give Testscript-driven tests access to source-tree data
directories that the test opens by relative name (for example `"inputs/..."`),
and why is the NEWS `fsdir{}` directory-symlink recipe the wrong tool for
that?

**Key facts** (all must appear in a correct answer):
- List the files as `include = adhoc` prerequisites of the test executable
  (for example `exe{test-parse_examples}: file{inputs/**}: include = adhoc`)
  so `dist` and `update-for-test` see them.
- In the testscript, `ln -s $src_base/inputs/ inputs` inside `$~` (a test
  scope so the links and the executable share a working directory). Trailing
  slash on the source is directory syntax.
- Do not `env -c $out_base` or `env -c $src_base`. Testscript will not
  auto-clean writes outside `$~`.
- NEWS `fsdir{}` with `ln -s $src_base/assets $out_base/assets` is for a
  program that needs an asset directory next to it at runtime, not for tests.
- Using that NEWS recipe for test data breaks in-source `b clean`
  (`rm: '...' is a directory`) because `src_base == out_base` makes
  `fsdir{inputs/}` the real source directory. `bdep test` is out-of-source
  and hides this.

**Source:** `HOWTO/test-runtime-fixtures.md`


## T011 -- Excluding test fixtures from a b dist archive

**Query:** A test's fixture data (a single large file, or a whole
`tests/resources/` directory) should stay in the git checkout but not ship
in the `b dist` archive. `dir{resources}/: dist = false`, `include = false`,
and `tests/: install = false` all seem plausible and none of them work. What
is the actual correct recipe?

**Key facts** (all must appear in a correct answer):
- `dist = false` must be a target-specific assignment -- its own buildfile
  line naming the target on the left of the colon (`file{data/fixture.txt}:
  dist = false`), not chained after a prerequisite on someone else's
  declaration line (`./: file{data/fixture.txt}: dist = false` sets a
  prerequisite-specific value that `dist`'s collector never reads and is
  silently ignored).
- `include = false` alone does not exclude a file from the archive:
  `dist_include()` rewrites excluded prerequisites to adhoc so "every
  source is included into the distribution."
- `dir{resources}/: dist = false` (target-specific, on the `dir{}` target)
  is a silent no-op: `dist`'s collector only ever walks `file` targets.
- A brace-block scope assignment (`resources/ { dist = false }`) is a hard
  parse error (`dist` has target visibility, cannot be assigned on a
  scope).
- `tests/: install = false` has no effect on `dist`: that cascading lookup
  is specific to the `install` module's rule, which `dist` does not have.
- The working recipe combines both knobs: `include = false` (keeps the
  build from requiring the now-uncopied file) plus target-specific
  `dist = false` (removes it from the archive). Without `include = false`,
  rebuilding the unpacked archive in-source fails with "no rule to update"
  because the buildfile still declares the prerequisite but the file is
  gone.
- Wrapping the declaration in `if` instead produces a dist-only parser
  warning ("conditional dependency declaration may result in incomplete
  distribution") and does not exclude the file under the branch taken.

**Source:** `HOWTO/exclude-test-data-from-dist.md`

**Source:** `HOWTO/test-runtime-fixtures.md`
