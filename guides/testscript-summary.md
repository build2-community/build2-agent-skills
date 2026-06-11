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

## See Also

- [testscript-commands.md](testscript-commands.md) -- variables, redirections, regex, cleanup, builtins, patterns
- [build2 core modules: test](build2-modules-core.md)
- [build2 projects advanced](build2-projects-advanced.md)
