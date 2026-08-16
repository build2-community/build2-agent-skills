# b -- Build System Driver

_Use for: invoking builds, running tests, installing targets, writing and
debugging buildfiles, configuring out-of-source builds._

## Overview

`b` is the build system driver for the build2 toolchain. It reads `buildfile`
descriptions of targets and their dependencies, then executes the requested
operations to bring those targets up to date. `b` is the lowest-level tool in
the build2 stack and is invoked directly for day-to-day development tasks such
as compiling, testing, installing, and packaging.

The central concept is the **buildspec**: a compact expression on the command
line that names which meta-operations, operations, and targets should be
processed. Options that control driver behaviour and build system variables
that set configuration values can be freely intermixed with the buildspec.
Together these three kinds of arguments let a single `b` invocation fully
describe a build task without a separate configuration step.

build2 supports both in-source and out-of-source builds. The **src** tree
holds source files and buildfiles and is never written to during a build. The
**out** tree (sometimes called the build or output tree) receives all generated
artifacts, dependency tracking data, and the saved configuration. When
`src_root` and `out_root` are the same directory the build is in-source.
When they differ `b` maps targets between the two trees automatically, provided
the association has been recorded by a prior `configure` step or is stated
explicitly on the command line with the `src/@out/` syntax.

A source directory can additionally be configured as **forwarded** to an
out-of-source build. With a forwarded configuration in place, running `b` from
the source directory transparently builds in the output directory and
**backlinks** selected "interesting" targets (executables, documentation, etc.)
into the source tree for easy access. This lets developers work entirely in the
source tree while keeping it free of build artifacts.

`b` sits at the base of a three-layer toolchain. `bpkg` (the package manager)
invokes `b` to build and install packages. `bdep` (the build system package
dependency manager) drives `bpkg`, which in turn drives `b`. Users may invoke
any layer directly: calling `b` directly is normal for day-to-day development,
while `bpkg` and `bdep` are used when managing external package dependencies.


## Buildspec Syntax

The full buildspec grammar is:

```
[meta-op '(' [op '(' target... ')']... ')']...
```

All parts are optional with the following defaults:

- Meta-operation defaults to `perform`.
- Operation defaults to the meta-operation's default. For `perform` this is `update`.
- Target defaults to the current working directory (`./`).

A plain `b` is therefore equivalent to `b perform(update(./))`.

**Shortcut syntax** avoids shell quoting for the common case of a single
operation or meta-operation. The first argument must be the operation name
followed immediately by `:`, and the remaining arguments are treated as
targets and variables:

```
$ b clean: foo/ bar/                 # clean(foo/ bar/)
$ b configure: src/@out/             # configure(src/@out/)
$ b create: conf/, cxx               # create(conf/, cxx)
$ b configure: config.cxx=g++ src/   # configure(src/) config.cxx=g++
```

**Brace grouping** applies multiple operations to the same target set:

```
$ b clean update                     # perform(clean(./) update(./))
$ b '{clean update}(foo/ bar/)'      # clean then update foo/ bar/
$ b '{clean test clean}(...)'        # make sure tests pass
$ b '{clean disfigure}(...)'         # similar to distclean
```

**Full-form examples** showing the default substitution rules:

```
$ b                        # perform(update(./))
$ b foo/                   # perform(update(foo/))
$ b update                 # perform(update(./))
$ b clean                  # perform(clean(./))
$ b configure              # configure(?(./))
$ b configure update       # configure(?(./)) perform(update(./))
```

**Src/out mapping** on the command line uses `src/@out/` notation:

```
$ b foo/@foo-out/exe{foo}  # out_base=foo-out/ src_base=foo/
```

Once the association is saved by `configure`, subsequent invocations do not
need to repeat it:

```
$ b configure: foo/@foo-out/  # saves the src/out association
$ b foo-out/                  # no need to repeat src
```


## Meta-Operations

| Meta-operation | Description |
|----------------|-------------|
| `perform`      | Perform an operation on a target (the default meta-operation). |
| `configure`    | Configure all operations for a project and save the result to `build/config.build`. Accepts `forward` and `hardlink` parameters. |
| `disfigure`    | Undo a previous `configure`, removing `build/config.build`. Accepts a `forward` parameter to remove only the forwarding link. |
| `create`       | Create and configure a configuration project (an amalgamation directory with no source files of its own). Takes optional module lists as parameters. |
| `dist`         | Prepare a source distribution containing all files needed to perform all operations. |
| `info`         | Print project metadata (name, version, src/out directories, subprojects) to stdout. Accepts `json`, `no_subprojects`, and `committed_version` parameters. |


## Operations

| Operation | Description |
|-----------|-------------|
| `update` | Build (bring up to date) a target. |
| `clean` | Remove build artifacts for a target. |
| `test` | Test a target. Performs `update` as a pre-operation. |
| `update-for-test` | Update only what is needed for testing. Equivalent to the `update` pre-operation of `test`. |
| `install` | Install a target. Performs `update` as a pre-operation. |
| `uninstall` | Uninstall a previously installed target. Performs `update` as a pre-operation. |
| `update-for-install` | Update only what is needed for installation. Equivalent to the `update` pre-operation of `install`. |


