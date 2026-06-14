# Tests: b -- build system driver

Source documentation: `b/README.md`, `b/b.md`


## T001 -- Default buildspec

**Query:** What does `b` execute when invoked with no arguments?

**Key facts** (all must appear in a correct answer):
- The default buildspec expands to `perform(update(./))`.
- `perform` is the default meta-operation.
- `update` is the default operation for `perform`.
- `./` (the current directory) is the default target.

**Source:** `b/README.md`


## T002 -- Meta-operations

**Query:** List all meta-operations that the build system driver `b` supports.

**Key facts** (all must appear in a correct answer):
- `perform` -- execute an operation on a target.
- `configure` -- configure a project and save the result to `build/config.build`.
- `disfigure` -- undo a previous `configure`.
- `create` -- create and configure an amalgamation (configuration project).
- `dist` -- prepare a source distribution.
- `info` -- print project metadata (name, version, directories) to stdout.

**Source:** `b/README.md`


## T003 -- configure saves to build/config.build

**Query:** Where does `b configure` write its output?

**Key facts** (all must appear in a correct answer):
- The result is saved to `build/config.build`.

**Source:** `b/README.md`


## T004 -- update-for-test vs update

**Query:** What is the difference between the `update` and `update-for-test`
operations in build2?

**Key facts** (all must appear in a correct answer):
- `update` builds all targets.
- `update-for-test` builds only what is necessary for running tests.

**Source:** `b/README.md`


## T005 -- Multiple operations in one invocation

**Query:** How do you run `clean` and then `update` in a single `b` invocation?

**Key facts** (all must appear in a correct answer):
- Both operations can be listed together: `b clean update`.
- This expands to `perform(clean(./) update(./))`.

**Source:** `b/README.md`


## T006 -- info with JSON output

**Query:** How do you print build2 project metadata in JSON format?

**Key facts** (all must appear in a correct answer):
- The `info` meta-operation accepts a `json` parameter.
- Example form: `b info: <dir>,json`

**Source:** `b/README.md`
