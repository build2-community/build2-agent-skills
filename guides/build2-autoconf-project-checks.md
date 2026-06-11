# libbuild2-autoconf -- Project-Specific Checks

Projects can supplement the builtin check catalog with their own checks
placed in `build/autoconf/checks/`. The format is identical to the builtin
catalog, so checks can be promoted upstream without modification.

See [libbuild2-autoconf module reference](build2-modules-autoconf.md) for
how checks are selected during substitution and how the catalogs relate.

---

## Check File Format

Create a `<NAME>.h` file in `build/autoconf/checks/` (preserving case).

The first line must be:

```
// <NAME>[!] [: <BASE>...]
```

- `!` marks the check as *unprefixable*: it is never prefixed even when
  `autoconf.prefix` is set. Use this for names that are standard macro
  names (e.g., `BYTE_ORDER`) that system headers may already define.
- `: BASE...` lists space-separated base checks to insert before this
  check's lines in the output. Bases are deduplicated across the file.

Subsequent lines are C-style comments or preprocessor directives that
`#define` or `#undef` `<NAME>`. C++-style comments (including the first
line) are stripped from the output. No double-quotes or backslashes except
for line continuations.

### Minimal example

```
// HAVE_BAR

#undef HAVE_BAR

/* No bar on Windows except with MinGW. */
#if !defined(_WIN32) || defined(__MINGW32__)
#  define HAVE_BAR 1
#endif
```

### Example using `BUILD2_AUTOCONF_LIBC_VERSION` helpers

When a check needs to test platform versions, declare
`BUILD2_AUTOCONF_LIBC_VERSION` as a base and assert it is present:

```
// HAVE_BAR : BUILD2_AUTOCONF_LIBC_VERSION

#ifndef BUILD2_AUTOCONF_LIBC_VERSION
#  error BUILD2_AUTOCONF_LIBC_VERSION appears to be conditionally included
#endif

/* Check for the bar() function.
 *
 * Available on Linux/glibc since 2.17, FreeBSD 11.0, and Mac OS 10.9.
 * Not available on Windows including MinGW.
 */
#undef HAVE_BAR

#if BUILD2_AUTOCONF_GLIBC_PREREQ(2, 17)   || \
    BUILD2_AUTOCONF_FREEBSD_PREREQ(11, 0) || \
    defined(BUILD2_AUTOCONF_MACOS)
#  define HAVE_BAR 1
#endif
```

---

## Catalog Precedence and Warnings

Project checks take precedence over builtin checks with the same name.
The module warns when this occurs to help identify when a project check
can be dropped (e.g., after an upstream fix lands in the builtin catalog).

Valid reasons to keep a project check with the same name as a builtin:

1. Testing a check on CI before proposing it upstream.
2. Shipping a release before waiting for an `autoconf` module release.
3. Overriding a broken builtin with a local fix.
4. A check that is private to the project and unlikely to be generally
   useful.

For private checks (case 4), embed the project name to avoid future name
clashes, since project check names could conflict with future builtin base
checks:

```
// HAVE_MYPROJECT_SPECIAL_FEATURE
```

Use `autoconf.aliases` to keep the original name in the output:

```
h{config}: in{config}
{
  autoconf.aliases = HAVE_SPECIAL_FEATURE@HAVE_MYPROJECT_SPECIAL_FEATURE
}
```

---

## Conditional Checks and Duplicate Suppression

The module deduplicates base checks within a file. This interacts badly
with checks that are conditionally present at the preprocessor level.

**Incorrect** -- conditional substitution causes the shared base to be
omitted on the guarded path:

```
#ifndef _WIN32
#  undef HAVE_EXPLICIT_BZERO
#endif
#undef HAVE_EXPLICIT_MEMSET
```

**Correct** -- place all substitutions unconditionally and adjust results
in user code afterward:

```
#undef HAVE_EXPLICIT_BZERO
#undef HAVE_EXPLICIT_MEMSET

#ifdef _WIN32
#  undef HAVE_EXPLICIT_BZERO
#endif
```

---

## Canonical Naming for Builtin Contributions

When writing a check intended for the builtin catalog, use canonical names:

| Entity | Name pattern | Example |
|---|---|---|
| Header | `HAVE_<path_with_underscores>_H` | `HAVE_SYS_STAT_H` |
| Function or macro | `HAVE_<name>` | `HAVE_STRLCPY` |
| Struct | `HAVE_STRUCT_<name>` | `HAVE_STRUCT_STAT` |
| Struct member | `HAVE_STRUCT_<name>_<member>` | `HAVE_STRUCT_STAT_ST_MTIM_TV_NSEC` |
| Type/other | `HAVE_<name>` or just `<name>` | `HAVE_SSE4_2`, `ssize_t` |

Include the leading underscores when they are part of the name
(e.g., `__bswap_32` becomes `HAVE___BSWAP_32`).

Describe what the check is for and on which platforms the feature is
present, including explicit mention when absent from Linux/glibc, Windows
(including MinGW), or Mac OS. This allows future maintainers to distinguish
an incorrect assumption from an incorrect implementation.

---

## See Also

- [libbuild2-autoconf module reference](build2-modules-autoconf.md) -- flavors, variables, builtin checks, custom substitutions
- [Buildfile integration](build2-autoconf-buildfile.md) -- communicating check results to buildfiles
- [Builtin checks catalog](https://github.com/build2/libbuild2-autoconf/tree/master/libbuild2-autoconf/libbuild2/autoconf/checks/)
