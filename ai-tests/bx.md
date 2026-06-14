# Tests: bx -- shell script and task runner

Source documentation: `bx/README.md`, `bx/bx.md`


## T001 -- Invocation modes

**Query:** How does `bx` decide whether the first argument is a script path or a task name, and what happens with no argument?

**Key facts** (all must appear in a correct answer):
- An argument is treated as a script path if it contains a directory separator or has the `.bx` extension.
- Otherwise the argument is treated as a task name.
- When no argument is given, `bx` runs the default task.

**Source:** `bx/README.md`, `bx/bx.md`


## T002 -- Verbosity levels

**Query:** What diagnostic output does each verbosity level 0, 1, and 2 produce, and which level is the default?

**Key facts** (all must appear in a correct answer):
- Level 0 produces no non-error messages.
- Level 1 shows high-level information messages and is the default.
- Level 2 shows the essential underlying commands being executed.

**Source:** `bx/bx.md`


## T003 -- Shebang line

**Query:** What is the recommended portable shebang for a `.bx` script and why is it preferred over an absolute path?

**Key facts** (all must appear in a correct answer):
- The recommended shebang is `#! /usr/bin/env bx`.
- Using `env` makes it portable because it locates `bx` via `PATH` rather than requiring a fixed installation path.

**Source:** `bx/README.md`, `bx/bx.md`


## T004 -- Default task argument passing

**Query:** How do you pass arguments to the default task when invoking `bx`?

**Key facts** (all must appear in a correct answer):
- Use `--` to separate `bx` options from the arguments: `bx -- <arg>...`.
- Without `--`, a bare argument would be interpreted as a task name rather than an argument to the default task.

**Source:** `bx/README.md`, `bx/bx.md`


## T005 -- Pager suppression

**Query:** How do you suppress the pager in `bx`?

**Key facts** (all must appear in a correct answer):
- Pass `--pager` with an empty string value: `--pager ''`.
- An empty string argument to `--pager` disables paging entirely.

**Source:** `bx/bx.md`
