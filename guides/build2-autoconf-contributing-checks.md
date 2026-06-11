# libbuild2-autoconf -- Contributing Builtin Checks

This document describes the requirements and stylistic guidelines for
contributing a check to the builtin catalog in
`libbuild2/autoconf/checks/`. These rules are in addition to the
correctness requirements described in
[Project-Specific Checks](build2-autoconf-project-checks.md), which
covers the check file format.

---

## Is This Check Suitable for the Builtin Catalog?

The key criterion is whether multiple unrelated projects are likely to use
the same check. A check is a strong candidate for the builtin catalog when
at least one of the following holds:

- Other projects already use the same check (search for the check name and
  plausible alternative spellings).
- The feature is available on more than one of the three main reference
  platforms: Linux/glibc, Windows (MSVC and MinGW), and Mac OS.

Keep the check in a project catalog if **both** of the following are true:

1. No other project appears to use it.
2. The feature is available on only one platform and is unlikely to spread
   (for example, an idiosyncratic Mac OS-only API with no POSIX or Windows
   counterpart).

When unsure, add the check to your project catalog first. Use it on CI,
stabilise the implementation, then propose it for the builtin catalog.

---

## Stylistic Guidelines

The following guidelines are required for all builtin contributions. They
exist to keep the catalog consistent and maintainable. The complete example
at the end of this section illustrates most of them together.

### 1. Verify uniqueness by content, not just name

Before adding a check, search the contents of the existing checks for a
component of the name unlikely to vary (e.g., `strlcpy` rather than
`HAVE_STRLCPY`). The same feature may already be present under a different
canonical name. Adding a project check because the existing builtin has a
different name is not acceptable; use `autoconf.aliases` instead.

### 2. Use C-style comments for content copied to `config.h`

All comments that will appear in the generated `config.h` must be
C-style (`/* ... */`). Use C++-style comments (`//`) only for metadata
that must not appear in the output, such as TODO notes and consistency
reminders:

```
// TODO: available in glibc since 2.38.
// NOTE: keep consistent with HAVE_STRLCAT.

/* Check for the strlcpy() function. ... */
```

### 3. Use proper sentences in all comments

Every sentence must start with a capital letter and end with a period.
This applies to both C-style and C++-style comment lines.

### 4. Use the canonical check name

Use the canonical name for the entity being checked, regardless of what
name your project uses. If your project uses a different name, map it with
`autoconf.aliases` rather than introducing a non-canonical entry.

| Entity | Name pattern | Example |
|---|---|---|
| Header `<sys/stat.h>` | `HAVE_<path_with_underscores>_H` | `HAVE_SYS_STAT_H` |
| Function `strlcpy()` | `HAVE_<name>` | `HAVE_STRLCPY` |
| Macro `__builtin_expect` | `HAVE_<name>` | `HAVE___BUILTIN_EXPECT` |
| Struct `stat` | `HAVE_STRUCT_<name>` | `HAVE_STRUCT_STAT` |
| Struct member `st_mtim.tv_nsec` | `HAVE_STRUCT_<name>_<member>` | `HAVE_STRUCT_STAT_ST_MTIM_TV_NSEC` |
| Instruction set | `HAVE_<name>` | `HAVE_SSE4_2` |

Include leading underscores when they are part of the entity name. For
example, `__bswap_32()` becomes `HAVE___BSWAP_32`.

### 5. Open the comment block with a standard description line

The first line of the main C-style comment must describe what the check
is for, using the standard phrasing below:

```
/* Check for the <sys/stat.h> header. */
/* Check for the strlcpy() function. */
/* Check for the stat struct. */
/* Check for the st_mtim.tv_nsec data member in the stat struct. */
```

For less well-known entities, add a brief explanatory sentence after the
standard opening:

```
/* Check for the availability of the kCMVideoCodecType_VP9 constant.
 * VP9 is an open-source video codec developed by Google.
 */
```

