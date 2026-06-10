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
test) gets a nested temporary working directory under `$out_base/test-<name>/`.
The directory is removed after a successful run and left behind on failure.

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

## Variables

Variable assignment (same semantics as Buildfile, no `{}`-name-generation):

```
foo = value
foo += appended
foo =+ prepended
args = [strings] foo bar 'fox   baz'
```

Variable lookup walks outward through testscript scopes then into the buildfile
starting with the test target's target-specific variables, then the script
target's variables, then normal scope lookup.

**Read-only special variables:**

| Variable | Meaning |
|---|---|
| `$*` | Full test command: `$test $test.options $test.arguments $test.redirects $test.cleanups` |
| `$0` | Path to the test target (`$test`) |
| `$N` | (N-1)-th element in `{$test.options $test.arguments}` |
| `$~` | Current scope working directory (read-only) |
| `$@` | Current scope id path (read-only) |

`$*` and `$0` are read-only aliases. To modify the command, assign to
`test.options`, `test.arguments`, etc. directly.

---

## Redirections

File descriptors: `0` = stdin, `1` = stdout, `2` = stderr. The fd prefix must
immediately precede the operator with no whitespace.

### Input redirects

| Syntax | Meaning |
|---|---|
| `<-` | Null input (/dev/null equivalent) |
| `<|` | Pass through to real stdin |
| `< text` or `<<<= text` | Here-string |
| `<< END` or `<<= END` | Here-document |
| `<<< file` or `<= file` | Read from file |

**Here-string modifiers** (append after `<`):

- `:` -- suppress the automatically-added terminating newline.
- `/` -- translate `/` to the target platform directory separator.
- `~` -- the string is a regex (must start with an introducer character).

### Output redirects

| Syntax | Meaning |
|---|---|
| `>-` | Discard output (/dev/null equivalent) |
| `>|` | Pass through to real stdout/stderr |
| `>!` | Discard at verbosity < 2, pass through otherwise |
| `>= file` | Write to file (overwrite) |
| `>+ file` | Append to file |
| `>& 1` or `>& 2` | Merge to the other stream |
| `>>> file` or `>? file` | Compare output to file contents |
| `>> END` or `>>? END` | Compare output to here-document |
| `> text` or `>>>? text` | Compare output to here-string |

**Output modifiers** (append to the operator before `~`):

- `:` -- suppress the automatically-added terminating newline.
- `/` -- translate `/` to the target platform directory separator.
- `~` -- the expected content is a regex.

### Here-documents

Fragments follow the command line in the order their redirects appear:

```
$* <<EOI >>EOO
input line
EOI
expected output
EOO
```

Quoting the end marker on the command line controls expansion inside the body:

- Unquoted or single-quoted end marker: body taken literally (no expansions).
- Double-quoted end marker: variable expansions and escapes are active in body.

Indentation stripping: the leading whitespace of the end marker line becomes
the strip prefix and is removed from every non-blank body line.

Shared here-document (for round-trip testing):

```
$* <<EOD >>EOD
<hello>Hello, World!</hello>
EOD
```

---

## Output Regex

Append `~` to an output redirect to indicate regex matching. Regex uses
ECMAScript (C++11) flavor.

```
$* 2>>~/EOE/ != 0
error: missing name
/usage: .+ <name>/
EOE
```

Matching is two-level:

- **Line-regex**: each line is a "character" in an outer regex.
- **char-regex**: a line starting with the introducer character is an inner
  ECMAScript regex matched against the corresponding output line.
- Literal lines (no introducer) match only identical lines.

The introducer character for a here-string is its first character. For a
here-document it is specified as the first character of the end marker:
`>>~/EOE/` uses `/` as introducer.

**Global match flags** are placed after the closing introducer of the end
marker: `>>~%EOO%i` applies `i` to all char-regexes in the document.

**Per-line match flags** follow the closing introducer of a char-regex line:
`/ba+r/i`.

Supported flags:

| Flag | Meaning |
|---|---|
| `i` | Case-insensitive match |
| `d` | Invert dot escaping (unescaped `.` is literal, `\.` matches any character) |

Syntax line-chars (outer-level regex operators) are written as lines starting
with the introducer but not ending with one:

```
$* >>~/EOO/
/(
/fo+x/|
/ba+r/
/)+
EOO
```

---

## Cleanup

Files and directories created inside the test scope's working directory are
automatically registered for cleanup when created by redirects or certain
builtins. Additional cleanups can be registered explicitly:

```
$* &output.log != 0          # always cleanup: fail if file does not exist
$* &?maybe-created-file
$* &!no-cleanup-for-this     # cancel a previously registered cleanup
$* &dir/***                  # remove dir/ and all its contents recursively
```

Wildcard components in cleanup paths:

| Pattern | Matches |
|---|---|
| `?` | Any single character |
| `*` | All immediate files |
| `*/` | All immediate sub-directories (must be empty) |
| `**` | All files recursively |
| `**/` | All sub-directories recursively (must be empty) |
| `***/` | All sub-directories recursively (must be empty) plus start dir |
| `***` (no trailing slash) | All files and sub-dirs recursively plus start dir |

