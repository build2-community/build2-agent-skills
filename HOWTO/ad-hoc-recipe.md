# Ad Hoc Recipes

An ad hoc recipe is a `{{ }}` (or `%` plus `{{ }}`) block that implements
update for one target without writing a C++ rule. Use it for a one-off
generator, a custom compile line, or a tool that needs the same interface
options the `c`/`cxx` link rule would have passed.

You do not need a custom rule when an ad hoc recipe is enough. See
[write-build2-rule.md](./write-build2-rule.md).

## Attachment grammar

A recipe block may only follow a *plain* `target: prereqs` dependency
declaration (optionally after a target-specific `{ }` variable block). It
must not follow a prerequisite-specific assignment
(`target: prereq: var = value`). Mixing `include = adhoc` with a custom
recipe on the same target means the plain prerequisite line has to come
last, immediately before `{{`:

```
exe{driver}: $foo: include = adhoc
exe{driver}: cxx{driver} $libs
{{
  diag link ($>)
  $cxx.path -o $path($>) $path($<[0])
}}
```

The other order fails with `unexpected '{{'` at the recipe line.
`parse_dependency()` only looks for a recipe after a non-chained
declaration.

A target-specific variable *block* is allowed before the recipe. A
target-specific *assignment* on the same line is not:

```
# Allowed: variable block, then recipe.
exe{driver}: cxx{driver} $libs
{
  bin.rpath += $($foo: libfoo.rpath)
}
{{
  ...
}}

# Not a recipe attachment: this is a target-specific assignment.
exe{driver}: bin.rpath += $($foo: libfoo.rpath)
```

Conditional recipes need an explicit `%` header. See
[config-independent-build-graph.md](./config-independent-build-graph.md#conditional-ad-hoc-recipes).

## Impure functions and `depdb hash`

`$c.lib_poptions()`, `$cxx.lib_poptions()`, `$c.lib_libs()`,
`$cxx.lib_libs()`, `$c.lib_rpaths()`, and `$cxx.lib_rpaths()` are not
pure. In an ad hoc recipe they may only be called in the depdb preamble.
Call the function, then `depdb hash` the result immediately:

```
import libs = libhello%lib{hello}

libue{hello-meta}: $libs

obje{hello.o}: cxx{hello} libue{hello-meta}
{{
  s = $path($<[0])
  o = $path($>)

  lib_poptions = $cxx.lib_poptions(libue{hello-meta}, obje)
  depdb hash $lib_poptions

  poptions = $cxx.poptions $cc.poptions $lib_poptions
  coptions = $cc.coptions $cxx.coptions

  diag c++ ($<[0])

  $cxx.path $poptions $coptions $cxx.mode -o $o -c $s
}}
```

Calling any of them later in the recipe body fails with:

```
error: call to impure function cxx.lib_poptions is only allowed in depdb preamble
  info: consider using 'depdb' builtin to track its result changes
```

Signatures, flags, and the common-interface (`libul{}` without an output
type) form are in
[build2-functions.md](../guides/build2-functions.md#cc-and-cxx-module-functions).

The same `$cxx.lib_poptions` plus `depdb hash` pattern is what ODB uses
in `odb-examples/*/buildfile` to pass include paths to the ODB compiler,
which is a code-generation step, not a link.

## `$cxx.lib_rpaths()` is not a substitute for `bin.rpath`

`$c.lib_rpaths()` / `$cxx.lib_rpaths()` return the rpath *options* you
would pass when you are already writing the link line yourself. They are
not a way to inject rpath into a target that still uses the stock
`c.link` / `cxx.link` rule.

For a dependency you deliberately never link (`include = adhoc`,
`dlopen` only), set `bin.rpath` from an always-absolute metadata path.
See [rpath-unlinked-dependency.md](./rpath-unlinked-dependency.md).

## See Also

- [build2-functions.md](../guides/build2-functions.md#cc-and-cxx-module-functions):
  `$c.lib_*` / `$cxx.lib_*` signatures
- [config-independent-build-graph.md](./config-independent-build-graph.md):
  conditional recipes and the `%` header
- [write-build2-rule.md](./write-build2-rule.md): when a recipe is no
  longer enough
- [rpath-unlinked-dependency.md](./rpath-unlinked-dependency.md): rpath
  without linking
