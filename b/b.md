# b -- Build System Driver (Full Reference)

## Synopsis

```
b [<options>] [<variables>] [<buildspec>]

<buildspec> = <meta-operation>(<operation>(<target>...[,<parameters>])...)...
```

## Description

The `build2` build system driver executes a set of meta-operations on operations on targets according to the build specification, or _buildspec_ for short. This process can be controlled by specifying driver `<options>` and build system `<variables>`.

Options, variables, and buildspec fragments can be specified in any order. To avoid treating an argument starting with `-` as an option, add the `--` separator. To avoid treating an argument containing `=` as a variable, add a second `--` separator.

The build system has built-in and pre-defined meta-operations (`perform`, `configure`, `disfigure`, `create`, `dist`, `info`) and operations (`update`, `clean`, `test`, `update-for-test`, `install`, `uninstall`, `update-for-install`). A meta-operation applied to an operation is called an _action_.

Buildspec and command line variable values are treated as `buildfile` fragments and can use quoting, escaping, variable expansions, and evaluation contexts. Escaping is limited to the effective sequences `\'`, `\"`, `\\`, `\$`, and `\(`. For example:

```
$ b config.install.root=c:\projects\install
$ b "config.install.root='c:\Program Files\test\'"
$ b 'config.cxx.poptions=-DFOO_STR=\"foo\"'
```

## Buildspec

All components in the buildspec can be omitted. If `<meta-operation>` is omitted it defaults to `perform`. If `<operation>` is omitted it defaults to the default operation for that meta-operation -- for `perform` that is `update`. If `<target>` is omitted it defaults to the current working directory. Some operations and meta-operations may take additional `<parameters>`.

```
$ b                       # perform(update(./))
$ b foo/                  # perform(update(foo/))
$ b foo/ bar/             # perform(update(foo/ bar/))
$ b update                # perform(update(./))
$ b 'clean(../)'          # perform(clean(../))
$ b perform               # perform(update(./))
$ b configure             # configure(?(./))
$ b 'configure(../)'      # configure(?(../))
$ b clean update          # perform(clean(./) update(./))
$ b configure update      # configure(?(./)) perform(update(./))
$ b 'create(conf/, cxx)'  # create(?(conf/), cxx)
```

The question mark above shows the imaginary default operation for `configure` -- it configures all operations for the specified target.

You can generate multiple operations for the same targets using brace expansion:

```
$ b '{clean update}(foo/ bar/)'
$ b '{clean update}(...)'        # rebuild
$ b '{clean update clean}(...)'  # make sure builds
$ b '{clean test clean}(...)'    # make sure passes tests
$ b '{clean disfigure}(...)'     # similar to distclean
```

**Shortcut syntax** -- in POSIX shells parentheses must be quoted, which also inhibits path auto-completion. A shortcut syntax is available for a single operation or meta-operation by ending the first buildspec argument with a colon:

```
$ b clean: foo/ bar/                # clean(foo/ bar/)
$ b configure: src/@out/            # configure(src/@out/)
$ b create: conf/, cxx              # create(conf/, cxx)
$ b configure: config.cxx=g++ src/  # configure(src/) config.cxx=g++
```

The colon is replaced with `(`, the rest of the arguments are used as-is, and a closing `)` is appended.

**Source/output directories** -- for each target the driver expects to find `buildfile` either in the target directory or, if it is part of the `out` tree, in the corresponding `src` directory. You can specify `src_base` explicitly using:

```
<src-base>/@<target>
```

Example workflow:

```
$ b configure: foo/@foo-out/  # src_base is saved
$ b foo-out/                  # no need to specify src_base
$ b clean: foo-out/exe{foo}   # no need to specify src_base
```

A directory target with subdirectories but no `buildfile` uses an implied buildfile that builds all subdirectories (`./: */`).

**Forwarded builds** -- a source directory can be configured as _forwarded_ to an out-of-source build. The driver then builds in the output directory and _backlinks_ interesting targets (executables, documentation, etc.) back to the source directory:

```
$ b configure: foo/@foo-out/,forward  # foo/ forwarded to foo-out/
$ cd foo/
$ b                                   # build in foo-out/
$ ./foo                               # symlink to foo-out/foo
```

**Variable assignment** -- variables passed on the command line normally carry configuration values. To help with path auto-completion the assignment can be split across three arguments:

```
$ b config.import.libhello = ../libhello/
```

## Meta-Operations

