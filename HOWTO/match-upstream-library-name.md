# Match Upstream Library Output Names

Build2 target identifiers (`lib{MoltenVK}`) are a separate namespace from
the package `name:` and `project:` manifest fields. See
[package-naming.md](./package-naming.md) for those.

When a library's output is consumed outside the build2 graph (a dynamic
loader, a `-l` link line, `dlopen()` by a fixed path, pkg-config), match
upstream's artifact, not a convenient build2 name. Existing consumers cannot
be "fixed" to expect a renamed file.

This is verified against
`.submodules/build2-toolchain/build2/libbuild2/cc/link-rule.cxx`
(`derive_libs_paths`, the `bin.lib.prefix` lookup) and
`libbuild2/bin/init.cxx` (`bin.lib.version`, `bin.lib.prefix`).

## Preference order

1. Match the upstream target name directly where reasonable
   (`lib{MoltenVK}`, not `lib{moltenvk}`).
2. At minimum, keep the generated artifact matching upstream's output
   name, including shared-library versioning (SONAME, compatibility or
   current version, `.so.MAJOR` / `.dylib` suffix placement, prefix
   removal on MinGW). Matching the base name only is not enough.

The `libmoltenvk` package name staying lowercase while the target is
`lib{MoltenVK}` is the usual split: the ICD JSON and `-lMoltenVK` are
fixed upstream expectations, independent of the package name.

## Default `bin.lib.version` does not match most upstream SONAMEs

`bdep new` emits a platform-independent suffix
(`doc/manual.cli`, `bdep/new.cxx`):

```
if $version.pre_release
  lib{hello}: bin.lib.version = "-$version.project_id"
else
  lib{hello}: bin.lib.version = "-$version.major.$version.minor"
```

That suffix is embedded in the library name on every platform
(`libhello-1.2.dll`, `libhello-1.2.dylib`, and `libhello-1.2.so` unless a
platform-specific key overrides it). It does not produce Linux
`libhello.so.MAJOR` (SONAME `libhello.so.MAJOR`) or Darwin
`libhello.MAJOR.dylib`.

Look at what upstream actually ships (`libfoo.so.1`, `libfoo.1.dylib`,
`foo-1.dll`) and set the knobs below until the produced file names match.

## `bin.lib.version`: platform-independent vs `linux@`

The value is a sequence of `@`-pairs. An empty key (the `@` can be omitted)
is the platform-independent suffix. A key is the target system or class
(`linux`, `macos`, `windows`, or a `bin.target.system` value). Lookup order
in `derive_libs_paths` is system, then class, then `*`, then the independent
entry.

Platform-specific versions are currently implemented only on Linux
(`manual.cli`: "currently only implemented on Linux"). A `macos@` or
`windows@` key fails with `X-specific bin.lib.version not yet supported`.

Linux form is `MAJOR.MINOR[.EXTRA]` (`link-rule.cxx`: MINOR is required,
EXTRA is optional):

```
lib{hello}: bin.lib.version = -1.2 linux@1.2.3
```

On Linux that yields:

- SONAME `libhello.so.1`
- intermediate `libhello.so.1.2` when EXTRA is present
- real name `libhello.so.1.2.3` (the whole version string is the extra
  extension)

`linux@1.2` (no EXTRA) has no intermediate and the real file is
`libhello.so.1.2`. A single-component `linux@1` fails with `missing minor
component`.

On other platforms the independent `-1.2` suffix applies (`libhello-1.2.dll`,
`libhello-1.2.dylib`).

To match a Linux SONAME while keeping the generated pre-release suffix
elsewhere, put the upstream `MAJOR.MINOR` or `MAJOR.MINOR.EXTRA` string on
the `linux@` key:

```
if $version.pre_release
  lib{hello}: bin.lib.version = "-$version.project_id" linux@"$version.major.$version.minor.0"
else
  lib{hello}: bin.lib.version = "-$version.major.$version.minor" linux@"$version.major.$version.minor.0"
```

Adjust the `linux@` value to what upstream actually ships. If the real file
should be `libfoo.so.MAJOR` with no minor in the filename, the `linux@`
knob cannot produce that (MINOR is required, and the real file always
carries the whole version string). Override `extension` instead.

## `bin.lib.prefix`: drop `lib` on MinGW

When `bin.lib.prefix` is unset:

- POSIX: default prefix is `lib` (`libhello.so`)
- MinGW: default prefix is also `lib` (`libhello.dll`)
- MSVC: no default prefix (`hello.dll`)

Assign empty to suppress the MinGW `lib` so the DLL matches a prefix-less
upstream name (`vulkan-1.dll` rather than `libvulkan-1.dll`):

```
if ($cxx.target.system == 'mingw32')
  lib{vulkan}: bin.lib.prefix =
```

An unset variable and an empty assignment are different. Unset falls back
to `lib` on MinGW. Empty keeps `pfx` as `""` and skips that fallback
(`link-rule.cxx`, `derive_libs_paths`).

## `extension`: layouts the version knobs do not produce

`libs{}` takes its extension from the target's `extension` variable
(`derive_extension`). Override it when upstream's layout is not the
Linux extra-extension form and not the independent suffix form. A BSD
`libfoo.so.MAJOR` (version inside the extension, not after `.so`) is the
usual case:

```
if ($cxx.target.class == 'bsd')
  libs{foo}: extension = "so.$version.major"
```

The same knob can produce a Darwin extra-extension layout
(`libfoo.1.dylib`) that the independent suffix (`libfoo-1.dylib`) would
miss. Confirm against upstream's actual file name before copying this.

## See Also

- [package-naming.md](./package-naming.md): repository / `project:` /
  package `name:` case, and the short target-vs-output note
- [build2-projects-advanced.md](../guides/build2-projects-advanced.md):
  `bin.lib.version` syntax
- [build2-modules-bin.md](../guides/build2-modules-bin.md): `lib{}` /
  `liba{}` / `libs{}`
- [packaging-guide-summary.md](../guides/packaging-guide-summary.md):
  default generated `bin.lib.version` in Step 5
