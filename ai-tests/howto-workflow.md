# Tests: HOWTO -- workflow and versioning

Source documentation:
- `HOWTO/tests-extra-dependencies.md`
- `HOWTO/sanitize-tests.md`
- `HOWTO/write-build2-rule.md`
- `HOWTO/bx-script.md`
- `HOWTO/package-version-non-semver.md`
- `HOWTO/package-version-none.md`
- `HOWTO/ci-cd-setup.md`
- `HOWTO/troubleshooting.md`
- `HOWTO/test-imported-executable.md`


## T001 -- Test package naming and manifest association

**Query:** What naming convention is used for a separate test package, and which
manifest field links it to the main package?

**Key facts** (all must appear in a correct answer):
- The suffix convention is `-tests` (e.g., `libhello-tests`); `-examples` and
  `-benchmarks` are also used for the respective package kinds.
- The manifest field `tests:` in the main package's manifest associates it with
  the test package (e.g., `tests: libhello-tests == $`).
- Declaring the `tests:` field implies a dependency on the main package -- no
  explicit `depends:` on the main package is needed in the test package manifest.

**Source:** `HOWTO/tests-extra-dependencies.md`


## T002 -- Environment variables and timeouts in testscript

**Query:** How do you set an environment variable and impose a timeout on a
testscript test command?

**Key facts** (all must appear in a correct answer):
- The `env` builtin handles both environment variables and timeouts.
- Setting a variable: `env VAR=value -- $*`
- Imposing a timeout: `env --timeout 60 --timeout-success -- $*`
- `--timeout-success` treats timeout expiry as success (useful for
  servers/daemons).

**Source:** `HOWTO/sanitize-tests.md`


## T003 -- Custom rule base class and required functions

**Query:** What base class does a custom build2 rule derive from, and which
functions must it implement?

**Key facts** (all must appear in a correct answer):
- Derive from `build2::simple_rule` (declared in `libbuild2/rule.hxx`).
- Must implement `match()`: returns `true` if the rule should handle the target.
- Must implement `apply()`: declares/matches prerequisites and returns a recipe.
- The recipe is a callable returned by `apply()` that performs the actual build
  step during the execute phase; it is not a separately named virtual function.
- Rules must be stateless (or MT-safe) because `match()` may be called
  concurrently.

**Source:** `HOWTO/write-build2-rule.md`


## T004 -- Running a script with bx and task support status

**Query:** How do you run a `.bx` script with `bx`, and is named task execution
currently available?

**Key facts** (all must appear in a correct answer):
- Any argument containing `/` or ending in `.bx` is treated as a script path
  (e.g., `bx ./tools/generate.bx`).
- Arguments after the script path are forwarded verbatim to the script.
- Named task support is not yet implemented; invoking a bare task name produces
  an error.
- Scripts intended to be called directly should use the shebang
  `#! /usr/bin/env bx`.

**Source:** `HOWTO/bx-script.md`


## T005 -- Strategies for non-semver upstream versions

**Query:** What are the two strategies for packaging a project that does not use
semantic versioning, and what becomes unavailable under strategy 2?

**Key facts** (all must appear in a correct answer):
- Strategy 1: coerce to a semver-like version (e.g., `20210824` -> `2021.8.24`).
  The `version` module and all `bdep` commands work as normal. The original
  upstream version can be recorded in the `upstream-version:` manifest field.
- Strategy 2: use the upstream version as-is (adjusting only to satisfy package
  version syntax). The `version` module and most `bdep` commands (including
  `bdep-release`) cannot be used. `bdep-ci` and `bdep-publish` are still
  available but require extra steps (`--forward`, explicit `--section`).

**Source:** `HOWTO/package-version-non-semver.md`


## T006 -- Versioning options for a package with no upstream version

**Query:** What version values are recommended for a package whose upstream
project has no version at all?

**Key facts** (all must appear in a correct answer):
- Option 1: use semver starting at `0.0.1` and increment only the patch
  component (`0.0.Z`). The `version` module and all `bdep` commands including
  `bdep-release` work normally. Best for immature projects likely to adopt
  versioning later.
- Option 2: use the commit or release date in `YYYYMMDD` format (e.g.,
  `20210824`). The `version` module and most `bdep` commands cannot be used.
  Best for mature projects unlikely to adopt versioning.
- If the versioning scheme must change later, a version epoch (e.g., `+2-`)
  ensures correct ordering across scheme changes.

**Source:** `HOWTO/package-version-none.md`


## T007 -- CI pipeline commands and remote CI submission

**Query:** What commands make up a typical bdep-based CI pipeline, and which
command submits to a remote CI server?

**Key facts** (all must appear in a correct answer):
- Initialization sequence: `bdep init --empty`, `bdep config create ... @ci cc
  config.cxx=g++`, `bdep init @ci`.
- Build and test: `bdep update @ci` followed by `bdep test @ci`.
- `bdep ci` submits a CI request to a remote CI server (e.g.,
  builds.cppget.org).

**Source:** `HOWTO/ci-cd-setup.md`


## T008 -- Common build2 error patterns and resolutions

**Query:** What causes `error: no rule to update target <path>` and
`error: unknown operation <name>`, and how are they fixed?

**Key facts** (all must appear in a correct answer):
- `error: no rule to update target <path>`: the required module is not loaded,
  the target type is undeclared, or the file does not exist in the source
  directory. Fix: load the correct module in `root.build` (e.g., `using cxx`).
- `error: unknown operation <name>`: the module providing the operation (e.g.,
  `test`, `install`, `dist`) is not loaded. Fix: add `using test` (or the
  relevant module) to `build/bootstrap.build`, not to `root.build`, because
  operations must be registered at bootstrap time.

**Source:** `HOWTO/troubleshooting.md`


## T009 -- Testing an imported executable

**Query:** How do you testscript-test an imported executable (for example, a
package's own `exe{}` re-imported into its `tests/` subproject), and what
must you add to avoid an "out of date" test failure?

**Key facts** (all must appear in a correct answer):
- Import the target and override the testscript's `test` variable:
  `import t = pkg%exe{tool}` then `testscript{*}: test = $t`.
- The override alone only resolves the target with a lookup, it does not
  update it -- add the imported target as a prerequisite of the directory
  alias alongside the testscript: `./: testscript $t`.
- Without that prerequisite, testing the subproject in isolation fails with
  "target ... specified in the test variable is out of date".

**Source:** `HOWTO/test-imported-executable.md`


## T010 -- Named testscript files and @./ qualification

**Query:** What changes when using a named testscript file (e.g.,
`trtexec.testscript`) instead of the default `testscript` filename with an imported
executable in an out-of-source build?

**Key facts** (all must appear in a correct answer):
- Named testscript targets use an explicit type qualifier (`testscript{trtexec}`),
  which causes build2 to declare them in the out tree by default -- unlike the
  unqualified `testscript` filename.
- `@./` is required on the variable-assignment line in `root.build`:
  `testscript{trtexec}@./: test = $t`
- `@./` is required on the prerequisite reference in `buildfile`:
  `./: testscript{trtexec}@./ $t`
- Without `@./`, build2 implicitly declares an out-tree target that has no rule,
  and errors with "no rule to update testscript{trtexec} (implicitly declared in a
  buildfile)".
- The default `testscript` filename does not need `@./` because the wildcard form
  `testscript{*}: test = $t` does not declare a specific target, and the unqualified
  prerequisite `testscript` uses the file-based out-then-src fallback to find the
  source file.

**Source:** `HOWTO/test-imported-executable.md`
