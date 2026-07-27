# build2 Testscript Reference

## Overview

Testscript is a domain-specific language embedded in the build2 build system
for running tests. It resembles Bash but is optimized for concise test
description and fast parallel execution. It is a _test runner_, not a
per-language testing framework: it drives external programs via stdin/stdout/
stderr and is therefore primarily geared toward functional testing.

Core capabilities:

- Supplying input via command line and stdin.
- Comparing to expected exit status.
- Comparing stdout/stderr to expected output, including regex matching.
- Setup/teardown commands and automatic file/directory cleanups.
- Simple (single-command) and compound (multi-command) tests.
- Test groups with common setup/teardown.
- Test isolation for parallel execution.
- Portable POSIX-like builtin commands.
- Formalized test documentation (id, summary, details).

The term _Testscript_ (capitalized) refers to the language. _testscript_ means
code written in this language. `testscript` refers to the file name.

---

## Integration with Build System

A testscript file is associated with a test target by listing it as a
prerequisite in the buildfile:

```
exe{hello}: cxx{hello} testscript
```

By convention a single testscript file is named `testscript`; multiple files
use the `.testscript` extension (e.g. `basics.testscript`). The `test` module
registers the `testscript{}` target type.

The same testscript may test multiple targets, or a directory target:

```
./: testscript
exe{hello}:      testscript{basics advanced}
exe{hello-lite}: testscript{basics}
```

### Special variables in the buildfile

| Variable | Meaning |
|---|---|
| `test` | Path to the target being tested (set automatically, or override to a target name) |
| `test.options` | Extra options prepended to the command |
| `test.arguments` | Extra arguments appended after options |
| `test.redirects` | Extra redirects (of `cmdline` type) |
| `test.cleanups` | Extra cleanups (of `cmdline` type) |
| `test.target` | Cross-testing platform target (defaults to `build.host`) |

### Simple-test prerequisite variables

Without a Testscript, a target can still be a **simple test** (`test = true`
or any of the variables below). Prerequisite-specific flags mark files used
as I/O for that single run:

| Variable | Meaning |
|---|---|
| `test.stdin` | Prerequisite file is redirected to the test's stdin |
| `test.stdout` | Prerequisite file is compared to the test's stdout |
| `test.roundtrip` | Shortcut for both stdin and stdout |
| `test.input` | Prerequisite is updated and its path is appended as an extra argv element (after `test.options` / `test.arguments`) |

Example:

```
exe{hello}: file{names.txt}: test.stdin = true
exe{hello}: file{greetings.txt}: test.stdout = true
```

`test.input` is currently available to **simple tests only**, not Testscript
runs. Do not use it for Testscript runtime fixtures (child helpers discovered
by path). Attach those as prerequisites of the testscript instead. See
[test-runtime-fixtures.md](../HOWTO/test-runtime-fixtures.md).

### Runtime fixtures on the testscript

Prerequisites of a `testscript{}` target are updated when the test is
prepared. Pin a pure-src testscript with `@./` when it is the **left-hand**
side of a dependency (LHS defaults to out):

```
testscript{common}@./: ../resources/exe{helper}
```

### Running tests

```
b test                                    # run all tests
b test config.test=basics                 # all tests in basics.testscript
b test config.test=basics/fox             # all tests in group fox
b test config.test=basics/foo             # only test foo
b test config.test="basics/foo basics/fox/bar"
b test config.test.runner="valgrind -q"   # run through a runner program
b test config.test.output=keep            # preserve working dirs after run
```

`config.test.output` takes a `<before>@<after>` pair. Before values: `fail`,
`warn`, `clean`. After values: `clean`, `keep`. Default is `warn@clean`.

---

## Execution Model

A testscript file is an implicit top-level group scope. Each scope (group or
test) gets a nested temporary working directory. For a directory target (`./`)
the path is `$out_base/test/`; for a named target like `exe{hello}` it is
`$out_base/test-hello/`. The directory is removed after a successful run and
left behind on failure.

**Scope types:**

| Syntax | Type |
|---|---|
| `{{ ... }}` | Group scope |
| `{ ... }` | Test scope (explicit) |
| single or semicolon-joined commands | Test scope (implicit) |

**Scope id and id path.** Each scope has an id. If not given explicitly it is
derived from the line number in the testscript. The id path (e.g.
`basics/group/test2`) is the concatenation of all ancestor ids separated by
`/`. It is also the relative filesystem path of the scope's working directory.
The id path is available via read-only `$@`. The working directory is available
via read-only `$~`.