**`perform`** -- perform an operation.

**`configure`** -- configure all operations supported by a project and save the result in the project's `build/config.build` file. Implemented by the `config` module. Example:

```
$ b configure                      \
    config.cxx=clang++             \
    config.cxx.coptions=-O3        \
    config.install.root=/usr/local \
    config.install.root.sudo=sudo
```

Use the `forward` parameter to configure a source directory as forwarded to an out-of-source build:

```
$ b configure: src/@out/,forward
```

Use the `hardlink` parameter to configure an out-of-source build that hard-links `src-root.build` from the source directory (useful to track the source directory use count via the file's hard link count).

**`disfigure`** -- disfigure all operations and remove `build/config.build`. Implemented by the `config` module. Use the `forward` parameter to remove forwarding only:

```
$ b disfigure: src/,forward
```

**`create`** -- create and configure a _configuration_ project. Implemented by the `config` module.

A configuration project has no source files of its own. It serves as an amalgamation for building other projects so that sub-projects automatically resolve their imports and inherit their configuration from the amalgamation.

Example -- building two projects together under `clang/` instead of configuring each separately:

```
$ b create: clang/,cxx config.cxx=clang++  # creates clang/
$ b configure: libhello/@clang/libhello/
$ b configure: hello/@clang/hello/
```

Target directories passed to `create` must not exist or be empty. `create` initializes a project then runs `configure` on it.

The first optional parameter is the list of modules to load in `root.build`. By default `.config` is appended to module names so only their configurations are loaded. Append `.` after a module name to override this. Prefix with `?` for optional module load.

The second optional parameter is the list of modules to load in `bootstrap.build`. If not specified the `test`, `dist`, and `install` modules are loaded by default (`config` is always loaded first).

`create` also writes a root `buildfile` containing `./: {*/ -build/}`, which builds all sub-projects currently present in the configuration.

**`dist`** -- prepare a distribution containing all files necessary to perform all operations in a project. Implemented by the `dist` module.

**`info`** -- print basic information about one or more projects to `stdout`, separating multiple projects with a blank line. Each project is identified by its root directory target.

```
$ b info: libfoo/ libbar/
project: libfoo
version: 1.0.0
src_root: /tmp/libfoo
out_root: /tmp/libfoo
subprojects: @tests
```

Parameters:

- `no_subprojects` -- omit discovering and printing subproject information.
- `committed_version` -- ignore uncommitted or untracked changes when calculating project version.
- `json` -- print output as a JSON array. Each element represents a project with the following fields: `project`, `version`, `summary`, `url`, `src_root`, `out_root`, `amalgamation`, `subprojects` (array of `{path, name?}`), `operations`, `meta-operations`, `modules`. Fields typed `optional<>`, `bool`, and `vector<>` may be absent (absent bool means false, absent vector means empty).

## Operations

**`update`** -- update a target.

**`clean`** -- clean a target.

**`test`** -- test a target. Performs `update` as a pre-operation. Implemented by the `test` module.

**`update-for-test`** -- update a target for testing only. Equivalent to the `update` pre-operation as executed by `test`, updating only what is necessary for testing. Implemented by the `test` module.

**`install`** -- install a target. Performs `update` as a pre-operation. Implemented by the `install` module.

**`uninstall`** -- uninstall a target. Performs `update` as a pre-operation. Implemented by the `install` module.

**`update-for-install`** -- update a target for installation only. Equivalent to the `update` pre-operation as executed by `install`, updating only what is necessary for installation. Implemented by the `install` module.

## Options

| Option | Arg | Default | Description |
|---|---|---|---|
| `-v` | | | Print actual commands being executed. Equivalent to `--verbose 2`. |
| `-V` | | | Print all underlying commands being executed. Equivalent to `--verbose 3`. |
| `--quiet`, `-q` | | | Run quietly, only printing error messages in most contexts. In certain contexts (such as updating build system modules) this level may be ignored; use `--silent` to suppress in all contexts. Equivalent to `--verbose 0`. |
| `--silent` | | | Run quietly, only printing error messages in all contexts. |
| `--verbose` | `<level>` | `1` | Set diagnostics verbosity 0-6. Level 0 suppresses non-error messages, level 6 is most detailed. Level 1: high-level info. Level 2: essential underlying commands. Level 3: all underlying commands. Level 4: info helpful to user. Level 5: info helpful to developer. Level 6: even more detail. |
| `--stat` | | | Display build statistics. |
| `--progress` | | | Display build progress. Enabled by default for low verbosity when printing to a terminal. Use `--no-progress` to suppress. |
| `--no-progress` | | | Don't display build progress. |
| `--diag-color` | | | Use color in diagnostics. Enabled by default on non-dumb terminals. Some rules propagate this to invoked tools. Use `--no-diag-color` to suppress. |
| `--no-diag-color` | | | Don't use color in diagnostics. |
| `--jobs`, `-j` | `<num>` | hw threads | Number of active parallel jobs (threads plus outstanding external commands). Value `0` uses hardware thread count. Negative value subtracts from hardware thread count. |
| `--max-jobs`, `-J` | `<num>` | 8x/32x jobs | Maximum number of threads to create (8x active jobs on 32-bit, 32x on 64-bit). |
| `--queue-depth`, `-Q` | `<num>` | `4` | Queue depth as a multiplier over active jobs. Use deeper for long jobs (compilation) and shallower for quick jobs (simple tests). |
| `--jobserver` | `<type>` | platform default | GNU make jobserver type to start: `fifo` (named pipe on POSIX) or `none`. When started, external commands receive jobserver info via `MAKEFLAGS`. |
| `--file-cache` | `<impl>` | `sync-lz4` | File cache implementation for intermediate build results: `noop` (no caching/compression) or `sync-lz4` (synchronous LZ4 on-disk compression, no caching). |
| `--max-stack` | `<num>` | | Maximum per-thread stack size in KBytes. The driver caps excessively large main-thread stacks (over 64 MB on 64-bit, 32 MB on 32-bit) to 8 MB. Use `0` to disable the cap and use the main thread size as-is. |
| `--serial-stop`, `-s` | | | Run serially and stop at the first error. Useful for diagnosing build system errors. No diagnostics buffering and child `stderr` is a terminal during serial execution. |
| `--dry-run`, `-n` | | | Print commands without executing them. Commands needed to create accurate build state are still run and dependency info saved. Only `perform` supports this mode. |
| `--no-diag-buffer` | | | Do not buffer diagnostics from child processes. By default diagnostics is buffered to prevent interleaving, but this makes child `stderr` non-terminal (may disable color). |
| `--match-only` | | | Match rules without executing the operation. Primarily useful for profiling and dumping build state. |
| `--load-only` | | | Match rules only to `alias{}` targets, ignoring others and skipping execution. Has the effect of loading all subdirectory buildfiles not explicitly included. Can only be used with `perform(update)` on an `alias{}` target, usually `dir{}`. |
| `--no-external-modules` | | | Don't load external modules during project bootstrap. Can only be used with meta-operations that do not load buildfiles, such as `info`. |
| `--structured-result` | `<fmt>` | | Write execution result in structured form to `stdout` instead of diagnostics to `stderr`. Valid formats: `lines` and `json`. Only `perform` supports this. See Structured Result Format below. |
| `--mtime-check` | | | Perform file modification time sanity checks. Enabled by default on Windows. Use `--no-mtime-check` to disable. |
| `--no-mtime-check` | | | Don't perform file modification time sanity checks. |
| `--dump` | `<phase>` | | Dump build state after the specified phase. Valid values: `load` (after loading buildfiles), `match` (after matching rules), `match-pre`, `match-post`. Repeatable. See also `--dump-scope`, `--dump-target`, `--match-only`, `--load-only`. |
| `--dump-format` | `<format>` | `buildfile` | Format for build state dumps: `buildfile` (human-readable, to `stderr`) or `json-v0.1` (machine-readable JSON, to `stdout`; currently unstable). JSON output uses JSON Lines form (one object per line) when multiple dumps are produced. |
| `--dump-scope` | `<dir>` | | Dump build state for the specified scope only. Repeatable. |
| `--dump-target` | `<target>` | | Dump build state for the specified target only. Repeatable. |
| `--trace-match` | `<target>` | | Trace rule matching for the specified target. Primarily for troubleshooting. Repeatable. |
| `--trace-execute` | `<target>` | | Trace rule execution for the specified target. Primarily for troubleshooting. Repeatable. |
| `--no-column` | | | Don't print column numbers in diagnostics. |
| `--no-line` | | | Don't print line and column numbers in diagnostics. |
| `--buildfile` | `<path>` | `buildfile` | Alternative buildfile to read. Use `-` to read from `stdin`. Affects only files read during buildspec processing, not `source`/`include` directives. Primarily for testing. |
| `--config-guess` | `<path>` | | Path to `config.guess` script for guessing host machine triplet. If not specified, the target `b` was built for is used as the host. |
| `--config-sub` | `<path>` | | Path to `config.sub` script for canonicalizing machine triplets. If not specified, built-in canonicalization is used. |
| `--pager` | `<path>` | `less` | Pager program for long text output. Empty string disables the pager. Falls back to `less` if not specified, or no pager if `less` is unavailable. |
| `--pager-option` | `<opt>` | | Additional option to pass to the pager program. Repeatable. |
| `--options-file` | `<file>` | | Read additional options from a file (one option per line, `#` comments, supports quoting). Repeatable. |
| `--default-options` | `<dir>` | | Additional directory to load default options files from. |
| `--no-default-options` | | | Don't load default options files. |
| `--help` | | | Print usage information and exit. |
| `--version` | | | Print version and exit. |

## Structured Result Format

Activated by `--structured-result=<fmt>`. Only the `perform` meta-operation supports this mode. Output goes to `stdout` rather than diagnostics to `stderr`.

**Lines format** (`--structured-result=lines`) -- one line per buildspec action/target pair:

```
<state> <meta-operation> <operation> <target>
```

`<state>` is one of `unchanged`, `changed`, or `failed`. For pre/post operations the outer operation appears in parentheses:

```
unchanged perform update(test) /tmp/hello/hello/exe{hello}
changed perform test /tmp/hello/hello/exe{hello}
```

**JSON format** (`--structured-result=json`) -- a JSON array of objects:

Fields:

- `target` -- target name qualified with extension if applicable, quoted for command line reuse.
- `display_target` -- unqualified, unquoted display name (same as lines format).
- `target_type` -- the target type name.
- `target_path` -- absolute path, present if the target type is path-based or `dir` (optional).
- `meta_operation` -- meta-operation name.
- `operation` -- operation name.
- `outer_operation` -- outer operation name, present for pre/post operations (optional).
- `state` -- one of `unchanged`, `changed`, `failed`.

Example:

```json
[
  {
    "target": "/tmp/hello/hello/exe{hello.}",
    "display_target": "/tmp/hello/hello/exe{hello}",
    "target_type": "exe",
    "target_path": "/tmp/hello/hello/hello",
    "meta_operation": "perform",
    "operation": "update",
    "outer_operation": "test",
    "state": "unchanged"
  },
  {
    "target": "/tmp/hello/hello/exe{hello.}",
    "display_target": "/tmp/hello/hello/exe{hello}",
    "target_type": "exe",
    "target_path": "/tmp/hello/hello/hello",
    "meta_operation": "perform",
    "operation": "test",
    "state": "changed"
  }
]
```

**JSON output general rules** -- member order is fixed as defined. New members may be added in future versions and should be ignored by older consumers. A member is required unless its type is `optional<>`, `bool`, or `vector<>`. Absent `bool` means false. Absent `vector<>` means empty. An empty top-level array is always present.

## Environment

`HOME` -- used to determine the user's home directory. If not set, `getpwuid(3)` is used. Used to shorten paths in diagnostics (`~/`) and available to buildfiles as `build.home`.

`BUILD2_VAR_OVR` -- propagates global variable overrides to nested build system driver invocations. Value is a newline-separated list of global variable assignments.

`BUILD2_DEF_OPT` -- suppresses loading of default options files in nested invocations. Values: `false` or `0` to suppress, `true` or `1` to load.

## Default Options Files

The `build2` toolchain uses _default options files_ containing the same options as the command line, loaded automatically. These are like `--options-file` files but loaded by default.

For `b`, the default options files are named `b.options` and searched for in `~/.build2/` and in the system directory (e.g., `/etc/build2/`) if configured. These files may also contain global variable overrides.

Files are loaded in reverse search order: system directory first, then home directory, then command line options. This means command line options override default options files. Options are loaded from most generic to most specific.

If a default options file contains `--no-default-options`, the search stops at that directory and no outer files are loaded. If `--no-default-options` is on the command line, no default options files are searched or loaded.

Use `--default-options` to specify an additional directory; its files are loaded after the home directory.

The load order is traced at verbosity level 3 (`-V`).

## See Also

- [b SUMMARY](SUMMARY.md)
- [bx reference](../bx/bx.md)
