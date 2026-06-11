# libbuild2-autoconf -- Autoconf Emulation Module Reference

The `autoconf` module processes `config.h.in`-style template files by
expanding named configuration checks into preprocessor definitions. It
supports three input flavors (Autoconf, CMake, and Meson), provides a
catalog of ~360 builtin platform/compiler checks, and allows projects to
add their own.

Unlike traditional Autoconf, checks are resolved by static
platform/compiler macro inspection rather than by trying to compile a test
program. This makes the module fast, reproducible, and cross-compilation
safe. See [Project Configuration][proj-config] for the rationale behind
this expectation-based approach.

The module is part of the standard pre-installed `build2` modules. No
extra installation is needed beyond `using autoconf` in your `buildfile`.

---

## Enabling the Module

Load it in the `buildfile` where the generated header is declared (it does
not require bootstrapping and does not need to be in `root.build` unless
the header is used across the whole project):

```
using autoconf
```

Then declare the output target with its `in{}` prerequisite:

```
h{config}: in{config}
```

---

## Flavors

The module supports three flavors that differ in how template lines are
written. The active flavor is selected automatically from the input file
extension or set explicitly via `autoconf.flavor`.

### autoconf (default)

Template lines use `#undef NAME`. The module replaces each line with
`#define NAME 1` when the check is true, leaves it as `#undef NAME` when
false, and emits `/* NAME already defined. */` for duplicates.

```
/* config.h.in */

#undef HAVE_STRLCPY
#undef BYTE_ORDER
```

Selected automatically when the input file has no recognized extension
(e.g., `config.h.in`, `config.h`).

### cmake

Template lines use `#cmakedefine NAME` or `#cmakedefine01 NAME`.

- `#cmakedefine NAME` becomes `#define NAME 1` (true) or `/* #undef NAME */`
  (false).
- `#cmakedefine01 NAME` becomes `#define NAME 1` (true) or `#define NAME 0`
  (false).

Both forms support an optional trailing substitution:

```
/* config.h.cmake */

#cmakedefine HAVE_STRLCPY
#cmakedefine01 HAVE_STRLCAT
#cmakedefine VERSION @version@
```

Selected automatically when the input file has the `.cmake` extension. To
use a `.in` file with the cmake flavor, set the variable explicitly:

```
h{config}: in{config}
{
  autoconf.flavor = cmake
}
```

### meson

Template lines use `#mesondefine NAME`. Behavior is the same as `#undef`
in the autoconf flavor: true yields `#define NAME 1`, false yields
`#undef NAME`.

```
/* config.h.meson */

#mesondefine HAVE_STRLCPY
```

Selected automatically when the input file has the `.meson` extension.

---

## How Substitutions Work

Each recognized template line (`#undef`, `#cmakedefine`, `#mesondefine`)
triggers a lookup for the name it references. The module looks up the name
in the following order, stopping at the first match:

1. Custom buildfile variables set on the target (see below).
2. `autoconf.substitutions` key-value pairs.
3. Project checks in `build/autoconf/checks/` (project catalog).
4. Builtin checks in the module's `libbuild2/autoconf/checks/` catalog.

If the name is not found in any catalog and is not set as a buildfile
variable, it remains unresolved and the line is left unchanged (with a
warning in some cases). Duplicate entries within a file are suppressed
with a comment.

Plain `@NAME@`-style substitutions in the template (outside of recognized
template lines) are processed by the underlying `in` module using lax mode
with `@` as the symbol. This handles variables like `PACKAGE_VERSION` that
are not checks:

```
/* config.h.in */

#define VERSION "@version@"
#undef HAVE_STRLCPY
```

```
h{config}: in{config}
{
  version = 1.2.3
}
```

---

## Module Variables

All variables are target-specific and set on the output target.

| Variable | Type | Description |
|---|---|---|
| `autoconf.flavor` | `string` | Input flavor: `autoconf` (default), `cmake`, or `meson`. |
| `autoconf.prefix` | `string` | Prefix to prepend when looking up checks (e.g., `LIBFOO_`). |
| `autoconf.aliases` | `map<string,string>` | Name aliases as `NEW@EXISTING` pairs. |
| `autoconf.substitutions` | `strings` | Key-value pairs as `NAME@VALUE`. Alias for `in.substitutions`. |

### Builtin `in` module variables

The `autoconf` rule inherits all `in` module variables. The defaults are:
`in.symbol = '@'` and `in.mode = lax`. These can be overridden but doing
so is rarely necessary.

