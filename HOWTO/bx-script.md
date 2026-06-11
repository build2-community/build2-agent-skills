# Running Scripts and Tasks with bx

`bx` runs portable `.bx` shell scripts or named tasks defined in a build2
project. Use it instead of a plain shell script when you need portability
across platforms or integration with a build2 project layout.

Note: named task support is not yet implemented. Only direct script execution
is currently available.

## Running a script by path

```
$ bx ./tools/generate.bx
$ bx scripts/check.bx --verbose
```

Any path argument (containing `/` or ending in `.bx`) is treated as a script
path. Remaining arguments are passed to the script.

## Portable shebang line

Scripts intended to be called directly (rather than through `bx`) should use
this shebang so they locate `bx` via `PATH`:

```
#! /usr/bin/env bx
```

## Passing arguments to a script

Arguments after the script path are forwarded verbatim:

```
$ bx ./configure.bx --prefix /usr/local --enable-tests
```

## Running the default task

Once task support is available, the default task will be run with no
arguments:

```
$ bx
$ bx -- --release    # pass arguments to the default task
```

A named task:

```
$ bx format
$ bx lint --fix
```

## See also

- [bx README](../bx/README.md) -- overview and usage patterns
- [bx full reference](../bx/bx.md) -- all options, exit status, environment
