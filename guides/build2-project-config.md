# build2 Project Configuration

## Overview

Project configuration in build2 allows a project to declare named configuration
variables that users can set at configure time. The mechanism is provided by the
built-in `config` module and underpins all configuration in the toolchain,
including build system core variables (such as `config.import.*`), module
variables (such as `config.cxx.coptions`), and project-specific variables (such
as `config.libhello.greeting`).

Configuration variables are persisted automatically in `build/config.build` and
are restored on every subsequent build, so the user does not need to repeat
command-line overrides. The configuration report (printed at sufficiently high
verbosity) shows the current values for all declared variables.

build2 does not support autoconf-style environment probing. The recommended
approach is expectation-based configuration: assume features are available when
well-known macros or platform conditions are met, and expose explicit
configuration variables only when the decision must be delegated to the user.

## Enabling Configuration

Load the `config` module (and any other modules your project uses) in
`build/root.build`:

```
using config
using cxx
```

The `config` directive that declares project configuration variables must appear
in `build/root.build` (or in a file sourced from it). It is not valid in
ordinary per-directory buildfiles.

## Declaring Configuration Variables

```
config [<type>] config.<project>.<name> ?= <default>
```

Examples:

```
config [bool]   config.libhello.fancy    ?= false
config [string] config.libhello.greeting ?= 'Hello'
```

The variable name must match the pattern `config[.**].<project>.**`. The
project's own name is the second component; sub-project variables may add
components between `config.` and the project name.

**Type** (inside `[...]`) is optional but strongly recommended. A typed
variable is validated automatically when the user supplies a value. Available
types are listed in the Variables chapter: `bool`, `string`, `strings`,
`path`, `dir_path`, `paths`, `dir_paths`, `int64`, `uint64`, and others.

**Default value** (`?=`) is also optional. If omitted the variable is undefined
(not null) until the user sets it. The `?=` form is the only assignment
operator valid inside the `config` directive.

The semantics of the `config` directive:

1. Enter the variable as overridable with global visibility.
2. If the variable is currently undefined and a default was given, assign it.
3. Mark the variable for persistence in `build/config.build`.
4. Mark the variable for inclusion in the configuration report.

If the user provided a value the default expression is not evaluated.

## Nullable Variables

By default configuration variables are non-nullable. Assigning `[null]` to
one produces an error. There are two ways to make null a valid value.

Using null as the default signals the variable is optional:

```
config [string] config.libhello.fallback_name ?= [null]
```

Using the `null` attribute together with a non-null default:

```
config [string, null] config.libhello.fallback_name ?= 'World'
```

## Required (Mandatory) Variables

To require the user to supply a value, declare the variable without a default
and then check:

```
config [string] config.libhello.database

if! $defined(config.libhello.database)
  fail 'config.libhello.database must be specified'
```

A variable without a default is omitted from `build/config.build` unless the
user sets it. This is also useful for values that are normally derived from
other configuration values but may be overridden:

```
config [strings] config.hello.database

config [bool, config.report.variable=multi] config.hello.multi_database

multi = ($defined(config.hello.multi_database) \
         ? $config.hello.multi_database        \
         : $size(config.hello.database) > 1)
```

When computing the default is expensive or conditional, the two-step pattern
is useful:

```
config [string] config.libhello.greeting

if! $defined(config.libhello.greeting)
{
  greeting = ... # Calculate default value.

  if ($greeting == [null])
    fail 'unable to calculate default greeting, specify manually \
with config.libhello.greeting'

  config config.libhello.greeting ?= $greeting
}
```

## Configuration Cache

The `build/config.build` file stores all configuration values that were either
set by the user or assigned a non-null default. Example after a configure run:

```
$ b configure config.libhello.greeting=Hi -v
config libhello@/tmp/libhello/
  greeting   Hi

$ cat build/config.build
config.libhello.greeting = Hi
```

On subsequent builds the file is read automatically and the stored values are
restored. To reconfigure, run the `configure` meta-operation again with updated
values:

```
$ b configure config.libhello.greeting=Hey
```

To revert a variable to its default, list its name in
`config.config.disfigure`:

```
$ b configure config.config.disfigure=config.libhello.greeting
```

For out-of-source builds, `build/bootstrap/src-root.build` stores the source
root path, removing the need to repeat it on each invocation.

## Hermetic Build Configurations

A hermetic configuration saves the build environment (environment variables)
alongside other configuration so that subsequent builds always see the same
environment as during configuration:

```
$ b configure config.config.hermetic=true
```

This is especially useful for preserving the Visual Studio developer command
prompt environment or for build system modules that need a stable environment.

To re-hermetize (capture a fresh environment snapshot) during reconfiguration:

```
$ b configure config.config.hermetic.reload=true
```

To de-hermetize:

```
$ b configure config.config.hermetic=false
```

The saved environment is stored in `config.config.environment`. To manually
declare that a specific environment variable affects the build result, use the
`config.environment` directive:

```
config.environment USE_FOO

foo = $getenv(USE_FOO)

if ($foo != [null])
  cxx.poptions += "-DUSE_FOO=$foo"
```

## Using Configuration Values

