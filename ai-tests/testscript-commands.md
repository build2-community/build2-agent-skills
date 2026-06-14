# Tests: testscript (commands) -- redirections, here-documents, cleanup, builtins

Source documentation: `guides/testscript-commands.md`


## T001 -- Here-document input

**Query:** What is the syntax for supplying stdin to a testscript command via a
here-document, and what delimiter conventions apply?

**Key facts** (all must appear in a correct answer):
- Use `<< END` (or `<<= END`) on the command line to introduce an input
  here-document with end marker `END`.
- The body lines follow the command line, terminated by a line containing only
  the end marker (e.g. `EOI`).
- An unquoted or single-quoted end marker means the body is taken literally
  (no variable expansions). A double-quoted end marker enables variable
  expansions and escape sequences inside the body.
- Indentation stripping: the leading whitespace of the end-marker line is used
  as a strip prefix and is removed from every non-blank body line.
- Example: `$* - <<EOI` followed by body lines and `EOI` on its own line.

**Source:** `guides/testscript-commands.md`


## T002 -- Expected output comparison

**Query:** What is the syntax for comparing stdout to exact expected content in
a testscript command, and how do you use regex-based comparison instead?

**Key facts** (all must appear in a correct answer):
- Exact here-document comparison: `>> END` (or `>>? END`) redirects stdout and
  compares it line-for-line against the here-document body.
- Exact here-string comparison: `> text` (or `>>>? text`) compares stdout to a
  literal string.
- Regex comparison: append `~` to the output redirect operator, e.g. `>>~ END`
  or `>>~/END/`. The `~` modifier indicates the expected content is a regex.
- In regex mode the end-marker's first character is the introducer. Lines
  starting with the introducer are ECMAScript (C++11) regexes matched against
  the corresponding output line; all other lines are matched literally.
- Example: `$* 2>>~/EOE/ != 0` with `/usage: .+ <name>/` as a char-regex line.

**Source:** `guides/testscript-commands.md`


## T003 -- Cleanup directives

**Query:** What are the three explicit cleanup directive forms in testscript, and
what does each one instruct the runner to do?

**Key facts** (all must appear in a correct answer):
- `&path` -- always clean up the path after the test. It is an error if the
  path does not exist at cleanup time.
- `&?path` -- optionally clean up the path. No error if the path does not
  exist.
- `&!path` -- cancel a previously registered cleanup for the path (suppress
  cleanup).
- Files and directories created inside the test scope's working directory by
  redirects or certain builtins are registered for cleanup automatically.
- Registering a path outside the script working directory is an error; use
  `rm -f` or `rmdir -f` for such paths instead.

**Source:** `guides/testscript-commands.md`


## T004 -- Testscript builtins

**Query:** What makes testscript builtins different from external system
commands? Name at least four builtins that are available.

**Key facts** (all must appear in a correct answer):
- Builtins are implemented inside the testscript runner itself, not as external
  system utilities. They are therefore portable across platforms without
  requiring those tools to be present on the host.
- To run a system utility with the same name instead of the builtin, prefix the
  name with `^` (e.g. `^find`).
- Available builtins include: `cat`, `cp`, `echo`, `find`, `mkdir`, `mv`, `rm`,
  `rmdir`, `sed`, `sleep`, `test`, `touch`, `true`, `false`, `ln`, `diff`,
  `date`, `sha256sum`, `xxh64sum`.
- Pseudo-builtins (`set`, `for`, `exit`, `export`, `env`, `timeout`) are also
  processed by the runner but have additional restrictions (e.g. `set` and
  `for` must be last in a pipeline).

**Source:** `guides/testscript-commands.md`


## T005 -- Here-document end-of-file markers

**Query:** What is the difference between the EOI and EOO/EOE end-of-file
markers used in testscript here-documents?

**Key facts** (all must appear in a correct answer):
- `EOI` (End Of Input) is the conventional end marker for an input
  here-document, i.e. one that supplies stdin to a command via `<< EOI`.
- `EOO` (End Of Output) is the conventional end marker for an output
  here-document that compares stdout, i.e. via `>> EOO`.
- `EOE` (End Of Error) is the conventional end marker for an output
  here-document that compares stderr, i.e. via `2>> EOE`.
- The marker names are user-chosen identifiers; `EOI`, `EOO`, and `EOE` are
  conventions, not keywords. Any unique identifier may be used.
- When a command has both input and output here-documents, the bodies appear in
  the order their redirects were written on the command line.

**Source:** `guides/testscript-commands.md`


## T006 -- Exit code checking

**Query:** What is the syntax for asserting a specific non-zero exit code from a
testscript command, and how do you assert any non-zero exit code?

**Key facts** (all must appear in a correct answer):
- Assert any non-zero exit code: append `!= 0` after the command and its
  redirects. Example: `$* != 0`.
- Assert a specific non-zero exit code: append `== N` or `!= N` where `N` is
  the expected code. Example: `$* == 1` asserts the command exits with code 1.
- Without an explicit exit-code check the runner expects the command to succeed
  (exit code 0) and fails the test if it does not.
- The exit code check is written after all redirects and cleanup directives on
  the command line.

**Source:** `guides/testscript-commands.md`
