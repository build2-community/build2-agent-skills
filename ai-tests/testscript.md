# Tests: Testscript language

Source documentation: `guides/testscript-summary.md`,
`guides/testscript-commands.md`


## T001 -- Conventional filename

**Query:** What is the conventional filename for a single testscript file, and
what extension do multiple testscript files use?

**Key facts** (all must appear in a correct answer):
- A single testscript file is conventionally named `testscript` (no extension).
- When a target has multiple testscript files, each uses the `.testscript`
  extension (e.g. `basics.testscript`).

**Source:** `guides/testscript-summary.md`


## T002 -- Associating a testscript with a target

**Query:** How is a testscript file associated with its test target in a
buildfile?

**Key facts** (all must appear in a correct answer):
- The testscript is listed as a prerequisite of the test target.
- Example: `exe{hello}: cxx{hello} testscript`
- The `test` module registers the `testscript{}` target type.

**Source:** `guides/testscript-summary.md`


## T003 -- Filtering tests at build time

**Query:** How do you run only tests whose id contains `basics` when invoking
`b test`?

**Key facts** (all must appear in a correct answer):
- Use the `config.test` variable to filter: `b test config.test=basics`
- This runs all tests in `basics.testscript`.

**Source:** `guides/testscript-summary.md`


## T004 -- Preserving test working directories

**Query:** How do you tell the testscript runner to keep working directories
after a test run (useful for debugging)?

**Key facts** (all must appear in a correct answer):
- Set `config.test.output=keep`.
- Example: `b test config.test.output=keep`

**Source:** `guides/testscript-summary.md`


## T005 -- Merging stdout into stderr

**Query:** In a testscript command line, how do you redirect stdout into stderr?

**Key facts** (all must appear in a correct answer):
- Use the `>&2` redirect operator.
- Example: `$* >&2`

**Source:** `guides/testscript-summary.md`


## T006 -- test.target variable

**Query:** What does the `test.target` variable control in a testscript build
configuration?

**Key facts** (all must appear in a correct answer):
- It specifies the cross-testing platform target.
- It defaults to `build.host` (the machine running the build).

**Source:** `guides/testscript-summary.md`
