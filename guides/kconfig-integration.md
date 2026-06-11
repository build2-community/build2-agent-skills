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

- [kconfig-summary.md](kconfig-summary.md) -- Kconfig language reference
- [build2 core modules](build2-modules-core.md)
- Official Kconfig Language: https://www.kernel.org/doc/html/latest/kbuild/kconfig-language.html
- Official Kconfig Macro Language: https://www.kernel.org/doc/html/latest/kbuild/kconfig-macro-language.html
- Example package: https://cppget.org/kconfig-hello
