# Link-Rule Prerequisite Order

On any target the `c.link` / `cxx.link` rule actually links (`exe{}`,
`libs{}`), prerequisite order is link-line order. List object and source
prerequisites before `$libs` and any other library prerequisites.

```
import libs = libfoo%lib{foo}

exe{x}: cxx{x} $libs
```

The same order applies when sources are a name pattern:

```
exe{hello}: {hxx cxx}{**} $libs
```

Do not write the libraries first:

```
exe{x}: $libs cxx{x}   # wrong
```

## Why this fails

The link rule walks the target's prerequisites in declaration order and
appends object files and libraries to the linker command line in that same
order. It does not reorder libraries ahead of objects.

GNU ld is single-pass on static archives. If `$libs` resolves to a static
archive (`liba{}`) and that archive appears before the object that references
it, the linker drops the archive and then fails with undefined references.
Apple ld often still succeeds, so the same buildfile can work on macOS and
fail under GNU ld.

Headers, testscripts, and other non-link inputs are skipped. Only object or
source prerequisites and library prerequisites participate in link-line order.

## Split declarations

Later dependency lines append. These two forms are the same bug:

```
exe{x}: $libs cxx{x}
```

```
exe{x}: $libs
exe{x}: cxx{x}
```

Write the sources on the first line, or keep sources before libraries across
the split:

```
exe{x}: cxx{x}
exe{x}: $libs
```

## Static libraries and utility libraries

`liba{}` and `libu*{}` are also matched by `c.link` / `cxx.link`, but that
rule archives those targets (`ar` / `lib.exe`) rather than linking them.
Library prerequisites are not archive inputs. Listing `$libs` before sources
on a `liba{}` is not this failure mode.

## `*.libs` variables

`c.libs` / `cxx.libs` values (`c.libs += -lm`) are appended after all
prerequisite inputs. They are a different mechanism from `$libs` as a
prerequisite and are not this order bug.

## See Also

- [link-system-library.md](./link-system-library.md): system libraries in `*.libs`
- [link-pthread.md](./link-pthread.md): portable pthread linking
- [build2-modules-bin.md](../guides/build2-modules-bin.md): `exe{}`, `liba{}`, `libs{}`, `libu*{}`
- [build2-modules-cc.md](../guides/build2-modules-cc.md): `c.link` / `cxx.link` and `*.libs`
- [troubleshooting.md](./troubleshooting.md): GNU ld undefined-reference symptom