### 6. Document platform availability, including explicit absences

The comment must state on which platforms (and minimum versions) the
feature is present, and must call out explicitly when absent from any of
the three main reference platforms: **Linux/glibc**, **Windows (including
MinGW)**, and **Mac OS**.

```
/* Check for the addrinfo struct.
 *
 * Available since Linux/glibc 2.4, OpenBSD 2.9, FreeBSD 3.5, NetBSD 1.5,
 * and Mac OS (exact version is unclear but for a while now). Not available
 * on Windows including MinGW.
 */
```

This narrative is required even when the implementation seems
self-explanatory, because it distinguishes an incorrect assumption from
an incorrect implementation when a bug needs to be diagnosed.

Use the following standard phrasing for Windows availability:

```
Not available on Windows including MinGW.
Not available on Windows except MinGW.
Available on Windows including MinGW.
Available on Windows except MinGW.
```

### 7. Avoid redundant macro guards

The most common redundancy is testing both `_WIN32` and `__MINGW32__`:

```
/* Incorrect: __MINGW32__ implies _WIN32. */
#if defined(_WIN32) || defined(__MINGW32__)

/* Correct. */
#if defined(_WIN32)
```

`__MINGW32__` is always defined when `_WIN32` is defined on a MinGW
toolchain. Only add `__MINGW32__` when you specifically need to distinguish
MinGW from MSVC.

### 8. Do not use one check to implement another

Checks must not test for the result of a sibling check. The only
permitted cross-check dependency is through the `BASE` mechanism
(`: BUILD2_AUTOCONF_LIBC_VERSION` or similar). Implementing a check
by querying `#ifdef HAVE_STRLCPY` is incorrect:

```
/* Incorrect. */
// HAVE_STRLCAT: HAVE_STRLCPY
#undef HAVE_STRLCAT
#ifdef HAVE_STRLCPY
#  define HAVE_STRLCAT 1
#endif
```

Instead, duplicate the platform conditions and add a consistency note:

```
/* Correct. */
// NOTE: keep consistent with HAVE_STRLCPY.
#undef HAVE_STRLCAT
#if defined(__FreeBSD__) || ...
#  define HAVE_STRLCAT 1
#endif
```

### 9. Ensure every relied-upon macro is reachable

If the check tests a macro that is not predefined by the compiler, include
the header that defines it. If it is compiler-predefined, document under
which conditions (e.g., which compiler options or target). Do not silently
depend on a macro being defined by an unrelated earlier include.

---

## Complete Example

```
// HAVE_STRLCPY

#undef HAVE_STRLCPY

// TODO: available in glibc since 2.38.

// NOTE: keep consistent with HAVE_STRLCAT.

/* Check for the strlcpy() function.
 *
 * Available in BSDs and Mac OS since the beginning. Not available
 * on Windows including MinGW or Linux/glibc.
 */
#if defined(__FreeBSD__) || \
    defined(__OpenBSD__) || \
    defined(__NetBSD__)  || \
    defined(__APPLE__)
#  define HAVE_STRLCPY 1
#endif
```

---

## Submitting a Pull Request

When submitting checks to the upstream repository:

- Squash all new checks into a single commit regardless of how many are
  being added.
- Use the subject `Add N common checks` where `N` is the number of new
  checks.
- List each added check name on its own line in the commit body:

```
Add 3 common checks

HAVE_ACCESS
HAVE_FILENO
HAVE_STRLCPY
```

Patch submissions (via email) follow the same convention.

---

## See Also

- [Project-specific checks](build2-autoconf-project-checks.md) -- check file format, BASE checks, conditional pitfalls
- [libbuild2-autoconf module reference](build2-modules-autoconf.md) -- flavors, variables, aliases, prefixing
- [Builtin checks catalog](https://github.com/build2/libbuild2-autoconf/tree/master/libbuild2-autoconf/libbuild2/autoconf/checks/)
