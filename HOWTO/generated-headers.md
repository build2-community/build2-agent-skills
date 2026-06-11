# Auto-Generated Headers

From build2 0.15.0, all headers listed as prerequisites of a library or
executable are pre-generated during the match phase before any source file
is compiled. This covers the common case automatically:

```
lib{hello}: {hxx cxx}{** -config} hxx{config}

hxx{config}: in{config}
```

See the [`in` module](../guides/build2-modules-misc.md#in-module) for `.in`
template processing.

For the vast majority of projects no manual intervention is needed. The
sections below cover corner cases and advanced control.

## Why pre-generation exists: the four mis-inclusion cases

Without pre-generation, a compiler encountering a missing header during
dependency extraction triggers build2 to generate it. This fails or produces
wrong results in four situations:

1. **Outdated header** -- compiler includes a stale generated header and
   continues preprocessing, potentially triggering `#error` guards.
2. **Wrong header** -- an in-source or forwarded build has the header in the
   source directory; the compiler picks it up before build2 generates the
   correct one in the output directory.
3. **Installed header** -- an installed copy from a system path is included
   instead of the to-be-generated one.
4. **Unrelated header** -- an identically named header from another project's
   exported include path is included.

Pre-generation (the default) avoids cases 1 and 2. Cases 3 and 4 require
the [dummy header technique](#dummy-header-technique) or a distinct inclusion
scheme (see [project structure](../guides/build2-intro-concepts.md#buildfiles-and-project-structure)).

A generated header is safe without pre-generation only when all three
conditions hold: it is not a "macro header", it is included with a name
unlikely to clash (e.g., prefixed with the project name), and it is not
installed.

## Pre-generation corner cases

### Side-effect sidestep (racy ordering)

Pre-generation of headers belonging to a library happens as a side effect of
the link rule matching that library. If the same object file can be matched
via two dependency paths, the ordering is non-deterministic:

```
# Racy: obje{common} may be matched before hxx{config} is pre-generated.
exe{hello}:   cxx{common hello} hxx{config}
exe{goodbye}: cxx{common goodbye}
hxx{config}: in{config}
```

Fix 1: add `hxx{config}` to every target that needs it:

```
exe{hello}:   cxx{common hello}   hxx{config}
exe{goodbye}: cxx{common goodbye} hxx{config}
```

Fix 2: use a [utility library](../guides/build2-modules-bin.md#libul-libue-libua-libus)
to create an explicit dependency path:

```
exe{hello}:   cxx{common hello}   libue{hello-config}
exe{goodbye}: cxx{common goodbye} libue{hello-config}

libue{hello-config}: hxx{config}
```

This also applies when only object files are built (no link rule involved):

```
obje{result}: cxx{result} libue{hello-config}
libue{hello-config}: hxx{config}
```

### Dependencies between generated headers

When a generated source/header (e.g., `moc` output) depends on another
generated header, the order of pre-generation can be undefined. Fix by
introducing a utility library to enforce ordering:

```
exe{hello}: cxx{main} {hxx cxx}{gui} libue{hello-config}

exe{hello}: cxx{moc_gui}: include = adhoc  # included by cxx{gui}
cxx{moc_gui}: hxx{gui}

libue{hello-config}: hxx{config}
hxx{config}: in{config}
```

The link rule matches `libue{hello-config}` before pre-generating
`cxx{moc_gui}`, ensuring `hxx{config}` exists first.

## Disabling pre-generation

Disable pre-generation on individual headers when they are safe (see the
three conditions above) and the pre-generation barrier is a measurable
bottleneck. Use `update = execute` to defer to the execute phase:

```
exe{hello}: cxx{main}
exe{hello}: {hxx cxx}{codepage-utf8  \
                      codepage-utf16 \
                      codepage-utf32}: update = execute
```

Measure before committing: normal (re)generation has its own costs (phase
switch contention, restarting header dependency extraction).

## Dummy header technique

Reduces the installed-header mis-inclusion case to the wrong-header case
(which build2 can remap). Maintain an empty tracked header in the source
directory that blocks the system search path:

1. Create the empty header, add it to git, then tell git to ignore local
   changes to it:

   ```
   $ git add --force version.hxx .gitignore
   $ git commit -m "Add dummy version.hxx"
   $ git update-index --assume-unchanged version.hxx
   ```

2. In the `buildfile`, disable pre-generation, distribute the dummy, and
   disable cleaning (so a cleaned state matches a distributed state):

   ```
   lib{hello}: {hxx cxx}{** -version}
   lib{hello}: hxx{version}: update = execute

   hxx{version}: in{version} $src_root/manifest
   {
     dist  = true
     clean = ($src_root != $out_root)
   }
   ```

## See Also

- [third-party-private-headers](./third-party-private-headers.md) -- generated config headers and private header sharing in third-party packaging contexts, including `include_arch` installation and capability detection via `-D` flags
