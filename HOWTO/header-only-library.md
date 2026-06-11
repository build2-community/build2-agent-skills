# Header-Only (Binless) Libraries

In build2 a header-only library is a _binless_ static or shared library -- not
a separate kind of target. See
[`lib{}`, `liba{}`, `libs{}`](../guides/build2-modules-bin.md#lib-liba-libs)
for the full type hierarchy.

A library becomes binless when it has no source file prerequisites:

```
lib{hello}: hxx{hello}
```

Create a new binless library with [`bdep-new`](../bdep/bdep-new.md#lib---library-project):

```
$ bdep new -l c++ -t lib,binless libhello
```

## System library dependencies

Binless libraries that depend on a system library (e.g., `-lm` or
[`-pthread`](./link-pthread.md)) must list it in both `*.export.libs` *and*
`*.libs`. The `*.libs` entry is needed when linking the static variant of
the binless library. See [library projects](../guides/build2-projects-advanced.md#library-projects)
for background on export vs build-time dependencies:

```
lib{hello}: hxx{hello}

if ($cxx.target.class != 'windows')
{
  cxx.libs += -lm
  lib{hello}: cxx.export.libs = -lm
}
```

## Metadata libraries

A _metadata library_ has no sources or headers and exists only to export a
dependency on platform-specific system libraries. By convention its name is
the original library name with `-meta` appended:

```
[rule_hint=c] lib{pthread-meta}:

c.libs = -pthread
lib{pthread-meta}: c.export.libs = -pthread
```

The `rule_hint` attribute is required because without sources or headers
build2 cannot infer which rule to use.

## See Also

- [build2-modules-bin.md](../guides/build2-modules-bin.md) -- lib, liba, libs target types
- [link-system-library.md](./link-system-library.md) -- linking system libraries in export options
- [packaging-guide-summary.md](../guides/packaging-guide-summary.md)
