# build2 Testscript -- Commands, Redirections, and Builtins

Variables, redirections, regex matching, cleanup, builtins, and common
patterns for Testscript.

See [testscript-summary.md](testscript-summary.md) for the integration model,
execution model, lexical structure, and test/group scope syntax.

## Variables

Variable assignment (same semantics as buildfiles, no `{}`-name-generation):

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
| `cp` | `cp [-p] [--no-cleanup] [-r|-R] <src> <dst>` | Copy files or directories. `-p` preserves times and permissions. `-r`/`-R` recursive. |
| `date` | `date [-u] [+<format>]` | Print current date/time using `std::put_time()` format (extended with `%[.N]` for nanoseconds). `-u` prints UTC. |
| `diff` | `diff [-u|-U <n>] <f1> <f2>` | Compare files. Not a true builtin; uses platform diff (GNU diff on Windows). |
| `echo` | `echo <string>...` | Write space-separated strings followed by a newline to stdout. |
| `env` | `env [-t <sec>] [-c <dir>] [-u <name>]... [-] [<name>=<value>]... -- <cmd>` | Run a command with modified environment, working directory, and/or timeout. Pseudo-builtin; `env` and `--` must be literal. |
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

## See Also

- [testscript-summary.md](testscript-summary.md) -- integration, execution model, lexical structure, scope syntax
- [build2 core modules: test](build2-modules-core.md)
- [build2 projects advanced: testing](build2-projects-advanced.md)