Configuration variables are ordinary buildfile variables accessible via `$`.
Access them by their full name anywhere in the project's buildfiles:

```
# Conditionally include source files.
lib{hello}: {hxx cxx}{hello-io}: include = $config.libhello.io

# Pass a macro to the compiler.
cxx.poptions += "-DLIBHELLO_GREETING=\"$config.libhello.greeting\""
```

After accessing the raw configuration value, assign it to a non-`config.*`
variable if further processing is needed. Do not modify `config.*` variables
directly after the `config` directive.

Pattern for customizable options:

```
config [strings] config.libhello.woptions

woptions  = -Wall -Wextra
woptions += $config.libhello.woptions
woptions += -Werror

cxx.coptions += $woptions
```

This allows users to inject options between the project's defaults and its
mandatory flags.

Enum-like values with validation via `switch`:

```
config [string] config.libhello.database ?= [null]

switch $config.libhello.database
{
  case [null]
  {
    # No database in use.
  }
  case 'sqlite'
  {
    cxx.poptions += -DLIBHELLO_WITH_SQLITE
  }
  case 'pgsql'
  {
    cxx.poptions += -DLIBHELLO_WITH_PGSQL
  }
  default
  {
    fail "invalid config.libhello.database value \
'$config.libhello.database'"
  }
}
```

## Propagating Configuration to Source Code

**Via preprocessor macros** (simple cases):

```
# buildfile
if $config.libhello.fancy
  cxx.poptions += -DLIBHELLO_FANCY

cxx.poptions += "-DLIBHELLO_GREETING=\"$config.libhello.greeting\""
```

**Via a generated header** (recommended for larger projects, uses the `in`
module):

In `build/root.build`:

```
using in
```

In `libhello/config.hxx.in`:

```
#pragma once

#define LIBHELLO_FANCY    $config.libhello.fancy$
#define LIBHELLO_GREETING "$config.libhello.greeting$"
```

In `libhello/buildfile`:

```
lib{hello}: {hxx ixx txx cxx}{** -version -config} hxx{version config}

hxx{config}: in{config}
{
  install = false
}
```

The `in` module substitutes `$variable$` placeholders using the current
buildfile variable values.

To export configuration information to consumers of a library, make the
generated header public (install it) or export the preprocessor options:

```
if $config.libhello.fancy
  lib{hello}: cxx.export.poptions += -DLIBHELLO_FANCY
```

## Configuration Report

The configuration report is printed when at least one variable has a new value
(verbosity 2, `-v`) or always at verbosity 3 (`-V`). It lists each variable
under its short name (the `config[.**].<project>` prefix is stripped):

```
$ b config.libhello.greeting=Hey -v
config libhello@/tmp/libhello/
  fancy      false
  greeting   Hey
```

**Controlling report behavior** with `config.report*` attributes inside `[...]`:

Exclude a variable from the report:

```
config [bool, config.report=false] config.libhello.selftest ?= false
```

Print a list value one element per line (`multiline` format):

```
config [dir_paths, config.report=multiline] config.libhello.search_dirs
```

Report a derived (non-`config.*`) variable instead of the raw value:

```
config [strings, config.report.variable=woptions] \
  config.libhello.woptions

woptions  = -Wall -Wextra
woptions += $config.libhello.woptions
woptions += -Werror
```

Report an automatically discovered value under the `config` report header:

```
config [config.report] plugin_dir
```

Override the module name shown in the report header:

```
config [config.report.module=rtos] revoker
```

## Command-Line Usage

Pass configuration values as `name=value` overrides after the target or
operation:

```
$ b config.libhello.greeting=Hi
$ b configure: config.cxx=clang++ config.libhello.greeting=Hi
```

Values set on the command line override those stored in `config.build` for
that invocation only, unless a `configure` meta-operation is used, which
persists them. A plain build invocation with an override rebuilds affected
targets but does not update `config.build`:

```
$ b config.cxx.coptions=-O3  # Rebuild with -O3 for this run only.
$ b                           # Rebuild with saved settings.
```

The `config.config.disfigure` variable resets named variables to their
defaults and removes them from `config.build`:

```
$ b configure config.config.disfigure=config.cxx.coptions
```

## Factoring config Directives into Separate Files

For projects with many configuration variables, or to share declarations with
sub-projects, extract `config` directives into `build/config/` and source the
file from `build/root.build`:

```
# build/root.build
source $src_root/build/config/common.build
```

The package manager (`bpkg`) expects shared config files in `build/config/`.
Files kept elsewhere must be listed in the package `manifest` under
`build-file`.

## Additional Recommendations for Packages

When a project will be consumed as a `bpkg` package, the package manager
negotiates configuration across dependents. Follow these additional rules:

- Prefer `bool` variables over single enum-like variables.
- Avoid inter-variable default dependencies. If unavoidable, express them
  using the original `config.*` variables, not derived locals.
- Keep the set of configuration variables and their types static (do not
  declare variables conditionally). Express unavailability through defaults
  and validation checks.

## See Also

- [build2 manual summary](build2-intro-concepts.md)
- [build2 modules cc](build2-modules-cc.md)
