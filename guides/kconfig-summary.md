# libbuild2-kconfig -- Kconfig Module Reference

## Overview

The `kconfig` module integrates the Linux kernel configuration system (Kconfig)
into the `build2` build system. It hooks into the `configure` and `disfigure`
meta-operations of the `config` module, runs a Kconfig configurator to produce
a `.config`-style file (`build/config.kconfig`), and exposes the resulting
values as `kconfig.<project>.*` Buildfile variables.

Use the `kconfig` module when your project has a large number of configuration
options with complex inter-dependencies that benefit from a dedicated
configurator UI (interactive terminal menus, graphical dialogs, or random
testing). For simple, mostly compile-time switches that do not need a separate
configuration session, the built-in `config` module with `config.*` variables
is sufficient and involves less setup.

Key characteristics:

- The module is part of the standard pre-installed set of `build2` modules.
  No extra package installation is needed beyond the `using kconfig` directive
  in `bootstrap.build`.
- Configuration values are named `kconfig.<project>.<symbol_lowercase>` and
  are available in all `buildfiles` and `testscripts` after the module
  initializes.
- `bool` Kconfig values map to the `bool` Buildfile type (`true`/`false`).
  `string` maps to `string`. `int` maps to `int64`. `hex` maps to `uint64`.
  `tristate` maps to `string` with values `true`, `false`, or `module`.
- If a non-bool option is disabled (its dependencies are unsatisfied), the
  corresponding `kconfig.*` variable is `null`.


## Enabling the Module

Load the module in `build/bootstrap.build`, after `using config`:

```
project = myproject

using version
using config
using kconfig
using test
using install
using dist
```

By default the module looks for `build/Kconfig` as the top-level definition
file. The module initializes lazily: on `configure`, it runs the configurator
and writes `build/config.kconfig`. On subsequent builds, it loads and validates
the existing file.

You may also initialize the module explicitly inside `build/root.build` at any
point where you need `kconfig.*` variables to be immediately available:

```
using cxx

using kconfig

if ($kconfig.myproject.fancy && $cxx.target.class == 'windows')
  fail "fancy mode is not supported on Windows"
```

Add the generated files to `.gitignore`:

```
/config.build
/config.kconfig*
```

The wildcard after `config.kconfig` also covers `config.kconfig.new`
(temporary during configure) and `config.kconfig.old` (saved by configurators
on reconfigure).


## The Kconfig Language

Kconfig is a line-oriented language. Lines can be continued with a trailing
`\`. The `#` character starts a comment. Special characters (`$`, quotes, `\`)
can be escaped with a backslash.

Strings use single or double quotes with identical semantics. A `Kconfig` file
begins with optional macro variable assignments, followed by zero or more
definitions (`config`, `menu`, `choice`, `comment`, `source`).


### Config Entries

```
config SYMBOL
      type ["prompt" [if expr]]
      prompt "prompt" [if expr]
      default value [if expr]
      range integer integer [if expr]
      depends on expr
      select SYMBOL [if expr]
      imply SYMBOL [if expr]
      help
        text
```

The `config` keyword starts an option definition. `SYMBOL` is traditionally
spelled in upper case. It appears in the configuration file as `CONFIG_SYMBOL`
and in Buildfile as `kconfig.<project>.symbol` (lower case).

**Supported types:**

| Type      | Buildfile type | Values                          |
|-----------|----------------|---------------------------------|
| `bool`    | `bool`         | `y` or `n`                      |
| `string`  | `string`       | quoted text                     |
| `int`     | `int64`        | signed 64-bit decimal integer   |
| `hex`     | `uint64`       | unsigned 64-bit hex (`0x...`)   |
| `tristate`| `string`       | `true`, `false`, or `module`    |

The prompt text is customarily combined with the type for brevity:

```
config IO
      bool "IO support"
      help
        Enable stdin/stdout input/output.
```

A separate `prompt` attribute can be used when multiple conditional prompts
are needed with `if expr`.

If a bool or tristate option has no default, `n` is assumed. If a string
option has no default, empty string is assumed. For `int` and `hex`, no
default is assumed and using non-interactive configuration methods without a
default value is an error.

`kconfig.*` variables are overridable on the command line without reconfiguring:

```
$ b kconfig.myproject.io=false
```

Note that such overrides bypass Kconfig dependency resolution.


### Dependency Keywords

**`depends on expr`** -- forward dependency. If the expression evaluates to
false, the option is disabled: `bool`/`tristate` become `n`, other types
become `null`. Disabled options are not shown to the user and do not use their
default value.

```
config NAME_ASK
      bool "Ask for name"
      depends on IO
```

Multiple `depends on` attributes are ANDed together.

**`select SYMBOL [if expr]`** -- strong reverse dependency. Forces `SYMBOL` to
`y` whenever this option is `y`, regardless of `SYMBOL`'s own dependencies or
user selection. Use with caution on user-visible options; prefer using `select`
on invisible helper options (see Helper Options below).