---

## Builtin Checks

The module ships ~360 builtin checks covering:

| Category | Examples |
|---|---|
| Headers | `HAVE_UNISTD_H`, `HAVE_SYS_STAT_H`, `HAVE_STDINT_H`, `HAVE_ARPA_INET_H` |
| Functions | `HAVE_STRLCPY`, `HAVE_STRLCAT`, `HAVE_GETADDRINFO`, `HAVE_ARC4RANDOM` |
| Byte order | `BYTE_ORDER`, `WORDS_BIGENDIAN`, `WORDS_LITTLEENDIAN` |
| Type sizes | `SIZEOF_INT`, `SIZEOF_LONG`, `SIZEOF_SIZE_T`, `SIZEOF_VOID_P` |
| Type defs | `ssize_t`, `socklen_t` |
| Keywords | `const`, `inline`, `restrict`, `volatile` |
| Builtins | `HAVE___BUILTIN_EXPECT`, `HAVE___BUILTIN_CLZ`, `HAVE___BUILTIN_BSWAP32` |
| SIMD | `HAVE_SSE4_2`, `HAVE_ALTIVEC`, `HAVE_NEON`, `HAVE_VFP` |
| Windows | `HAVE_WINDOWS_H`, `HAVE_WINSOCK2_H`, `HAVE__ALIGNED_MALLOC` |
| Structs | `HAVE_STRUCT_STAT_ST_MTIM_TV_NSEC` |
| libc | `STDC_HEADERS`, `STRERROR_R_CHAR_P`, `HAVE_VARIADIC_MACROS` |

Checks use static macro inspection based on compiler-predefined macros and
system headers. For example, `HAVE_STRLCPY` checks for BSD/Apple targets
where the function is known to exist; `SIZEOF_INT` reads `__SIZEOF_INT__`
if available or defaults to the MSVC-known value.

The full list is in
[`libbuild2/autoconf/checks/`][checks].

### BASE checks and `BUILD2_AUTOCONF_LIBC_VERSION`

Some checks depend on others declared with the `: BASE` syntax in their
first line. The most important base is `BUILD2_AUTOCONF_LIBC_VERSION`,
which includes platform-specific version headers and defines helper macros:

```
BUILD2_AUTOCONF_GLIBC_PREREQ(maj, min)
BUILD2_AUTOCONF_FREEBSD_PREREQ(maj, min)
BUILD2_AUTOCONF_OPENBSD_PREREQ(yyyymm)
BUILD2_AUTOCONF_NETBSD_PREREQ(maj, min)
BUILD2_AUTOCONF_MACOS_PREREQ(maj, min)
BUILD2_AUTOCONF_MINGW_PREREQ(maj, min)
```

All of these always evaluate to `0` on platforms to which they don't
apply, so checks can use them without guarding against undefinedness.

For example, `HAVE_SYS_STAT_H` is declared as:

```
// HAVE_SYS_STAT_H : BUILD2_AUTOCONF_LIBC_VERSION
```

This ensures `BUILD2_AUTOCONF_LIBC_VERSION` is included before
`HAVE_SYS_STAT_H` in the output so its helper macros are available.
Base checks are deduplicated: if two checks share the same base it is
emitted only once.

### Unprefixable checks

Some check names are standard macro names that arrive from system headers
on certain platforms (e.g., `BYTE_ORDER` from `<sys/endian.h>` on
FreeBSD). These are marked `!` in their first line:

```
// BYTE_ORDER!
```

Unprefixable checks are never prefixed even when `autoconf.prefix` is set.

---

## Custom Substitutions

### Via buildfile variables

Set a variable with the same name as the check on the target:

```
/* config.h.in */

#define PACKAGE_NAME @PACKAGE_NAME@
#define PACKAGE_VERSION @PACKAGE_VERSION@
#undef HAVE_STRLCPY
```

```
h{config}: in{config}
{
  PACKAGE_NAME    = $project
  PACKAGE_VERSION = $version
  HAVE_STRLCPY    = true
}
```

### Via `autoconf.substitutions`

Use this for names that cannot be buildfile variables (names beginning
with `_` are reserved in build2):

```
/* config.h.in */

#undef _GNU_SOURCE
#undef _POSIX_SOURCE
```

