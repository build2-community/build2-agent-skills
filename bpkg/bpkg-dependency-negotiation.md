# bpkg Dependency Configuration Negotiation

## Overview

When a dependent package specifies how a dependency should be configured, and
multiple such dependents exist in the same build, `bpkg` must arrive at a
single configuration acceptable to all of them. This process is called
dependency configuration negotiation.

Configuration preferences and requirements are expressed as clauses inside the
multi-line form of the `depends` (direct dependency) or `constrains` (indirect
dependency) manifest fields.


## The Problem

Consider two packages, `hello` and `world`, both depending on `libfoo`. Each
may want different configuration options:

- `hello` needs `config.libfoo.buffer >= 4096` and prefers caching enabled.
- `world` needs `config.libfoo.buffer >= 8192`.

Because `libfoo` is built only once in a configuration, the two sets of
requirements must be reconciled. If they are incompatible, the build fails.


## How Negotiation Works

Negotiation is a cooperative-refinement loop:

1. `bpkg` evaluates each dependent's `prefer` clause, which sets configuration
   variables on the dependency to the values preferred by that dependent.
2. Whenever a `prefer` clause changes any variable, all other dependents'
   `prefer` clauses are re-evaluated against the updated values.
3. The loop continues until one of these outcomes:
   - **Success:** No clause changes any value in a round. All `accept`
     conditions evaluate to `true`.
   - **Failure:** An `accept` condition returns `false` after negotiation
     converges.
   - **Failure:** The process oscillates between two or more configurations
     ("yo-yoing").

After the `prefer` round, every dependent's `accept` condition is evaluated
against the final configuration. If any returns `false`, the build fails.

Before each re-evaluation of a `prefer` clause, variables that were **first
set to their current values by this dependent** are reset to their defaults.
This lets a dependent change its mind in response to changes made by others.


## Writing Cooperative prefer Clauses

Dependents are expected to cooperate by not overriding values that are already
"better" than what they require.

**Non-cooperative (avoid unless an exact value is required):**

```
prefer
{
  config.libfoo.buffer = 4096
}
```

This always forces the buffer to exactly 4096, overriding any higher value
another dependent set.

**Cooperative (preferred pattern):**

```
prefer
{
  config.libfoo.buffer = ($config.libfoo.buffer < 4096 \
                          ? 4096                       \
                          : $config.libfoo.buffer)
}

accept ($config.libfoo.buffer >= 4096)
```

This raises the buffer to the minimum required but respects larger values set
by other dependents.

Setting a variable to the maximum possible value (e.g., `true` for a boolean
feature) is inherently cooperative and needs no guard.

**Important:** a dependent must always re-assign the variable even if the
current value already satisfies it. Leaving the variable untouched means
`bpkg` does not know this dependent is relying on it. The following is
incorrect:

```
prefer
{
  if ($config.libfoo.buffer < 4096)   # Incorrect.
    config.libfoo.buffer = 4096
}
```


## Configuration Variable Origin

The `$config.origin()` function returns the origin of a variable's current
value:

| Return value | Meaning |
|--------------|---------|
| `undefined` | Variable has no value and no default. |
| `default` | Value comes from the `config` directive default in `root.build`. |
| `buildfile` | Value comes from `config.build` or another buildfile. |
| `override` | Value is a command-line override (user configuration). |

This is useful for changing only the default while respecting explicit user
configuration:

```
prefer
{
  config.libfoo.buffer = (                             \
    $config.origin(config.libfoo.buffer) == 'default'  \
    ? 4096                                             \
    : $config.libfoo.buffer)
}
```


## The constrains Field

The `constrains` field applies version constraints and/or configuration to an
**indirect** dependency -- a package in the dependency tree that the declaring
package does not depend on directly. This is useful when a package "knows"
what indirect dependency will be selected and needs to tighten requirements.

```
constrains: [*] <dependency> [? <enable-cond>] [<reflect-var>]
```

The constraint is active **only if** the named package is part of the resolved
dependency tree. It is ignored if the package is not selected. Example:

```
name: libfoo
depends: libmariadb >= 10.0.0 | libmysqlclient

name: libbar
depends: libfoo
constrains: libmariadb >= 11.0.0 config.libbar.mariadb=true
```

Here `libbar` tightens the `libmariadb` version and reflects that it is being
used -- but only if `libmariadb` was actually chosen as the dependency for
`libfoo`. If `libmysqlclient` was chosen instead, the `constrains` has no
effect even if `libmariadb` is present in the configuration for another reason.

The `constrains` field supports the same `enable`, `require`,
`prefer`/`accept`, and `reflect` clauses as `depends`. `constrains` values
must follow all `depends` values in the manifest.


## Examples

### Require a boolean feature to be enabled

```
depends:
\
libmariadb ^10.2.2
{
  require
  {
    config.libmariadb.cache = true
  }
}
\
```

`require` is a shortcut for `prefer`/`accept` when only setting `bool` vars to
`true`. It allows `bpkg` to apply additional optimizations.

### Prefer X but accept X or Y

For a configuration variable representing a mutually exclusive choice:

```
libfoo ^1.0.0
{
  prefer
  {
    config.libfoo.ui = (                                         \
      $config.origin(config.libfoo.ui) == 'default' ||           \
      ($config.libfoo.ui != 'gui' && $config.libfoo.ui != 'cli') \
      ? 'gui'                                                    \
      : $config.libfoo.ui)
  }

  accept ($config.libfoo.ui == 'gui' || $config.libfoo.ui == 'cli')
}
```

This prefers `gui`, keeps `cli` if already set, and rejects `none`.

### Use a feature only if someone else enables it

```
libfoo ^1.0.0
{
  prefer
  {
  }

  accept (true)

  reflect
  {
    config.hello.libfoo_x = $config.libfoo.x
  }
}
```

An empty `prefer` with `accept (true)` observes the value without influencing
it. The `reflect` clause captures it for use in the package's own buildfiles.

### Disable a default-enabled feature if this package is the sole user

```
libfoo ^1.0.0
{
  prefer
  {
    if ($config.origin(config.libfoo.x) == 'default')
      config.libfoo.x = false
  }

  accept (true)
}
```

This disables the feature only when it still has its default value -- meaning
no other dependent has requested it.

### Configuration-dependent minimum, with reflect

```
libfoo ^1.0.0
{
  prefer
  {
    min_buffer = ($config.libfoo.cache ? 8192 : 4096)
    config.libfoo.buffer = ($config.libfoo.buffer < $min_buffer \
                            ? $min_buffer                       \
                            : $config.libfoo.buffer)
  }

  accept ($config.libfoo.buffer >= ($config.libfoo.cache ? 8192 : 4096))

  reflect
  {
    config.hello.buffer = $config.libfoo.buffer
  }
}
```

The reset-to-defaults behavior ensures that if `config.libfoo.cache` changes
from `true` to `false` in a re-evaluation round, the buffer requirement drops
back to 4096 rather than being held at 8192.

### Saving an uninfluenced variable across depends values

Config variables set in `prefer` are visible in subsequent `depends` values of
the same dependent. Variables that were not set are only visible until the
immediately following `reflect`. To use an uninfluenced variable in a later
`depends` value, save it in `reflect`:

```
depends:
\
libfoo ^1.0.0
{
  prefer
  {
  }

  accept (true)

  reflect
  {
    config.hello.libfoo_cache = $config.libfoo.cache
  }
}
\

depends: libbar ^1.0.0 ? ($config.hello.libfoo_cache)
```


## See Also

- [bpkg README](README.md)
- [bpkg-pkg-build](bpkg-pkg-build.md)