**`imply SYMBOL [if expr]`** -- weak reverse dependency. Suggests `y` as the
default for `SYMBOL` when this option is `y`, but the user can still override
it and unsatisfied dependencies still disable it.

```
config IO
      bool "IO support"
      default y
      imply NAME_ASK
```


### Default Values

The `default` attribute sets the suggested or fallback value:

```
config PUNCT
      string "End of greeting punctuation"
      default "!"
```

Multiple `default` attributes with `if expr` conditions are evaluated in
order; the first matching one applies:

```
config GREETING_TEXT
      string "Custom greeting" if GREETING_CUSTOM
      default "Hello" if GREETING_HELLO
      default "Hi"    if GREETING_HI
      default "Howdy" if GREETING_HOWDY
```


### Range Constraints

The `range` attribute restricts `int` and `hex` values to an inclusive range.
The user cannot enter a value outside the range:

```
config NAME_ASK_MAX
      int "Max times to ask for name"
      default 5
      range 1 10
```


### Menu and Choice Blocks

**`menu` / `endmenu`** -- groups related options under a named submenu:

```
menu "Basic options"

config IO
      bool "IO support"

config PUNCT
      string "End of greeting punctuation"
      default "!"

endmenu
```

The `visible if expr` attribute hides the entire menu and all its entries when
the expression is false. The `depends on expr` attribute on a `menu` is
equivalent to adding that dependency to every entry inside it.

**`menuconfig`** -- a hybrid that acts as both a `config` entry and a `menu`
parent. Entries that depend on its symbol become its submenu:

```
menuconfig FANCY
      bool "Fancy options"

if FANCY

config GREETING
      string "Custom greeting"

config NAME_ASK
      bool "Ask for name"

endif
```

**`choice` / `endchoice`** -- restricts selection to at most one option from a
set. Choice options must be `bool` or `tristate`. A `default` attribute names
the pre-selected option. The `optional` attribute allows no selection at all:

```
choice
      prompt "Greeting"
      default GREETING_HELLO

config GREETING_HELLO
      bool "\"Hello\""

config GREETING_HI
      bool "\"Hi\""

config GREETING_CUSTOM
      bool "Custom greeting"

endchoice
```

A named optional choice can be used as a helper to detect whether any choice
option was selected:

```
choice NAME_FALLBACK
      bool "Name fallback"
      optional

config NAME_ASK
      bool "Ask for name"

config NAME_DEF
      bool "Use default name"

endchoice
```

`kconfig.myproject.name_fallback` is then `true` if any option was selected.


### Conditional Blocks

`if` / `endif` applies a dependency to all enclosed entries. It is the most
common way to group options that share the same dependency:

```
if IO

config NAME_ASK
      bool "Ask for name"

config TRACE
      bool "Trace execution"

endif
```

This is equivalent to adding `depends on IO` to each entry inside the block.
Note that `source` inside `if` / `endif` is an unconditional inclusion with the
dependency propagated to the sourced definitions, not a conditional file
include.


### Help Text

The `help` keyword introduces multi-line help. Text is indented relative to
`help` (customarily 2 spaces). The help ends when indentation drops below the
first help line's indentation:

```
config IO
      bool "IO support"
      help
        Enable stdin/stdout input/output. Note that if this option
        is disabled, then you won't see any output.
```


## Build System Integration

### Loading Kconfig Files

Place the top-level `Kconfig` definition file at `build/Kconfig`. To source
additional files or to place the root `Kconfig` in the project root directory,
use the `source` directive with the pre-defined `SRC_ROOT` macro variable
(which equals `src_root` in Buildfiles):

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


### Generated Configuration

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


### Configuration Storage

`build/config.kconfig` is the active configuration. It is written atomically:
the configurator writes `build/config.kconfig.new` first, then `configure`
renames it to `build/config.kconfig` only after the project loads
successfully. On `disfigure`, `config.kconfig` is moved to
`config.kconfig.old`.

The module verifies on each build that `config.kconfig` is consistent with the
current `Kconfig` definitions. If it is not (for example, after adding or
removing options), `build2` fails and asks you to reconfigure.


## Module Variables

| Variable | Type | Description |
|---|---|---|
| `config.kconfig` | `string` | Configuration method to use. Format: `[new-|old-](def|ask|reask|mconf|qconf|env ...) [file]`. Default: `ask`. |
| `kconfig.kconfig.configure` | `string` | Default method when configuring from scratch (no existing `config.kconfig`). Default: `reask`. |
| `kconfig.kconfig.reconfigure` | `string` | Default method when reconfiguring with existing `config.kconfig`. Default: `ask`. |
| `kconfig.kconfig.retryconfigure` | `string` | Default method when `config.kconfig.new` exists from an interrupted run. Default: `reask`. |
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


## See Also

- [build2 modules core](build2-modules-core.md)
- Official Kconfig Language: https://www.kernel.org/doc/html/latest/kbuild/kconfig-language.html
- Official Kconfig Macro Language: https://www.kernel.org/doc/html/latest/kbuild/kconfig-macro-language.html
- Example package: https://cppget.org/kconfig-hello
