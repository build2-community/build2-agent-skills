# Nested fsdir{} Parent Chains

The built-in `fsdir{}` rule auto-creates parent directories only when the
target directory is not under the project's `src_path()`. Out-of-tree that
cascade is `mkdir -p`. In-source it is not. Only an explicitly declared
`fsdir{}` prerequisite is honored.

This is verified against
`.submodules/build2/libbuild2/algorithm.cxx`
(`inject_fsdir_impl`) and `libbuild2/rule.cxx` (`fsdir_rule::apply`).

## The rule

`fsdir_rule::apply()` calls `inject_fsdir()` on the `fsdir{}` target itself.
That walks one directory level at a time, stopping at the project boundary.

The auto-inject branch is taken only when:

```
rs != nullptr && !d.sub (rs->src_path ())
```

That is true for the whole output tree in a forwarded out-of-source config
(`out_base != src_base`). A single deepest-level `fsdir{}` prerequisite is
then enough. Ancestors are created automatically.

In an in-source build (`out_base == src_base`) every directory is under
`src_path()`, so the auto-inject branch is never taken. Missing intermediate
levels fail with:

```
error: unable to create directory <path>: no such file or directory
```

An in-source build is exactly what `b dist` then `configure` then `update`
of the unpacked archive produces, and what the cppget.org queue runs.

## Why this is intentional

The comment above the guard states the intent: if there is no root scope, or
the directory is in `src_root`, inject nothing unless it was requested
explicitly.

An in-source build is modeled as `out_root == src_root`, not as a separate
code path. `doc/manual.cli` calls this parallel out/src structure a
cornerstone design decision. Once out and src coincide, build2 cannot tell a
directory that already exists because it mirrors source content from a
synthetic directory that has never existed. The guard is the direct
consequence of that model, not a defect.

The same out vs src test appears elsewhere as
`clean = ($src_root != $out_root)` (see
[generated-headers.md](./generated-headers.md)).

## Recipe: out-of-tree vs in-source

A target that writes into a nested directory that does not exist in src:

```
file{bundle/Contents/icd.d/icd.json}: fsdir{bundle/Contents/icd.d/}
```

**Out-of-tree (forwarded `@config`).** That single deepest `fsdir{}` is
enough. `inject_fsdir()` creates `bundle/Contents/` and `bundle/` on the way
up.

**In-source (`dist` then `configure` then `update`).** Every missing level
needs its own `fsdir{}`-to-`fsdir{}` prerequisite:

```
file{bundle/Contents/icd.d/icd.json}: fsdir{bundle/Contents/icd.d/}

fsdir{bundle/Contents/icd.d/}: fsdir{bundle/Contents/}
fsdir{bundle/Contents/}:      fsdir{bundle/}
```

`inject_fsdir_impl()` looks through the target's own prerequisites for an
`fsdir{}` whose directory is the parent. Listing the parent on the child is
what makes the chain load-bearing in-source. The project root already exists,
so `fsdir{bundle/}` needs no parent of its own.

Write the in-source chain. It is correct out-of-tree as well (the extra
prerequisites are then redundant, not wrong). Do not delete it after a
forwarded dev config stays green.

## Spelling

`fsdir{a/b/c/}` (path inside the braces) and `a/b/c/fsdir{}` (directory
prefix outside the braces) identify the same target. They behave the same
for this in-source case.

## How this hides in a forwarded config

A forwarded out-of-source config is exactly where auto-inject masks a
missing chain. `bdep test` staying green is not evidence the chain is
complete.

The check that matters for publish is the in-source dist cycle in
[packaging-guide-testing.md](../guides/packaging-guide-testing.md):

```
$ b dist config.dist.root=/tmp/dist config.dist.uncommitted=true
$ cd /tmp/dist/<package>-<version>/
$ b configure
$ b update
```

## See Also

- [test-runtime-fixtures.md](./test-runtime-fixtures.md): NEWS `fsdir{}`
  directory-symlink recipe used as a test-data fixture (a different
  `fsdir{}` topic)
- [packaging-guide-testing.md](../guides/packaging-guide-testing.md): the
  in-source dist cycle that surfaces a missing chain
- [generated-headers.md](./generated-headers.md): `clean = ($src_root !=
  $out_root)` as the same out vs src model
- [troubleshooting.md](./troubleshooting.md): `unable to create directory`
  when an intermediate `fsdir{}` is missing in-source
- [build2-targets-variables.md](../guides/build2-targets-variables.md):
  `fsdir{}` in the core target type table