**Execution order:**

1. Setup commands (`+cmd`) run sequentially.
2. Inner test/group scopes run in parallel.
3. Teardown commands (`-cmd`) run sequentially after all inner scopes succeed.

Filesystem names starting with `stdin`, `stdout`, or `stderr` inside a scope
working directory are reserved.

---

## Lexical Structure

Testscript is a line-oriented, UTF-8 language. Leading whitespace and blank
lines are ignored (except inside here-document fragments).

**Line continuation:** a backslash followed by a newline (outside
single-quoted strings and single-quoted here-docs) removes both characters and
joins the next line.

**Comments:** unquoted `#` starts a line comment. A lone `#\` line starts a
multi-line comment that ends at the next `#\` line.

**Quoting:**

- Single-quoted (`'...'`): no expansions, no escapes; all characters are
  literal.
- Double-quoted (`"..."`): variable expansions, function calls, evaluation
  contexts, and escape sequences are active. Only `"`, `\`, `$`, `(` need
  escaping inside.

**Escape:** a backslash escapes the next character to its literal value.
Use `\\` for a literal backslash.

**Line types** (determined by the leading unquoted character):

| Leading character | Line type |
|---|---|
| `:` | Description line |
| `.` | Directive line |
| `{{` | Group scope start |
| `}}` | Group scope end |
| `{` | Test scope / block start |
| `}` | Test scope / block end |
| `+` | Setup command line |
| `-` | Teardown command line |
| (other) | Variable assignment or command, determined by first two tokens |

**`cmdline` type.** Variables of type `cmdline` (e.g. `$*`, `test.redirects`)
are re-lexed after expansion so that redirect and pipe syntax tokens inside
them are recognized. Use the doubled single-quoting idiom to pass literal
strings through re-lexing:

```
filter = [cmdline] sed -e \''s/foo (bar|baz)/$&/'\'
```

---

## Test Script Structure

### Description

Description lines start with `:` and precede (or, for one-liners, follow) a
test or group. All three components are optional:

```
: <id>
: <summary>
:
: <details>
```

The id contains only alphanumeric characters, underscores, pluses, and minuses.
If omitted, the id is auto-derived from the line number. Trailing description
(id or summary only) is written after the command separated by `:`:

```
$* 'World' >'Hello, World!' : command-name
```

### Group scope

```
: config
{{
  conf = $~/hello.conf

  +cat <<EOI >=$conf
  John = Howdy
  EOI

  $* -c $conf 'John' >'Howdy, John!' : custom-greet
  $* -c $conf 'Jack' >'Hello, Jack!' : default-greet
}}
```

### Test scope (explicit)

```
: config-greet
{
  conf = hello.conf
  cat <'Jane = Good day' >=$conf
  $* -c $conf 'Jane' >'Good day, Jane!'
}
```

### Compound test (implicit scope)

Semicolons after each line except the last signal test continuation:

```
conf = test.conf;
cat <'verbose = true' >=$conf;
$* $conf
```

### Setup and teardown

- `+cmd` -- setup: runs before inner tests.
- `-cmd` -- teardown: runs after all inner tests succeed.
- Standalone variable assignments are automatically setup (before any test) or
  teardown (after the first test).

### Conditional branching

```
if ($cxx.target.class != windows)
{{
  $* -c /dev/null 'Jane' >'Hello, Jane!' : jane
}}
else
{{
  $* -c nul 'Jane' >'Hello, Jane!' : jane
}}
```

Shortcuts for null/empty checks: `ifn`, `ife`, `ifn!`, `ife!`, `elifn`,
`elife`, `elifn!`, `elife!`.

### Loops

**For loop (value form):**

```
for v: $values
  test1 $v;
test2
```

**For loop (stream form):**

```
cat values.txt | for -n v
  test1 $v;
test2
```

**While loop:**

```
while test -f $file
  test1 $file;
test2
```

Use `continue` and `break` to control loop iteration.

### Include directive

```
.include common.testscript
.include --once helpers.testscript
```

Evaluated at parse time. Relative paths are relative to the including file.

---

## Commands

A command has the form:

```
<path> [<arg>|<redirect>|<cleanup>]... [== <exit>|!= <exit>]
```

Commands can be chained:

- `cmd1 | cmd2` -- pipe (stdout of left to stdin of right).
- `cmd1 && cmd2` -- logical AND (run cmd2 only if cmd1 succeeds).
- `cmd1 || cmd2` -- logical OR (run cmd2 only if cmd1 fails).

Operators are left-associative with equal precedence and are short-circuiting
(except for expansions which are always evaluated).

**Exit status check:**

- Omitted: expect exit code 0.
- `== 0` or `!= 0`: explicit check.

If a command terminates abnormally the entire test/setup/teardown fails
immediately.

**Redirecting stderr to stdout (or vice versa):**

```
$* >&2    # merge stdout into stderr
$* 2>&1   # merge stderr into stdout
```

**Running a system utility instead of a builtin:**

```
^cat --squeeze-blank <file>
```

---

## Style Guide

### Testing philosophy

The primary goal of testing in build2 is not to exhaustively test every
possible situation. The aim is to keep tests comprehensible and maintainable
in the long run.

Don't try to test every possible combination. This striving quickly leads to
hundreds of tests that are only slight variations of each other. Sometimes
combination tests are useful, but generally keep things simple and test one
thing at a time. Real-world usage uncovers far more interesting interactions
(which must become regression tests) than you would think of in advance.

Don't confuse combination tests with corner case tests. For each test you
should have a clear understanding of what logic in the code you are testing.
If you don't have evidence of why two features might not work together, don't
add a test for it just for good measure.

A practical approach: look at the diff of changes you want to commit and
ensure you have at least one test exercising each happy (non-error) logic
branch. For important code, do the same for unhappy logic branches.

Keep testing in mind during implementation. When tempted to add a small
special case to make the result nicer, remember you will also have to test it.

Prefer functional tests over unit tests when the functionality is well exposed
through the program's interface. If unit-testing a complex piece of
functionality, consider designing a concise textual mini-format for input and
output rather than constructing test data programmatically.

### Documentation conventions

Each test should at minimum include an explicit id that adequately summarizes
what it tests. Add a summary or details for more complex tests. Failure tests
usually warrant this.

Use the leading description for multi-line tests:

```
: multi-name
:
$* 'John' 'Jane' >>EOO
Hello, John!
Hello, Jane!
EOO
```

A description with all three components (id, summary, details):

```
: multi-name
: Test multiple name arguments
:
: This test makes sure we properly handle multiple names passed as
: separate command line arguments.
:
$* 'John' 'Jane' >>EOO
Hello, John!
Hello, Jane!
EOO
```

### Formatting guidelines

Separate multi-line tests with blank lines. Place larger tests into explicit
test scopes for better visual separation, especially when the test body
contains blank lines (for example, in here-document fragments). The
description goes before the scope. Here-documents are indented inside the
scope:

```
: multi-name
:
{
  $* 'John' 'Jane' >>EOO
  Hello, John!

  Hello, Jane!

  EOO
}
```

One-line tests may use the trailing description, which must be the test id.
Within a block of one-liners (no blank line between them), align the ids:

```
$* John >'Hi, John!'       : custom-john
$* World >'Hello, World!'  : custom-world
```

You may use multiple spaces between the end of the command line and the
trailing description. Don't try to align ids across blocks -- this is a
maintenance burden.

### Grouping

If multiple tests belong together and their ids share a common prefix,
consider placing them in an explicit group scope. Use the shared prefix as
the group id and omit it from the individual test ids. Give the group a
summary:

```
: custom
: Test custom greetings
:
{{
  $* John >'Hi, John!'       : john
  $* World >'Hello, World!'  : world
}}
```

Don't repeat the testscript filename in group or test ids. If the tests live
in `greeting.testscript`, using `custom-greeting` as the group id is
unnecessarily repetitive because the id path would become
`greeting/custom-greeting/john`.

### Quoting

Quote values that are strings as opposed to options, file names, paths
(unless they contain spaces), integers, or booleans. Use single quotes unless
you need expansions or single quotes inside. Unlike Bash, you do not need to
quote variable expansions to preserve whitespace:

```
arg = 'Hello   Spaces'
echo $arg              # Hello   Spaces
```

## See Also

- [testscript-commands.md](testscript-commands.md) -- variables, redirections, regex, cleanup, builtins, patterns
- [build2 core modules: test](build2-modules-core.md)
- [build2 projects advanced](build2-projects-advanced.md)
