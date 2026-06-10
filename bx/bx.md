# bx -- Shell Script and Task Runner (Full Reference)

## Synopsis

```
bx [<options>] <path> [<arg>...]
bx [<options>] <task> [<arg>...]
bx [<options>] [-- <arg>...]
```

## Description

`bx` executes a `.bx` shell script (first form) or a named task (second and
third forms) with optional arguments.

The first argument after options determines the mode. It is considered a
script path if it contains a directory separator or has the `.bx` extension.
Otherwise it is treated as a task name. An absent first argument means the
default task -- use `--` if you wish to pass arguments to it. Neither the
script path nor the task name can start with `-`.

Note: task running is not yet implemented.

The recommended shebang for a portable `.bx` script:

```
#! /usr/bin/env bx
```

## Options

| Option | Arg | Default | Description |
|--------|-----|---------|-------------|
| `-v` | | | Print actual commands being executed. Equivalent to `--verbose 2`. |
| `-V` | | | Print all underlying commands being executed. Equivalent to `--verbose 3`. |
| `--quiet`, `-q` | | | Run quietly, only printing error messages. Equivalent to `--verbose 0`. |
| `--verbose` | `<level>` | `1` | Set diagnostics verbosity to `<level>` between 0 and 6. See below. |
| `--diag-color` | | | Use color in diagnostics. Color is used by default on non-dumb terminals. Use `--no-diag-color` to suppress. |
| `--no-diag-color` | | | Don't use color in diagnostics. |
| `--max-stack` | `<num>` | | Maximum per-thread stack size in KBytes. See below. |
| `--pager` | `<path>` | | Pager program for long output. Falls back to `less` if not specified. Empty string disables paging. |
| `--pager-option` | `<opt>` | | Additional option to pass to the pager program. Repeatable. |
| `--options-file` | `<file>` | | Read additional options from `<file>`. See below. Repeatable. |
| `--default-options` | `<dir>` | | Additional directory to load default options files from. |
| `--no-default-options` | | | Don't load default options files. |
| `--help` | | | Print usage information and exit. |
| `--version` | | | Print version and exit. |

### --verbose levels

| Level | Additional diagnostics produced |
|------:|--------------------------------|
| 0 | No non-error messages. |
| 1 | High-level information messages (default). |
| 2 | Essential underlying commands being executed. |
| 3 | All underlying commands being executed. |
| 4 | Information that could be helpful to the user. |
| 5 | Information that could be helpful to the developer. |
| 6 | Even more detailed information. |

### --max-stack

On pthreads-based systems `bx` queries the stack size of the main thread and
uses the same size for additional threads, which allows the usual mechanisms
(such as `ulimit`) to control it. However, if the main thread stack size
exceeds a predefined limit (64 MB on 64-bit systems, 32 MB on 32-bit systems)
it is capped to a more sensible value (8 MB). Passing `0` disables this cap
and uses the main thread stack size as-is.

### --options-file format

Each option should appear on a separate line, optionally followed by a space
or `=` and the option value. Empty lines and lines starting with `#` are
ignored. Values can be enclosed in double (`"`) or single (`'`) quotes to
preserve leading/trailing whitespace or to specify empty values. If the value
itself contains surrounding quotes, wrap it in an extra pair (e.g., `'"x"'`).
Non-leading and non-trailing quotes are treated as part of the value.

The semantics are equivalent to providing the same options in the same order
on the command line at the point where `--options-file` is specified, except
that shell escaping and quoting are not required.

## Exit Status

For a script execution the script's exit code is returned. For a task
execution non-zero exit status is returned on error.

## Environment

`HOME` -- used to determine the user's home directory. If not set,
`getpwuid(3)` is used instead. Used to shorten paths in diagnostics (replaced
with `~/`) and made available to scripts as `shell.home`.

`BUILD2_DEF_OPT` -- suppresses loading of default options files in nested
runner invocations. Set to `false` or `0` to suppress, `true` or `1` to load.

## Default Options Files

Instead of a separate config file format, `bx` uses default options files
containing the same options as the command line.

Files searched (in order, loaded from outermost to innermost):

1. System directory (e.g., `/etc/build2/`), if configured.
2. `.build2/` subdirectory of the home directory.
3. Directory specified with `--default-options` (loaded after home directory).

Within each directory `bx.options` is loaded first, followed by
`bx-script.options` (script mode only) or `bx-task.options` (task mode only).
Note that `bx-task.options` can also contain global variable overrides.

Command-line options always override default options file values.

If `--no-default-options` appears in a default options file, the search stops
at that directory and no outer files are loaded. If specified on the command
line, no default options files are loaded at all.

The order in which default options files are loaded is traced at verbosity
level 3 (`-V`).

## See Also

- [bx SUMMARY](SUMMARY.md)
- [INDEX](../INDEX.md)
