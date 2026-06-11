# build2 Miscellaneous Modules Reference

This document covers the `in` and `bash` build system modules. These modules
can be loaded in `build/root.build` (they do not need bootstrapping).

---

## in module

### Overview

The `in` module preprocesses `.in` (input) template files by substituting
build system variable references with their values to produce an output file.
A substitution is a variable name enclosed between a pair of substitution
symbols (default: `$`). The rule tracks changes to both the input file and
the substituted variable values, and regenerates the output automatically.

Several other modules -- including `version`, `bash`, and the third-party
`autoconf` module -- are based on `in` and extend its preprocessing rule.

### Enabling

Load in `build/root.build` (or `build/bootstrap.build` for early use):

```
using in
```

### Target Type

The module defines the `in{}` target type and implements the `in` rule.
The `in{}` type supports target-dependent search: when used as a prerequisite,
the `.in` extension on the source file can be omitted. All three declarations
below produce the same result:

```
hxx{config}:     in{config}
hxx{config.hxx}: in{config}
hxx{config.hxx}: in{config.hxx.in}
```

The `in` rule matches any `file{}`-based target that has an `in{}`
prerequisite, provided no more specific extended rule (such as the `version`
or `bash` rule) matches.

### Substitution Syntax

The default substitution symbol is `$`. A substitution is the variable name
enclosed between two instances of the symbol:

```
// config.hxx.in

#define TARGET "$cxx.target$"
```

The double symbol (`$$`) is the escape sequence in strict mode.

Variable values are looked up starting from target-specific variables. Typed
values are converted to string using the corresponding `builtin.string()`
overload before substitution.

### Substitution Modes

| Mode | Behavior |
|---|---|
| `strict` (default) | Every substitution symbol must start a valid substitution. Unresolved names are errors. `$$` is the escape sequence. |
| `lax` | Only treats a symbol pair as a substitution if the enclosed text looks like a variable name (no spaces, etc.). Unterminated symbols and non-variable-looking content are copied as-is. `$$` is not treated as an escape sequence. |

Lax mode is useful when adapting existing `.in` files from other build
systems such as `autoconf`. It is still stricter than `autoconf` because
unresolved substitutions are errors (unless `in.null` is set).

### Key Variables

All of these are target-specific variables set on the output target or its
group.

| Variable | Type | Description |
|---|---|---|
| `in.symbol` | string (1 char) | Substitution symbol. Default: `$`. Must be a single character. |
| `in.mode` | string | Substitution mode: `strict` (default) or `lax`. |
| `in.substitutions` | string list | Key-value pairs (`name@value`) providing substitution values. Entries here take precedence over buildfile variables. Omitting the value (just `name`) sets a null value. |
| `in.null` | string | Fallback string used when a substituted variable has a `null` value. Using a null value without this fallback is an error. |

### Usage Examples

Basic usage -- substitute `cxx.target` into a configuration header:

```
# build/root.build

using in
```

```
// config.hxx.in

#define TARGET "$cxx.target$"
```

```
# buildfile

hxx{config}: in{config}
```

Change the substitution symbol to `@`:

```
// data.cxx.in

const char data[] = "@data@";
```

```
# buildfile

cxx{data}: in{data}
{
  in.symbol = '@'
  data = 'Hello, World!'
}
```

Adapt an autoconf-style `.in` file with lax mode:

```
# buildfile

h{config}: in{config}
{
  in.symbol = '@'
  in.mode = lax

  CMAKE_SYSTEM_NAME = $c.target.system
  CMAKE_SYSTEM_PROCESSOR = $c.target.cpu
}
```

Use `in.substitutions` for names that cannot be buildfile variables (for
example, names starting with `_`):

```
/* config.h.in */

#define _GNU_SOURCE   @_GNU_SOURCE@
#define _POSIX_SOURCE @_POSIX_SOURCE@
```

