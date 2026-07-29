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
`>>~/EOE/` uses `/` as introducer. There is no way to escape the introducer
character inside the regex -- if a golden line's content needs to contain it
(e.g. a literal `/` in an expected path), change the introducer for the whole
here-document instead, e.g. `>>~%EOE%` instead of `>>~/EOE/`, and convert
every regex line inside it to use the new introducer.

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

Each scope (test or group) gets its own temporary working directory named after
the scope id, accessible via `$~`. At the end of the scope all registered
cleanups are executed in reverse order of registration: the named file or
directory is deleted. After all cleanups the working directory itself is removed
-- but only if it is empty. If it is not empty the test is considered failed due
to unexpected output. In other words, any file left in `$~` that was not
explicitly cleaned up causes a test failure.

Output redirect files (written with `>=` or `>+`) are registered automatically.
Filesystem builtins (`cp`, `ln`, `mkdir`, `touch`) register newly created
entries that fall inside the working directory automatically as well.

To keep the working directory for post-mortem inspection, run:

```
b test config.test.output=keep
```

This skips all cleanups and teardowns and leaves `$~` intact. Note that with
`keep`, some failures due to unexpected output may go undetected.

Additional cleanups can be registered explicitly:

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

### `--no-cleanup` on filesystem builtins

The builtins `cp`, `ln`, `mkdir`, and `touch` automatically register newly
created entries that are inside the script working directory for cleanup. Pass
`--no-cleanup` to suppress that automatic registration for the current
invocation.

The `mv` builtin does not create entries; instead it adjusts the cleanup paths
already registered for the source entities to reflect their new names and
locations. If the destination is outside the working directory or an entry
already exists at the destination, the source's cleanup is canceled. Passing
`--no-cleanup` suppresses these adjustments entirely.

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
| `set` | `set [-e] [-n|-w] <var> [<attr>]` | Set a variable from stdin. `-e` exact match (no trailing newline stripping), `-n` split at newlines, `-w` split at whitespace. Pseudo-builtin. Must be last in pipe. |
| `for` | `for [-e] [-n\|-w] <var> [<attr>]` | Iterate over stdin values, executing the body for each. `-e` exact match, `-n` split at newlines, `-w` split at whitespace (default). Pseudo-builtin. Must be last in pipe. |
| `sha256sum` | `sha256sum [-b|-t] [--sum-only] <file>...` | Compute SHA256 checksums. `--sum-only` prints only the hash. |
| `sleep` | `sleep <seconds>` | Pause execution for at least the specified number of seconds. |
| `test` | `test -f|-d <path>` | Test whether path is a regular file (`-f`) or directory (`-d`). |
| `timeout` | `timeout [-s] [<group>/][<test>]` | Set test and/or group timeouts in seconds. Pseudo-builtin. `-s` treats timeout as success. |
| `touch` | `touch [--no-cleanup] [--after <ref>] <file>...` | Update timestamps or create files. `--after` keeps touching until mtime is after ref. |
| `true` | `true` | Exit with code 0. |
| `xxh64sum` | `xxh64sum [-b|-t] [--sum-only] <file>...` | Compute XXH64 checksums (fast, non-cryptographic). Same interface as `sha256sum`. |

---

## Pseudo-builtin Details

### set

`set` reads stdin and assigns the result to a variable. It must be the last
command in a pipeline.

```
cat file.txt | set content
$* | set -n lines [strings]
```

| Option | Description |
|---|---|
| **-e**, **--exact** | Do not strip the trailing newline from the input. By default the final newline is removed before assignment. |
| **-n**, **--newline** | Split input at newlines and store as a list. |
| **-w**, **--whitespace** | Split input at whitespace runs and store as a list. |

`-n` and `-w` are mutually exclusive. When neither is given the full input
(after newline stripping unless **-e**) is stored as a single string.

### for

`for` reads stdin and executes its body once per value. It must be the last
command in a pipeline.

```
echo "a b c" | for -w item
{
  echo $item
}
```

| Option | Description |
|---|---|
| **-e**, **--exact** | Do not strip the trailing newline from the last value. |
| **-n**, **--newline** | Split input at newlines. |
| **-w**, **--whitespace** | Split input at whitespace runs (default). |

`-n` and `-w` are mutually exclusive.

### depdb

`depdb` is a pseudo-builtin available only inside ad-hoc build rules (in
build scripts, not in testscripts). It manages the dependency database for
dynamic dependency extraction. The primary sub-command is `depdb --dyndep`.

```
depdb --dyndep [<options>] [--file <path>]
```

`depdb --dyndep` reads dependency information from stdin (or from the file
given by **--file**) and registers the discovered prerequisites and/or
dynamic targets with the build system. The sub-command must appear before
any command that produces the dependency output.

Two dependency formats are supported via **--format**:

- `make` (default): standard make dependency syntax
  `<target>...: [<prerequisite>...]`. In non-byproduct mode a relative
  prerequisite path is treated as non-existent (to-be-generated).
- `lines`: one prerequisite (or target) per line. In non-byproduct mode a
  line with a leading space denotes a non-existent prerequisite. If
  **--dyn-target** is also given, the target list comes first, separated
  from the prerequisite list by a blank line.

**Prerequisite options:**

| Option | Type | Description |
|---|---|---|
| **--file** | `path` | Read dependency info from this file instead of stdin. |
| **--format** | `string` | Dependency format: `make` (default) or `lines`. |
| **--what** | `string` | Label for the prerequisite kind used in diagnostics, e.g., `header`. |
| **-I**, **--include-path** | `dir_path...` | Search paths for generated (not-yet-existing) prerequisites. |
| **--default-type** | `string` | Default prerequisite target type when the type cannot be derived from the file extension. |
| **--adhoc** | flag | Register dynamically discovered prerequisites as ad hoc so they are excluded from `$<` (normal mode only). |
| **--cwd** | `dir_path` | Working directory used to complete relative paths of prerequisites (byproduct mode, `lines` format, existing paths only). |
| **--drop-cycles** | flag | Silently drop prerequisites that are also targets. Use only when such cycles are known to be harmless. |

**Byproduct and dynamic-target options:**

| Option | Type | Description |
|---|---|---|
| **--byproduct** | flag | Must be the first option. Switches to byproduct mode where dependency info is recorded after the command runs rather than before. |
| **--dyn-target** | flag | Must be the first option (or follow **--byproduct**). Enable dynamic target extraction. Discovered targets are added as ad hoc group members. Not available in byproduct mode. |
| **--target-what** | `string` | Label for the target kind used in diagnostics, e.g., `source`. |
| **--target-default-type** | `string` | Default target type when the type cannot be derived from extension. |
| **--target-extension-type** | `string=string` | Extension-to-type mapping in `<ext>=<type>` form (e.g., `h=hxx`). Checked before automatic extension mapping. Resolves extension ambiguities. Repeatable. |
| **--target-cwd** | `dir_path` | Working directory used to complete relative paths of discovered targets. |

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
- [build2 buildfile language reference](build2-buildfile-language.md) -- ad-hoc rules and build scripts where `depdb` is used
