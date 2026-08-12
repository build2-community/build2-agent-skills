# Require a Dependency Feature

When this package needs a boolean feature of a dependency turned on, write a
multi-line `depends` with `require` alone. That includes a sibling in the
same repository.

`require` and `reflect` are not a pair. A `depends` alternative is `require`
or `prefer`/`accept`, and optionally `reflect` after that.


## What each clause does

| Clause | What it sets | When to use it |
|---|---|---|
| `require { ... }` | The *dependency's* `bool` config vars to `true` | This package needs that feature on |
| `prefer` / `accept` | The dependency's config, with negotiation | Non-bool values, or a preference that others may override |
| `reflect { ... }` | *This* package's own `config.*` vars | A later `depends` or this package's buildfile must read the negotiated value |

Do not add `reflect` just because `require` is present.


## Common case: require alone

```
depends:
\
liblodepng == $
{
  require
  {
    config.liblodepng.cpp = true
  }
}
\
```

This asks `bpkg` to configure the dependency with that bool set. After
`bdep sync` or `bdep init`, the configuration report shows
`config.liblodepng.cpp=true` as set by this package.

The same clause works for an external dependency. Swap `== $` for a version
constraint such as `^0.1.0`.

`require` is a shortcut for `prefer`/`accept` when the only goal is to set
`bool` vars to `true`.


## When to add reflect

Add `reflect` only if this package must see the negotiated value itself:

- a later `depends: ... ? ($config.this.x)`
- a condition or option in this package's own buildfile

```
depends:
\
libfoo ^1.0.0
{
  require
  {
    config.libfoo.x = true
  }

  reflect
  {
    config.hello.libfoo_x = $config.libfoo.x
  }
}
\
```

If this package never reads `config.hello.libfoo_x`, omit `reflect`.


## See Also

- [bpkg-manifest-reference](../bpkg/bpkg-manifest-reference.md): `depends` clause syntax
- [bpkg-dependency-negotiation](../bpkg/bpkg-dependency-negotiation.md): `prefer`/`accept` and the negotiation loop
- [packaging-guide-summary](../guides/packaging-guide-summary.md): Step 6, adding dependencies
- [optional-library-components](./optional-library-components.md): declaring *your* optional feature
- [conditional-dependency-config](./conditional-dependency-config.md): passing `config.<pkg>.*` on `bdep init -C`
