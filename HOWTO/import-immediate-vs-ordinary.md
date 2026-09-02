# Immediate vs Ordinary Import

You need a library's metadata, or want to probe whether it is present, and
you also need to link that same library. Using `import!`/`import?` for both
purposes looks natural but breaks the link, most visibly in the installed
case.

## The rule

Immediate import (`import!`, or `import?` -- `?` is always immediate, there
is no deferred-optional form) resolves the target right at the directive,
before any consumer exists. Use it when the directive itself needs the
target:

- Querying target metadata (`[metadata]`), including from an installed
  library, where `rule_hint=c.link`/`cxx.link` is also required to reach the
  link rule's installed search.
- Probing optional presence (`import?`, compared against `[null]`).
- Importing an executable used as a build tool (`PATH` search, metadata).

Ordinary, deferred `import` (no `!`/`?`) resolves later, when the target
that consumes the result (`exe{}`/`lib{}`) is matched. Use it for anything
that becomes a link prerequisite: `libs`, `intf_libs`, `impl_libs`. Let the
consumer's match drive installed search, implementation dependencies, and
rpath -- see
[build2-modules-cc.md](../guides/build2-modules-cc.md#importation-of-installed-libraries).

Do not assign the immediate import to `libs` (or `impl_libs`/`intf_libs`)
and then list that variable as a prerequisite of a linked target. Keep the
immediate result in its own variable. If the library also needs linking,
issue a second, ordinary `import` into `libs`:

```
import? [metadata, rule_hint=cxx.link] lh = libhello%lib{hello}

libs =
if ($lh != [null])
  import libs = libhello%lib{hello}

exe{driver}: c{driver} $libs
```

## Worked example: an optional static member

A common shape is probing an optional member that may not exist on every
platform (for example a static archive not built on Windows), then linking
it only when it does and some condition on its metadata holds:

```
import? [metadata, rule_hint=c.link] liba = libfoo%liba{foo}

enable = [bool] false
if ($liba != [null])
  enable = $($liba: libfoo.some_flag)

libs =
if $enable
  import libs = libfoo%liba{foo}

./: exe{driver}: include = $enable
exe{driver}: c{driver} $libs
```

`c.link` vs `cxx.link` is picked to match the consumer language. The
optional immediate import resolves cleanly to `null` when the member is
absent; the ordinary import only runs once `enable` confirms the member is
both present and wanted.

## Why linking the immediate target breaks in the installed case

In-tree (amalgamation or `config.import.*`), linking the immediate target
directly often still appears to work, because the export stub returns the
real `lib{}`/`liba{}` with its `$impl_libs` already attached. The installed
case has no export stub: the link rule never runs for an immediate import
(unless nominated via `rule_hint`, and even then it runs without a
consumer), so the library's own implementation dependencies arrive, if at
all, as raw linker flags instead of imported targets, and the consumer gets
no rpath entry for them. A static consumer of an installed library that
itself has implementation dependencies can then fail at runtime with an
unresolved shared library, even though the library's own buildfile already
lists that dependency in `impl_libs`. Re-importing the missing dependency in
the consumer is the wrong fix -- the ordinary `import` above, which lets the
link rule run against the real consumer, is.

## Related pitfall: importing two members of the same installed library

Importing two members of the same installed library (for example both
`liba{}` and `libs{}`, or `lib{}` alongside either) from one project can
trip an assertion in the pkg-config loader:
[build2 issue #561](https://github.com/build2/build2/issues/561). The issue
is open and the root cause beyond the assert site is not yet confirmed. If a
consumer needs a specific member, prefer importing that member consistently
rather than also importing a different member of the same library elsewhere
in the same project.

## See Also

- [build2-projects-advanced.md](../guides/build2-projects-advanced.md#immediate-import-import-and-import) -- `import!`/`import?` mechanics, the `metadata` and `rule_hint` attributes
- [target-metadata.md](./target-metadata.md#importing-with-metadata) -- the metadata protocol and the `lh` query pattern this recipe builds on
- [build2-modules-cc.md](../guides/build2-modules-cc.md#importation-of-installed-libraries) -- the link rule's installed-library search that ordinary import relies on
- [packaging-guide-testing.md](../guides/packaging-guide-testing.md#step-9-test-the-package) -- the installed test is what exercises this split
