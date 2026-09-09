# Tests: HOWTO -- build and configuration

Source documentation: `HOWTO/cross-compilation.md`, `HOWTO/generated-headers.md`,
`HOWTO/multiple-configurations.md`, `HOWTO/config-independent-build-graph.md`,
`HOWTO/target-metadata.md`, `HOWTO/for-install-conflicts.md`,
`HOWTO/update-for-test-install.md`, `HOWTO/test-runtime-fixtures.md`,
`HOWTO/conditional-dependency-config.md`, `HOWTO/exclude-test-data-from-dist.md`,
`HOWTO/fsdir-parent-chain.md`, `HOWTO/builds-ci-filtering.md`,
`HOWTO/sys-build-config.md`, `HOWTO/ad-hoc-recipe.md`,
`HOWTO/local-installed-import.md`, `HOWTO/ci-results.md`


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


## T012 -- fsdir{} parent auto-creation is out-of-tree only

**Query:** When does the built-in fsdir{} rule auto-create parent
directories, what must you declare for a nested directory in an in-source
build, and which test actually catches a missing chain?

**Key facts** (all must appear in a correct answer):
- Parent directories are auto-created only when the target directory is
  not under the project's `src_path()` (out-of-tree).
- In-source (`out_base == src_base`) auto-inject never fires. Only an
  explicitly declared `fsdir{}` prerequisite is honored.
- Every missing intermediate level needs its own `fsdir{}`-to-`fsdir{}`
  prerequisite.
- A forwarded out-of-source config hides a missing chain because that is
  where the cascade fires.
- The check that matters for publish is `b dist` then in-source
  `configure` then `update` of the unpacked archive.
- This is intentional build2 behavior, not a defect.

**Source:** `HOWTO/fsdir-parent-chain.md`


## T013 -- Requesting system-provided libraries on specific CI bots with sys

**Query:** How do you get a specific per-configuration CI bot to resolve a
dependency against the system-provided library instead of building it from
source, what does the leading `?` mean in a `*-build-config` dependency spec
like `?sys:libz`, and what does the `sys` class actually control?

**Key facts** (all must appear in a correct answer):
- Pair a `*-build-config:` value listing `sys:<pkg>` dependency specs with a
  matching `*-builds:` override naming the `sys` class (for example
  `fedora-x11-build-config: sys:libxi` with `fedora-x11-builds: sys`).
- The `<name>` in `*-build-config`/`*-builds` (e.g. `fedora-x11`) is an
  arbitrary package-chosen configuration name defining an additional
  configuration built alongside `default`, not the name of an existing bot
  configuration. `sys` in the `*-builds:` value is the separate,
  deployment-defined class restricting which real bot machines that
  configuration runs on.
- The `*-build-config` dependency-spec grammar permits both `sys:<pkg>`
  (bare) and `?sys:<pkg>` forms. The `?` is the same `pkg-spec` flag used
  with `bpkg build`: without it the package is built to hold, with it it is
  built as a dependency (dropped once nothing depends on it), not an
  "optional dependency" marker.
- Resolving `sys:<pkg>` queries the system package manager for an
  already-installed version and does not install anything without
  `--sys-install`. Neither `build2-toolchain` nor the live cppget.org
  build-configs page documents what the `sys` class itself does; the
  best-supported explanation is that it identifies bot machines provisioned
  with those libraries preinstalled.
- `bbot`'s `bbot.sys-install` worker step is unrelated: it installs a
  package's own generated binary distribution artifact to verify it installs
  cleanly, not a package's `sys:` dependencies.
- This mechanism only applies to libraries an actual system package manager
  distributes. OS/SDK-bundled frameworks with no installable package name
  (e.g. Apple's Metal, Cocoa, IOKit, CoreVideo) are outside its scope and are
  typically linked directly instead (e.g. via `-framework`).

**Source:** `HOWTO/sys-build-config.md`, `bpkg/bpkg-manifest-reference.md`


## T014 -- Ad hoc recipe attachment and impure functions

**Query:** Can I put a `{{ }}` recipe immediately after
`exe{driver}: $foo: include = adhoc`, and how must `$cxx.lib_poptions()` be
called inside a recipe?

**Key facts** (all must appear in a correct answer):
- A recipe block may only follow a plain `target: prereqs` declaration, not
  a prerequisite-specific assignment. Put the `include = adhoc` line first
  and the plain prerequisite line last, immediately before `{{`.
- Otherwise the parse error is `unexpected '{{'`.
- `$cxx.lib_poptions()` (and `$cxx.lib_libs()` / `$cxx.lib_rpaths()`) are
  not pure. In a recipe they may only be called in the depdb preamble,
  immediately followed by `depdb hash <value>`.
- `$cxx.lib_rpaths()` is for a hand-rolled link line, not a substitute for
  `bin.rpath` on a target that still uses the stock link rule.

**Source:** `HOWTO/ad-hoc-recipe.md`


## T015 -- Local installed import! check

**Query:** How do I locally verify that `import! [metadata, rule_hint=cxx.link]`
works against an installed library, and is `PKG_CONFIG_PATH` required if I
already pass `-L<prefix>/lib`?

**Key facts** (all must appear in a correct answer):
- Install the dependency into a prefix from one bpkg configuration, then
  consume it from a second configuration with
  `config.cc.loptions+=-L<prefix>/lib`.
- Installed-library search looks for the binary in `-L` directories and
  for the `.pc` in that directory's `pkgconfig/` subdirectory, so `-L` is
  enough when the install layout is `<prefix>/lib` plus
  `<prefix>/lib/pkgconfig`.
- `PKG_CONFIG_PATH` is only needed when the `.pc` is not next to the
  library.
- A plain `import` can find the binary from `-L` alone.
  `import! [metadata]` still needs the `.pc` because that is where
  `export.metadata` lives for an installed library.

**Source:** `HOWTO/local-installed-import.md`


## T016 -- builds: -static when tests import libs{}

**Query:** A tests package does `import! [metadata] ... %libs{foo}` and CI
fails on a `config.bin.lib=static` configuration with `unable to import
target`. What manifest line fixes it, and on which package?

**Key facts** (all must appear in a correct answer):
- The shared member does not exist when only static is built, and the
  diagnostic does not mention a missing build-class exclusion.
- Put `builds: -static` on the tests/companion package's own manifest.
- `static` is a deployment-defined class on cppget.org, not one of the
  five pre-defined names.

**Source:** `HOWTO/builds-ci-filtering.md`


## T017 -- cppget.org test-installed results

**Query:** Does the `test-installed` phase on cppget.org run once for the
whole CI matrix, and why does a passing run often have no separate
`test-installed` badge?

**Key facts** (all must appear in a correct answer):
- `test-installed` runs per build-configuration, not once for the matrix.
- A passing run is folded into that configuration's `log` link with no
  separate badge.
- A warning or error gets its own `test-installed` link.
- This is cppget.org UI, not a `bdep` contract.

**Source:** `HOWTO/ci-results.md`