Registering a path outside the script working directory is an error. Use
`rm -f` or `rmdir -f` to clean up such paths manually.

---

## Builtins

To run a system utility instead of a builtin, prefix the name with `^`.

| Builtin | Synopsis | Description |
|---|---|---|
| `cat` | `cat [<file>...]` | Print files (or stdin) to stdout. `-` means stdin. |
| `cp` | `cp [-p] [--no-cleanup] [-R] <src> <dst>` | Copy files or directories. `-p` preserves times and permissions. `-R` recursive. |
| `date` | `date [-u] [+<format>]` | Print current date/time using `std::put_time()` format (extended with `%[.N]` for nanoseconds). `-u` prints UTC. |
| `diff` | `diff [-u|-U <n>] <f1> <f2>` | Compare files. Not a true builtin; uses platform diff (GNU diff on Windows). |
| `echo` | `echo <string>...` | Write space-separated strings followed by a newline to stdout. |
| `env` | `env [-t <sec>] [-s] [-c <dir>] [-u <name>]... [-] [<name>=<val>]... -- <cmd>` | Run a command with modified environment, working directory, and/or timeout. Pseudo-builtin; `env` and `--` must be literal. |
| `exit` | `exit [<code>] [<diag>]` | Exit the current scope. Code 0 exits successfully; non-zero exits with error. Pseudo-builtin. |
| `export` | `export [-c <name>]... [-u <name>]... [<name>=<val>]...` | Add/remove variables from the execution environment for the current scope. Pseudo-builtin. |
| `false` | `false` | Exit with code 1. |
| `find` | `find <start>... [<expr>]` | Search filesystem. Supports `-name`, `-type` (f/d/l), `-mindepth`, `-maxdepth`. Primaries are ANDed implicitly. |
| `ln` | `ln [--no-cleanup] [-s] <target> <link>` | Create hard (default) or symbolic (`-s`) links. Falls back to copy if links unsupported. |
| `mkdir` | `mkdir [--no-cleanup] [-p] <dir>...` | Create directories. `-p` creates parents and ignores existing dirs. |
| `mv` | `mv [--no-cleanup] [-f] <src> <dst>` | Move/rename files or directories. `-f` allows sources outside working dir. |
| `rm` | `rm [-r] [-f] <path>...` | Remove files or directories. `-r` for directories, `-f` to suppress errors. |
| `rmdir` | `rmdir [-f] <dir>...` | Remove empty directories. `-f` suppresses errors. |
| `sed` | `sed [-n] [-i] (-e <script>)... [<file>]` | Stream editor. Supports `s/regex/replacement/flags` only. ECMAScript regex flavor. Flags: `g`, `p`, `i`. Replacement extras: `\N`, `\u`, `\l`, `\U`, `\L`, `\n`. |
| `set` | `set [-e] [-n|-w] <var> [<attr>]` | Set a variable from stdin. `-n` split at newlines, `-w` split at whitespace. Pseudo-builtin; must be last in pipe. |
| `sha256sum` | `sha256sum [-b|-t] [--sum-only] <file>...` | Compute SHA256 checksums. `--sum-only` prints only the hash. |
| `sleep` | `sleep <seconds>` | Pause execution for at least the specified number of seconds. |
| `test` | `test -f|-d <path>` | Test whether path is a regular file (`-f`) or directory (`-d`). |
| `timeout` | `timeout [-s] [<group>/][<test>]` | Set test and/or group timeouts in seconds. Pseudo-builtin. `-s` treats timeout as success. |
| `touch` | `touch [--no-cleanup] [--after <ref>] <file>...` | Update timestamps or create files. `--after` keeps touching until mtime is after ref. |
| `true` | `true` | Exit with code 0. |
| `xxh64sum` | `xxh64sum [-b|-t] [--sum-only] <file>...` | Compute XXH64 checksums (fast, non-cryptographic). Same interface as `sha256sum`. |

---

## Common Patterns

**Test a failure case and expected stderr:**

```
: missing-name
$* 2>>"EOE" != 0
error: missing name
usage: $0 <name>
EOE
```

**Test stdout with a here-string:**

```
$* 'World' >'Hello, World!' : command-name
```

**Test stdout with a here-document:**

```
$* - <<EOI >>EOO : stdin-names
Jane
John
EOI
Hello, Jane!
Hello, John!
EOO
```

**Group with shared setup file:**

```
: config
{{
  conf = $~/hello.conf

  +cat <<EOI >=$conf
  John = Howdy
  Jane = Good day
  EOI

  $* -c $conf 'John' >'Howdy, John!'  : custom-greet
  $* -c $conf 'Jack' >'Hello, Jack!'  : default-greet
}}
```

**Compound test with a generated file:**

```
cat <<EOI >=hello.conf;
John = Howdy
EOI
$* -c hello.conf 'John' >'Howdy, John!' : config-greet
```

**Platform-conditional variable:**

```
conf = ($windows ? nul : /dev/null);
$* -c $conf 'Jane' >'Hello, Jane!'
```

---

## See Also

- [build2 manual summary](build2-manual-summary.md)