```
# buildfile

h{config}: in{config}
{
  in.symbol = '@'
  in.mode = lax

  in.substitutions = _GNU_SOURCE@0 _POSIX_SOURCE@1
}
```

Allow null substitutions to produce an empty string:

```
h{config}: in{config}
{
  in.null = ''
}
```

---

## bash module

### Overview

The `bash` module provides modularization support for Bash scripts. It is
built on top of the `in` module and extends its preprocessing rule with
support for _import substitutions_ in the form `@import <module-path>@`.
During preprocessing, each import substitution is replaced with a `source`
builtin call that sources the appropriate module file.

The module allows Bash scripts to be split into reusable, installable modules.
Modules can depend on other modules and can be factored into separate
_module libraries_ that are imported using the standard build system import
mechanism.

### Enabling

Load in `build/root.build`:

```
using bash
```

### Target Types

The module defines the `bash{}` target type for `.bash` module files.

### Default Substitution Behavior

The `bash` preprocessing rule uses lax substitution mode and `@` as the
substitution symbol by default. These defaults can be overridden using the
standard `in` module variables (`in.symbol`, `in.mode`).

### Import Path Convention

An import path has the form `<project>/<module-name>`. The first component
must be both the project name and the top-level subdirectory containing the
module. The `.bash` extension can be omitted from the module name.

```
@import hello/say-hello@
```

During development the import resolves to the absolute source path of the
`bash{}` prerequisite. During installation it resolves to a path relative to
the sourcing script, so installed scripts and modules can be moved together.

Module libraries use the `lib` name prefix by convention (for example,
`libhello`). If a native library also exists, the Bash library appends `.bash`
to its name (for example, `libhello.bash`), while the top-level subdirectory
keeps the shorter name (`libhello/`).

### Installation Layout

By default, a script is installed into `bin/` and its modules into a
subdirectory named `<project>.bash/` under the same `bin/` directory. For
example, a script `hello` would be installed as `bin/hello` and a module
`say-hello.bash` as `bin/hello.bash/say-hello.bash`.

### Module Conventions

Public modules (those meant for use by other projects) should:

- Prefix all functions and global variables with the library name (without
  the `lib` prefix) to avoid name clashes.
- Include a source guard at the top to prevent being sourced multiple times.

```
# libhello/say-hello.bash

if [ "$hello_say_hello" ]; then
  return 0
else
  hello_say_hello=true
fi

function hello_say_hello ()
{
  echo "Hello, $1!"
}
```

Private modules are implementation details of a single project and are not
imported from other projects.

### Key Variables

| Variable | Type | Description |
|---|---|---|
| `in.symbol` | string (1 char) | Substitution symbol. Default for `bash` rule: `@`. |
| `in.mode` | string | Substitution mode. Default for `bash` rule: `lax`. |

All other `in` module variables apply as well.

### Usage Examples

Simple script with one module in the same project:

```
# build/root.build

using bash
```

```
# hello/say-hello.bash

function say_hello ()
{
  echo "Hello, $1!"
}
```

```
#!/usr/bin/env bash

# hello/hello.in

@import hello/say-hello@

say_hello 'World'
```

```
# hello/buildfile

exe{hello}: in{hello} bash{say-hello}
```

Import a module from a separate `libhello` module library project:

```
# hello/buildfile

import mods = libhello%bash{say-hello}

exe{hello}:        in{hello}       bash{hello-world}
bash{hello-world}: in{hello-world} $mods
```

```
# hello/hello-world.bash.in

@import libhello/say-hello@

function hello_world ()
{
  hello_say_hello 'World'
}
```

Wrapper to expose a shorter function name:

```
@import libhello/say-hello@

function say_hello () { hello_say_hello "$@"; }
```

---

## See Also

- [build2 manual summary](build2-intro-concepts.md)
- [build2 core modules](build2-modules-core.md)
- [libbuild2-autoconf module](build2-modules-autoconf.md) -- autoconf/cmake/meson config.h processing built on top of `in`
