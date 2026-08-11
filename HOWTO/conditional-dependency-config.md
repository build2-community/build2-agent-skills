# Package Config Variables in `bdep init -C`

When creating a build configuration with `bdep init -C`, two distinct argument
groups exist: `<cfg-args>` (before `--`) and `<pkg-args>` (after `--`). Package
config variables that control conditional `depends:` entries must go in `<pkg-args>`.
Placing them in `<cfg-args>` causes them to be silently dropped.

## Argument groups

The full form of `bdep init -C` is:

```
bdep init -C <cfg-dir> [@<cfg-name>] [<cfg-args>] [-- <pkg-args>]
```

The two groups go to different underlying commands:

- `<cfg-args>` are forwarded to `bpkg cfg-create`: toolchain variables and module
  names, such as `cc`, `config.cxx=g++`, `config.cc.coptions=-O2`.
- `<pkg-args>` are forwarded to `bpkg pkg-build`: per-package configuration
  variables, such as `config.libfoo.feature=true`, and optional dependency
  overrides such as `?sys:libz/*`.

## Conditional dependencies require pkg-args

A `depends:` entry in a package manifest can be guarded by a configuration
variable evaluated at build time:

```
depends: ? ($config.libtaskflow.cuda) libcuda
```

When `bdep init -C` is used, the dependency evaluator runs inside the newly
created configuration. For the condition to evaluate to `true`, the variable
must reach `bpkg pkg-build`, not `bpkg cfg-create`.

Correct -- variable goes after `--` and reaches `bpkg pkg-build`:

```
$ bdep init -C ../build-msvc @msvc cc config.cxx=cl.exe -- config.libtaskflow.cuda=true
```

Wrong -- variable lands in `<cfg-args>`, `bpkg cfg-create` has no schema for it
and silently drops it, and the condition evaluates to the declared default (`false`):

```
$ bdep init -C ../build-msvc @msvc cc config.cxx=cl.exe config.libtaskflow.cuda=true
```

There is no error or warning in either case. The only symptom is that the
conditional dependency is not installed.

## No cfg-args, with pkg-args

When there are no `<cfg-args>` to pass but there are `<pkg-args>`, two `--`
separators are required -- the first marks the empty `<cfg-args>` boundary and
the second separates it from `<pkg-args>`:

```
$ bdep init -C ../build-msvc @msvc cc -- -- config.libtaskflow.cuda=true
```

## Toolchain variables vs package config variables

A quick rule of thumb:

| Variable pattern | Where to pass |
|------------------|---------------|
| `config.cxx`, `config.cc.*`, `config.c.*` | `<cfg-args>` (before `--`) |
| `config.<pkg>.*` for any package other than the toolchain | `<pkg-args>` (after `--`) |

## See Also

- [`bdep-init`](../bdep/bdep-init.md) -- full `init` command reference including
  the two-`--` form
- [`bdep-argument-grouping`](../bdep/bdep-argument-grouping.md) -- argument
  grouping facility for passing per-package options
- [`bpkg-cfg-create`](../bpkg/bpkg-cfg-create.md) -- what `<cfg-args>` are
  forwarded to
- [`bpkg-pkg-build`](../bpkg/bpkg-pkg-build.md) -- what `<pkg-args>` are
  forwarded to
- [`multiple-configurations`](./multiple-configurations.md) -- managing
  debug/release/sanitize configurations with bdep
