# bx -- Shell Script and Task Runner

_Use for: running .bx scripts and named tasks; portable automation that
replaces shell scripts in a build2 project._

## Overview

`bx` is the build2 shell script and task runner. It executes portable `.bx`
scripts or named tasks defined in a project, with optional arguments.

The mode is determined by the first non-option argument: if it contains a
directory separator or ends in `.bx` it is a script path, otherwise it is a
task name. Passing no argument (with an optional `--` separator) runs the
default task.

Note: task running is not yet implemented. Only script execution is currently
supported.

## Common Usage Patterns

**Run a script directly:**
```
$ bx ./configure.bx
```

**Run a named task:**
```
$ bx format
```

**Pass arguments to the default task:**
```
$ bx -- --release
```

**Portable script shebang:**
```
#! /usr/bin/env bx
```

## Navigation

- [bx full reference](bx.md) -- all options, exit status, environment
