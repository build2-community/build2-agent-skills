# build2 kconfig Module -- Build System Integration

Build system integration, module variables, and complete example for the
`kconfig` module.

See [kconfig-summary.md](kconfig-summary.md) for the module overview, enabling
instructions, and the Kconfig language reference.

## Loading Kconfig Files

Place the top-level `Kconfig` definition file at `build/Kconfig`. To source
additional files or to place the root `Kconfig` in the project root directory,
use the `source` directive with the pre-defined `SRC_ROOT` macro variable
(which equals `src_root` in buildfiles):

```
source "$(SRC_ROOT)/Kconfig"
```

Always use `SRC_ROOT`-based absolute paths. On Windows, forward slashes are
required even in Kconfig path strings.

To conditionally include platform-specific fragments, set a `Kconfig.*`
variable in `root.build` and use it for substitution:

```
# root.build
using cxx

Kconfig.PLATFORM = $cxx.target.class
using kconfig
```

```
# build/Kconfig
source "$(SRC_ROOT)/build/Kconfig-$(PLATFORM)"
```

If sourced filenames are determined dynamically, add them to the distribution
explicitly in your root `buildfile`:

```
./: ... build/file{Kconfig-*}
```

This only applies to dynamically-named files. `build/Kconfig` itself and any
files it sources (transitively) by a static, unconditional path -- as well as
any `build/defconfig*.kconfig` default configuration files (see
[Default Configuration Files](#default-configuration-files) below) -- are
automatically added to the distribution and need not be mentioned as
prerequisites.


## Generated Configuration

After `configure`, `build/config.kconfig` holds the saved values in
`CONFIG_SYMBOL=value` format. The module reads this file on every build and
exposes values as `kconfig.<project>.<symbol>` variables (symbol converted to
lower case).

To propagate values to C/C++ source code, use the `in` module in the same way
as with `config.*` values. If a non-bool option can be `null` (disabled
dependency), set `in.null` to avoid substitution errors:

```
h{config}: in{config}
{
  in.null = ''
}
```

The configuration is also reported in the configure-time output at verbosity 2
or higher:

```
$ b configure -v
kconfig myproject@/path/to/myproject/
  io         true
  greeting   Hi
```


## Configuration Storage

`build/config.kconfig` is the active configuration. It is written atomically:
the configurator writes `build/config.kconfig.new` first, then `configure`
renames it to `build/config.kconfig` only after the project loads
successfully. On `disfigure`, `config.kconfig` is moved to
`config.kconfig.old`.

This atomicity requires the configuration to be available during project
loading, before `configure` itself completes, so the module spreads the work
across three points in the process:

| Step | Action |
|---|---|
| `bootstrap.build` | Register the post-`configure` callback with the `config` module. |
| `root.build` | Run the configurator, saving the result to `config.kconfig.new`. |
| `configure` (post-configure) | Rename `config.kconfig.new` to `config.kconfig`. |

The module verifies on each build that `config.kconfig` is consistent with the
current `Kconfig` definitions. If it is not (for example, after adding or
removing options), `build2` fails and asks you to reconfigure.


## Module Variables

| Variable | Type | Description |
|---|---|---|
| `config.kconfig` | `string` | Configuration method to use. Format: `[new-|old-](def|ask|reask|mconf|qconf|env ...) [file]`. Default: `ask`. |
| `kconfig.kconfig.configure` | `string` | Default method when configuring from scratch (no existing `config.kconfig`). Default: `reask`. |
| `kconfig.kconfig.reconfigure` | `string` | Default method when reconfiguring with existing `config.kconfig`. Default: `ask`. |
| `kconfig.kconfig.retryconfigure` | `string` | Default method when `config.kconfig.new` exists from an interrupted run. Default: `reask`. Choosing a method that does not let the user adjust every option can produce an invalid configuration recoverable only by disfiguring the project. |
| `kconfig.kconfig.transient` | `string` | Method used when a build is attempted without `config.kconfig`. Default: `ask` (disabled). Set to `def` or a file path to allow transient configurations. |
| `kconfig.kconfig.title` | `string` | Override for the main menu title. The module sets this to the project name and version by default. |
| `Kconfig.*` | any | External macro variables passed into the Kconfig macro language as `$(NAME)` substitutions. `bool` values are auto-converted from `true`/`false` to `y`/`n`. |

**Configuration method values:**

| Method | Description |
|---|---|
| `def [file]` | Set all newly-defined options to defaults from `file` or from `Kconfig`. Use `new-def` to reset all options. |
| `ask [file]` | Prompt only for newly-defined options. Existing values are preserved. |
| `reask [file]` | Prompt for all options. |
| `mconf` | Full terminal menu configurator (requires `kconfig-mconf` executable). |
| `qconf` | Full graphical configurator (requires `kconfig-qconf` executable). |
| `env prog [args]` | Run an arbitrary program in the Kconfig environment (sets `KCONFIG_CONFIG` etc.). |

`def`, `ask`, and `reask` are built into the module and do not require any
external configurator executables. The `new-` prefix forces creation from
scratch. The `old-` prefix requires an existing `config.kconfig`.


## Example

**`build/Kconfig`:**

```
config IO
      bool "IO support"
      default y
      help
        Enable stdin/stdout input/output.

config GREETING
      string "Custom greeting"
      default "Hello"
      depends on IO
      help
        String to use as a greeting.
```

**`build/bootstrap.build`:**

```
project = hello

using version
using config
using kconfig
using test
using install
using dist
```

**`build/root.build`** (optional: non-interactive default for CI):

```
kconfig.kconfig.configure   = new-def
kconfig.kconfig.reconfigure = old-def
kconfig.kconfig.transient   = def

using kconfig
```

**`buildfile`** (using the values):

```
exe{hello}: cxx{main} h{config}

h{config}: in{config}
{
  in.null = ''
}
```

**`config.h.in`** (source file template):

```c
#define CONFIG_IO $kconfig.hello.io$
#define CONFIG_GREETING "$kconfig.hello.greeting$"
```

**Running configure:**

```
$ b configure
kconfig build/config.kconfig.new
*
* hello 1.0.0
*
IO support (IO) [Y/n/?] (NEW)
Custom greeting (GREETING) [Hello] (NEW) Hi
save build/config.build
mv build/config.kconfig.new build/config.kconfig
```

The resulting `build/config.kconfig`:

```
#
# Automatically generated file; DO NOT EDIT.
# hello 1.0.0
#
CONFIG_IO=y
CONFIG_GREETING="Hi"
```


## Default Configuration Files

Besides defaults from the `Kconfig` file itself, a project can offer several
sets of default values as separate files, for example one per target
platform. A common convention is `defconfig-<platform>.kconfig`, where
`<platform>` is the target class (`linux`, `windows`, `macos`, etc.) from
`cxx.target.class`:

```
using cxx

defconfig = $src_root/build/defconfig-$(cxx.target.class).kconfig

kconfig.kconfig.configure   = new-def $defconfig
kconfig.kconfig.reconfigure = old-def $defconfig
kconfig.kconfig.transient   = def $defconfig

using kconfig
```

`build/defconfig*.kconfig` files are automatically added to the distribution,
same as `build/Kconfig` and the files it statically sources (see
[Loading Kconfig Files](#loading-kconfig-files) above).

Such a file is normally a minimal one produced with
`kconfig-conf --savedefconfig`, which contains only the values that differ
from the `Kconfig` defaults (see
[Backwards Compatibility](#backwards-compatibility) below for why this is
more resilient than committing a full `config.kconfig`). Given a suitably
configured project, extract it with the `env` method:

```
$ b configure config.kconfig=\
"env kconfig-conf --savedefconfig defconfig-linux.kconfig"
```

Or manually, given just the configuration file:

```
$ KCONFIG_CONFIG=config.kconfig \
  kconfig-conf --savedefconfig defconfig-linux.kconfig Kconfig
```

If the `Kconfig` definition file relies on external inputs (see
[External Kconfig Macro Variables](#external-kconfig-macro-variables) below),
manual extraction also requires supplying those inputs via environment
variables.

For the non-interactive configuration methods used above (`new-def`,
`old-def`, `def`), the `kconfig-conf`-to-method mapping, and CI-oriented
recipes such as random configuration generation, see
[kconfig-patterns.md](kconfig-patterns.md).


## External Kconfig Macro Variables

The `kconfig` module lets buildfile variables drive textual substitution inside
`Kconfig` definition files. Any variable named `Kconfig.<NAME>` (capital K) set
in `root.build` before `using kconfig` is passed into the Kconfig macro
language as `$(NAME)`.

`bool` values are automatically converted: Buildfile `true` becomes Kconfig `y`
and `false` becomes `n`. All other types are converted to their string
representation.

The only variable that the module defines automatically is `SRC_ROOT`, which
equals `src_root` in buildfiles. It is used to form absolute paths in `source`
directives.

A common use-case is platform-conditional options. Remove the assignment from
`Kconfig` and instead set it from `root.build`:

```
# build/root.build
using cxx

Kconfig.ENABLE_FANCY = ($cxx.target.class != 'windows')

using kconfig
```

```
# build/Kconfig
config FANCY
      bool "Fancy options"
      depends on $(ENABLE_FANCY)
```

This makes the `FANCY` option unavailable for selection on Windows without
requiring a post-configure check.

A macro substitution that references a name not set in the `Kconfig` file and
not provided via a `Kconfig.*` buildfile variable is an error, so every
variable used in `$(...)` substitutions must be defined in one of the two
places.

Limit external variables to controlling option and menu availability. Using
them to alter prompts, default values, or expressions creates definitions that
are hard to reason about and may surprise users.


## Macro Language

The Kconfig macro language is a two-layer system modelled on `make`. The bottom
layer performs plain textual substitution on the raw text of the `Kconfig`
file. The result of that substitution is then parsed as Kconfig definitions by
the top layer.

### Simple and recursively-expanding variables

Assignments use `:=` for simple variables and `=` for recursively-expanding
variables, the same distinction as in `make`:

- A simple variable (`NAME := value`) is expanded once at the point of
  assignment. All `$(...)` references on the right-hand side are resolved
  immediately.
- A recursively-expanding variable (`NAME = value`) stores the right-hand side
  verbatim and expands it each time `$(NAME)` is referenced elsewhere.

For most uses a simple variable is the right choice and avoids unexpected
re-expansion.

### Substitution scope and lookup order

When `$(NAME)` is encountered, the macro language looks up `NAME` in the
following order:

1. Macro variable assignments at the top of the current `Kconfig` file.
2. `Kconfig.*` buildfile variables (via the module).
3. The built-in `SRC_ROOT`.

An undefined reference is an error.

### All references are always expanded

Because substitution is a flat textual pass over the whole file, every
`$(NAME)` is expanded regardless of whether the surrounding Kconfig expression
would ever evaluate to true at configuration time. For example:

```
config GREETING
      string "Custom greeting"
      default $(DEFAULT_GREETING_IO) if IO
      default $(DEFAULT_GREETING)    if !IO
```

Both `DEFAULT_GREETING_IO` and `DEFAULT_GREETING` must be defined even though
only one branch will be used.

Kconfig keywords cannot themselves be the result of a macro substitution, and
substitutions cannot span multiple Kconfig tokens.

### The `shell` function

The Kconfig macro language inherits a `shell` function from the Linux kernel
build system. Its use is not recommended in `build2` projects: it introduces
portability issues and poor performance because it forks a shell process during
configuration parsing.


## Modularity Support

The `tristate` type extends `bool` with a third state, `m`, that represents
"built as a module". It is purpose-built for the Linux kernel modular driver
model and should only be used when that semantics genuinely applies.

### The `modules` attribute

One `bool` option in the project must be designated as the global modules gate
by adding the `modules` attribute. When that option is `n`, all `tristate`
options behave as `bool` and the `m` state is unavailable. When it is `y`, the
`m` state becomes selectable.

```
config MODULES
      bool "Modules support"
      modules

config IO
      tristate "IO support"
```

To enable modules unconditionally, make the gate option prompt-less with a `y`
default:

```
config MODULES
      bool
      default y
      modules
```

Only one option per configuration may carry the `modules` attribute.

### Buildfile mapping

`tristate` maps to the `string` Buildfile type with three possible values:
`true`, `false`, and `module`. Use equality comparisons in buildfiles to
distinguish all three states.

### `tristate` in choices

A `choice` block whose options are `tristate` allows the user to select at most
one option as `y` but any number as `m` (when modules are enabled). This is the
only context where multiple choice options can be active simultaneously.

```
choice
      prompt "Name fallback"

config NAME_ASK
      tristate "Ask for name"

config NAME_DEF
      tristate "Use default name"

endchoice
```

### Expressions and `m`

In expressions (`depends on`, `if`, etc.) the value `m` is treated as `y` when
modules are enabled and as `n` otherwise.


## Backwards Compatibility

Kconfig is designed to reuse old configurations across project versions. When a
full `config.kconfig` from an older release is loaded against a newer `Kconfig`
definition, options absent from the old file are treated as newly-defined and
receive their defaults. Options present in the old file but no longer in the
definition are silently dropped.

Users may also keep minimal default configurations produced with
`kconfig-conf --savedefconfig`. These files contain only values that differ
from the Kconfig defaults, so they are more resilient to definition changes
than a full `config.kconfig`.

### Changes that are generally safe

- Adding new options.
- Removing or renaming existing options (the old value is dropped).
- Moving options between menus or reorganising the menu hierarchy.
- Changing `depends on` constraints or `visible if` expressions.
- Changing prompt text or help text.

### Changes to avoid

- Changing the type of an existing option. An old value of the wrong type
  produces an invalid configuration.
- Changing the default value or `range` of an existing option. Users who rely
  on the previous default or range will see unexpected behaviour after reload.
- Removing an option from a non-optional `choice` that has no `default`
  attribute. If the removed option was the previously selected one, the choice
  becomes invalid.

When a breaking change is unavoidable, document it prominently in the release
notes and provide migration instructions, for example a replacement default
configuration file that users can load with `config.kconfig="new-def <file>"`.


## See Also

- [kconfig-summary.md](kconfig-summary.md) -- Kconfig language reference
- [kconfig-patterns.md](kconfig-patterns.md) -- helper options, kconfig-conf method mapping, random/fuzz configuration
- [build2 core modules](build2-modules-core.md)
- Official Kconfig Language: https://www.kernel.org/doc/html/latest/kbuild/kconfig-language.html
- Official Kconfig Macro Language: https://www.kernel.org/doc/html/latest/kbuild/kconfig-macro-language.html
- Example package: https://cppget.org/kconfig-hello