```
gnu_source    = ($c.stdlib == 'glibc')
posix_source  = ($c.target.class != 'windows' && !$gnu_source)

h{config}: in{config}
{
  autoconf.substitutions  = _GNU_SOURCE@$gnu_source
  autoconf.substitutions += _POSIX_SOURCE@$posix_source
}
```

### Overriding builtin checks

Custom substitutions and buildfile variables take precedence over builtin
checks. To force a check to true or false:

```
h{config}: in{config}
{
  HAVE_STRLCPY = true   # force to 1
  HAVE_STRLCAT = false  # force to undef
}
```

---

## Check Prefixing

To avoid clashes with macros from other headers, use `autoconf.prefix` to
prefix check names in the output. The template uses the prefixed names:

```
/* config.h.in */

#undef LIBFOO_HAVE_STRLCPY
#undef LIBFOO_HAVE_STRLCAT
```

```
h{config}: in{config}
{
  autoconf.prefix = LIBFOO_
}
```

The prefix is stripped during catalog lookup: `LIBFOO_HAVE_STRLCPY` looks
up `HAVE_STRLCPY` in the catalogs, then emits the result under the
prefixed name. Unprefixable checks (`!`) are always used without prefix
regardless of `autoconf.prefix`.

Overrides and `autoconf.substitutions` entries must include the prefix:

```
h{config}: in{config}
{
  autoconf.prefix      = LIBFOO_
  LIBFOO_HAVE_STRLCPY  = true
  autoconf.aliases     = LIBFOO_MY_SSIZE_T@ssize_t
}
```

---

## Check Aliases

Use `autoconf.aliases` when a project's `config.h.in` uses a non-canonical
name for an existing builtin check. The map entry `NEW_NAME@EXISTING_NAME`
resolves `NEW_NAME` by looking up `EXISTING_NAME`:

```
/* config.h.in */

#undef HAVE_AF_UNIX_H
#undef MY_SSIZE_T
```

```
h{config}: in{config}
{
  autoconf.aliases  = HAVE_AF_UNIX_H@HAVE_AFUNIX_H
  autoconf.aliases += MY_SSIZE_T@ssize_t
}
```

Both names in an alias must include the prefix if `autoconf.prefix` is
set (unprefixable names are used as-is regardless).

---

## Disambiguating the `version.in` and `autoconf.in` Rules

When both the `version` and `autoconf` modules are loaded in the same project,
both the `version.in` and `autoconf.in` rules are registered and both can
match `.in` targets. If the same target matches both rules (for example, a
`hxx{version}` target that contains `#undef` directives), the build system
will error:

```
error: multiple rules matching configuring updating hxx{version}
  info: autoconf.in
  info: version.in
```

Disambiguate by adding a `rule_hint` attribute on the target:

```
# Use the autoconf rule for this .in file:
[rule_hint=autoconf.in] h{config}: in{config}

# Use the version rule for this .in file:
[rule_hint=version.in] hxx{version}: in{version}
```

The `rule_hint` can also be set as a target-specific variable when multiple
targets share the same pattern:

```
hxx{*}: [rule_hint] = version.in
h{config}: [rule_hint] = autoconf.in

hxx{version}: in{version}
h{config}:    in{config}
```

Note: a future build2 release is expected to resolve this automatically via
weighted rule matching (see [build2 issue #421][issue-421]), so the hint will
become optional in most cases.

[issue-421]: https://github.com/build2/build2/issues/421

---

## See Also

- [`in` module](build2-modules-misc.md#in-module) -- the substitution engine this module extends
- [Project-specific checks](build2-autoconf-project-checks.md) -- adding and authoring `build/autoconf/checks/` entries
- [Buildfile integration](build2-autoconf-buildfile.md) -- communicating check results to buildfiles via `c.predefs`
- [`packaging-guide-summary`](packaging-guide-summary.md) -- packaging third-party projects
- [`migrate-from-cmake`](../HOWTO/migrate-from-cmake.md) -- porting CMake projects
- [`build2-project-config`](build2-project-config.md) -- expectation-based configuration
- [Builtin checks catalog][checks]
- [`third-party-private-headers`](../HOWTO/third-party-private-headers.md) -- using `c.predefs` and `-D` flags to avoid a generated config header in third-party packaging

[checks]: https://github.com/build2/libbuild2-autoconf/tree/master/libbuild2-autoconf/libbuild2/autoconf/checks/
[proj-config]: https://build2.org/build2/doc/build2-build-system-manual.xhtml#proj-config