## Key Options Overview

| Option | Description |
|--------|-------------|
| `-v` | Print actual commands being executed. Equivalent to `--verbose 2`. |
| `-V` | Print all underlying commands being executed. Equivalent to `--verbose 3`. |
| `--verbose <level>` | Set diagnostics verbosity 0-6. Default is 1. |
| `--quiet` / `-q` | Suppress all non-error output (equivalent to `--verbose 0`). |
| `--silent` | Suppress all non-error output in all contexts including module updates. |
| `--jobs` / `-j <num>` | Number of parallel jobs. `0` or omitted uses hardware thread count. Negative values subtract from hardware thread count. |
| `--serial-stop` / `-s` | Run serially and stop at the first error. Useful for diagnosing build system errors. |
| `--dry-run` / `-n` | Print commands without executing them. Still does minimum work to determine accurate build state. Only supported by `perform`. |
| `--match-only` | Match rules without executing the operation. Useful for profiling and state inspection. |
| `--load-only` | Match rules for `alias{}` targets only, effectively loading all subdirectory buildfiles without building. |
| `--no-external-modules` | Skip loading external modules during bootstrap. Can only be used with meta-operations that do not load buildfiles (e.g., `info`). |
| `--config-guess <path>` | Path to a `config.guess` script for determining the host machine triplet. |
| `--config-sub <path>` | Path to a `config.sub` script for canonicalizing machine triplets. |
| `--buildfile <path>` | Alternative buildfile to read. Use `-` to read from stdin. |
| `--structured-result <fmt>` | Write execution results in machine-readable form to stdout. Valid formats are `lines` and `json`. |
| `--dump <phase>` | Dump the build system state after `load` or `match` phases for debugging. |
| `--stat` | Display build statistics after the build completes. |
| `--progress` / `--no-progress` | Control display of the build progress indicator. |
| `--no-default-options` | Do not load any default options files (`b.options`). |
| `--options-file <file>` | Read additional options from a file, one option per line. |


## Configuration Variables

Build configuration is passed as `name=value` assignments anywhere on the
command line. Common configuration variables are provided by modules such as
`config.cxx`, `config.cxx.coptions`, `config.install.root`, etc.

```
$ b config.cxx=clang++ config.cxx.coptions=-O3
```

To avoid treating an argument starting with `-` as an option, or an argument
containing `=` as a variable, use the `--` separator:

```
$ b -- -weird-target
$ b configure -- config.cxx=g++
```

Variable assignments can also be split into three separate arguments to allow
shell path completion on the right-hand side:

```
$ b config.import.libhello = ../libhello/
```

Variables specified on the command line are global overrides. They take
precedence over values set in `build/config.build` and are propagated to
nested driver invocations via the `BUILD2_VAR_OVR` environment variable.


## Common Usage Patterns

**Build the current directory:**
```
$ b
```

**Build and run tests:**
```
$ b test
```

**Rebuild from scratch:**
```
$ b clean update
```

**Configure an out-of-source build:**
```
$ b configure: src/@../build-release/
```

**Configure with compiler and install prefix:**
```
$ b configure: config.cxx=clang++ config.install.root=/usr/local
```

**Build after configuring (no need to repeat variables):**
```
$ b
```

**Configure a forwarded build so `b` in the source dir builds out-of-source:**
```
$ b configure: foo/@foo-out/,forward
$ cd foo/
$ b
```

**Create a configuration project amalgamating several sub-projects:**
```
$ b create: clang/,cxx config.cxx=clang++
$ b configure: libfoo/@clang/libfoo/
$ b configure: hello/@clang/hello/
$ b clang/
```

**Install a project:**
```
$ b install: config.install.root=/usr/local/
```

**Prepare a distribution tarball:**
```
$ b dist: ./
```

**Print project metadata:**
```
$ b info: ./
$ b info: libfoo/,json
```


## Navigation

- [b full reference](b.md)
- [bx reference](../bx/bx.md) -- shell script and task runner

## See Also

- [`alias-targets`](../HOWTO/alias-targets.md) -- PHONY-equivalent targets using `alias{}`
- [`buildfile-compile-options`](../HOWTO/buildfile-compile-options.md) -- which compile/link options belong in a buildfile, compile-line order, cxx.mode after std
- [`generated-headers`](../HOWTO/generated-headers.md) -- auto-generated C/C++ headers
- [`config-independent-build-graph`](../HOWTO/config-independent-build-graph.md) -- keeping the build graph configuration-independent
- [`target-metadata`](../HOWTO/target-metadata.md) -- exporting metadata with executables and libraries
- [`build2-buildfile-language`](../guides/build2-buildfile-language.md) -- full buildfile language syntax reference