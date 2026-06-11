# Optional Library Components

## Prefer unconditional inclusion

If a component is not large and has no additional dependencies, include it
unconditionally. The static linker drops unused components automatically when
they are in separate translation units, and shared library users avoid
incompatibility issues from mismatched build options.

## Separate library (preferred)

If the component requires additional dependencies, factor it into a separate
library (and if those dependencies are significant, a separate package). This
keeps the main library's dependency footprint small and composes cleanly with
shared libraries. If this feels like overkill, that is a signal that the
component belongs in the main library unconditionally.

## Configuration variables (last resort)

When factoring into a separate library is not possible (e.g., when packaging
a third-party project), use
[configuration variables](../guides/build2-project-config.md#declaring-configuration-variables)
to gate optional components:

- Declare a `bool` config variable per component with a `false` default.
- Use it in the `buildfile` to include/exclude translation units.
- Make additional dependencies conditional on the variable being `true` via
  the [`depends` manifest field](../bpkg/bpkg-manifest-reference.md#dependency-fields).
- Convey the enabled features as library metadata so consumers can query them.
  See [target-metadata](./target-metadata.md).

The same `config` variable approach can also create a "single package,
multiple libraries" arrangement -- see `libasio` and `libevent` on
`cppget.org` for real examples.

## See Also

- [build2 core modules: config](../guides/build2-modules-core.md) -- config variables and persistence
- [build2-modules-bin.md](../guides/build2-modules-bin.md) -- lib/liba/libs target types
- [target-metadata.md](./target-metadata.md)
