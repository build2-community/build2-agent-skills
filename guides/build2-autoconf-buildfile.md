# libbuild2-autoconf -- Buildfile Integration

Check results are defined as preprocessor macros and are normally consumed
in C/C++ source. To make a value available as a `buildfile` variable (e.g.,
to select source files or set compiler options), combine two build2
mechanisms:

- The [`c.predefs`][predefs] submodule, which compiles a header and
  extracts its macro values into a `buildfile` fragment or JSON file.
- The [`update` directive][update-directive], which updates a target while
  loading a `buildfile`.

See [libbuild2-autoconf module reference](build2-modules-autoconf.md) for
how checks are produced in the first place.

---

## Example: Select Source Files by Endianness

This example derives a `little_endian` boolean buildfile variable from the
`BYTE_ORDER` check and uses it to include only the appropriate source file.

### Step 1 -- Template for the intermediate header

Create `byte-order.h.in`. It produces the autoconf-generated `BYTE_ORDER`
value and converts it to a plain boolean that `c.predefs` can extract:

```
/* byte-order.h.in */

#undef BYTE_ORDER

#if BYTE_ORDER == LITTLE_ENDIAN
#  define BYTE_ORDER_LITTLE_ENDIAN true
#elif BYTE_ORDER == BIG_ENDIAN
#  define BYTE_ORDER_LITTLE_ENDIAN false
#else
#  error unexpected byte order
#endif
```

### Step 2 -- Load the `c.predefs` submodule

In `build/root.build`, load `c.predefs` after the C compiler module:

```
using c
using c.predefs
```

### Step 3 -- Drive the extraction from the buildfile

At the top of the `buildfile` where the result is needed, before any
target that depends on `little_endian`:

```
using autoconf

h{byte-order}: in{byte-order}

[rule_hint=c.predefs] buildfile{byte-order}: h{byte-order}
{
  c.predefs.poptions = false
  c.predefs.macros   = BYTE_ORDER_LITTLE_ENDIAN@little_endian
}

./: buildfile{byte-order}

if ($build.meta_operation == 'perform')
{
  update buildfile{byte-order}
  source $path(buildfile{byte-order})
}
else
  little_endian = false
```

Key points:

- `[rule_hint=c.predefs]` selects the predefs rule for `buildfile{byte-order}`.
- `c.predefs.poptions = false` suppresses project `poptions` so only the
  generated header is compiled.
- `c.predefs.macros` maps the macro name to the buildfile variable name.
- The `if ($build.meta_operation == 'perform')` guard provides a safe
  fallback for non-`perform` operations (e.g., `configure`, `dist`) where
  the header cannot be compiled.
- `./: buildfile{byte-order}` ensures the generated `buildfile` is cleaned.

### Step 4 -- Use the variable

After the extraction fragment, `little_endian` is a normal buildfile variable:

```
exe{hello}: cxx{hello-big}:    include = (!$little_endian)
exe{hello}: cxx{hello-little}: include = $little_endian
```

---

## See Also

- [libbuild2-autoconf module reference](build2-modules-autoconf.md) -- flavors, variables, builtin checks, custom substitutions
- [Project-specific checks](build2-autoconf-project-checks.md) -- authoring checks in `build/autoconf/checks/`

[predefs]: https://build2.org/stage/build2/doc/build2-build-system-manual.xhtml#c-predefs
[update-directive]: https://build2.org/stage/build2/doc/build2-build-system-manual.xhtml#directives-update
