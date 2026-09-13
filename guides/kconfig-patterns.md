# libbuild2-kconfig -- Patterns and Recipes

Practical design patterns and CI-oriented recipes for the `kconfig` module,
supplementing the language reference in
[kconfig-summary.md](kconfig-summary.md) and the build system integration
guide in [kconfig-integration.md](kconfig-integration.md).


## Helper Options

An option with no prompt, or with a prompt disabled via `if expr`, is
invisible to the user. Such an option can still take on a default value or be
set by `select`/`imply`, with the result usable both inside the `Kconfig`
file (for other options' dependencies) and outside through `kconfig.*`
Buildfile variables. These invisible, `select`/`imply`-driven options are
called **helper options**.

The pattern is most useful for collapsing buildfile branching. Consider a
choice between several built-in greetings plus a custom one:

```
choice
      prompt "Greeting"
      default GREETING_HELLO

config GREETING_HELLO
      bool "\"Hello\""
      select GREETING_BUILTIN

config GREETING_HI
      bool "\"Hi\""
      select GREETING_BUILTIN

config GREETING_HOWDY
      bool "\"Howdy\""
      select GREETING_BUILTIN

config GREETING_CUSTOM
      bool "Custom greeting"

endchoice

config GREETING_BUILTIN
      bool
```

`GREETING_BUILTIN` is a helper option: it has no prompt of its own and is set
to `true` only when one of the built-in greetings is selected. It can then
gate another option's dependencies:

```
config PUNCT
      string "End of greeting punctuation"
      default "!"
      depends on !GREETING_BUILTIN
```

Taking the pattern further, a second helper option can absorb the *value* of
whichever branch was taken:

```
config GREETING_TEXT
      string "Custom greeting" if GREETING_CUSTOM
      default "Hello" if GREETING_HELLO
      default "Hi"    if GREETING_HI
      default "Howdy" if GREETING_HOWDY
```

`GREETING_TEXT` now holds the resolved greeting string in both the built-in
and custom cases. Without it, the buildfile would need to branch on every
option:

```
if $kconfig.hello.greeting_builtin
{
  if $kconfig.hello.greeting_hello
    greeting = 'Hello'
  elif $kconfig.hello.greeting_hi
    greeting = 'Hi'
  elif $kconfig.hello.greeting_howdy
    greeting = 'Howdy'
  else
    fail 'unhandled builtin greeting'
}
else
  greeting = $kconfig.hello.greeting_text
```

With the helper option in place, this collapses to:

```
greeting = $kconfig.hello.greeting_text
```

A named optional `choice` used purely to detect whether *any* option in it was
selected (see [kconfig-summary.md](kconfig-summary.md#menu-and-choice-blocks))
is the same idea applied to a whole `choice` block rather than a single
option.


## Non-Interactive Configuration Methods

`kconfig-conf`, the reference command-line configurator, offers several
non-interactive modes that map directly onto the module's built-in
`def`/`ask`/`reask` methods (see the Configuration Method table in
[kconfig-integration.md](kconfig-integration.md#module-variables)). Use this
mapping when translating `kconfig-conf` invocations or documentation into
`config.kconfig`/`kconfig.kconfig.*` values:

| `kconfig-conf` option | Equivalent method |
|---|---|
| `--oldconfig` | `ask` |
| `--oldaskconfig` | `reask` |
| `--olddefconfig` | `def` |
| `--alldefconfig` | `new-def` |
| `--defconfig <file>` | `new-def <file>` |

Two methods have no `kconfig-conf` equivalent: `old-def <file>` and
`[re]ask <file>`.

Since `def`, `ask`, and `reask` are built into the module, none of the above
require the `kconfig-conf` executable to be present. Reach for `kconfig-conf`
itself only through the `env` method, for example to invoke a mode the
built-in methods don't cover.


## Random and Fuzz Configuration

The `env` method can also drive `kconfig-conf`'s `--randconfig` mode, which
generates a random (but dependency-valid) configuration:

```
$ b configure config.kconfig="env kconfig-conf -s --randconfig"
kconfig build/config.kconfig.new
KCONFIG_SEED=0xD6A72753
save build/config.build
mv build/config.kconfig.new build/config.kconfig
```

`kconfig-conf` prints the seed it used. Passing that seed back as the
`KCONFIG_SEED` environment variable recreates the exact same random
configuration:

```
$ KCONFIG_SEED=0xD6A72753 \
  b configure config.kconfig="env kconfig-conf -s --randconfig"
```

`KCONFIG_ALLCONFIG` complements `--randconfig` by naming a configuration file
whose options are pinned to specific values instead of randomized, letting
you fuzz the remaining option space around a fixed baseline.

This combination is well suited to a CI loop that repeatedly reconfigures and
tests the project with a fresh random configuration each iteration:

```
$ while \
  b configure config.kconfig="env kconfig-conf -s --randconfig" && \
  b test; do :; done
```


## See Also

- [kconfig-summary.md](kconfig-summary.md) -- Kconfig language reference
- [kconfig-integration.md](kconfig-integration.md) -- build system integration, module variables, and complete example
- [build2 core modules](build2-modules-core.md)
