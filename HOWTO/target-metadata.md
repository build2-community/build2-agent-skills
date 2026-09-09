# Conveying Metadata with Targets

Available in build2 0.15.0 and later.

The unit of importation is a target. Targets can carry
[target-specific variables](../guides/build2-targets-variables.md#built-in-target-types)
that importers can query with `$(<target>: <variable>)`. This is the mechanism
for passing build-time metadata (configuration flags, asset paths, etc.) from
a library or executable to its consumers.

For background on target importation see
[target importation](../guides/build2-projects-advanced.md#target-importation)
and the [library metadata protocol](../guides/build2-projects-advanced.md#library-metadata-protocol).

## Development-build case

Set variables directly on the target:

```
lib{hello}:
{
  libhello.fancy = [bool] $config.libhello.fancy
  libhello.assets = [dir_path] $assets_dir
}
```

Query in the consumer:

```
import hello = libhello%lib{hello}

if $($hello: libhello.fancy)
  ...

assets_dir = $($hello: libhello.assets)
```

## Installed case: C/C++ libraries

For installed libraries, metadata must travel in the `pkg-config` file. Signal
this with `export.metadata`. The first element is the protocol version (always
`1`); the second is the variable name prefix -- only variables with that prefix
are saved to `.pc`:

```
lib{hello}:
{
  export.metadata = 1 libhello

  cxx.export.poptions = "-I$out_root" "-I$src_root"
  cxx.export.libs = $intf_libs

  libhello.fancy = [bool] $config.libhello.fancy
  libhello.assets = [dir_path] $assets_dir
}
```

Allowed value types: `bool`, `int64`, `uint64`, `string`, `path`,
`dir_path`, and their list variants (`int64s`, `strings`, `paths`, etc.).
Values cannot be `null`.

### Build vs installed paths (.for_install)

For values that differ between the build and installed locations, set both
the plain variable and a `.for_install` variant. The `.for_install` value is
used when writing the `.pc` file. See the
[install module](../guides/build2-modules-core.md#install-module) for
`install.resolve` and path configuration:

```
lib{hello}:
{
  export.metadata = 1 libhello

  libhello.assets = [dir_path] $out_base/assets/
  libhello.assets.for_install = ($install.root != [null] \
    ? $install.resolve([dir_path] data/assets/) \
    : )
}
```

### Importing with metadata

Use `import!` (forced immediate importation) with the `metadata` attribute so
the import directive resolves the target and verifies metadata is present.
Nominate the link rule for the installed search with `rule_hint`:

```
import! [metadata, rule_hint=cxx.link] hello = libhello%lib{hello}
```

Keep `$hello` in its own variable for the metadata query. Do not put it on an
`exe{}`/`lib{}` prerequisite list to link the library: the immediate import
skips the link rule, so the consumer gets no rpath entry for the library's
own implementation dependencies. If the same library also needs linking, add
a second, ordinary `import` into `libs`. See
[import-immediate-vs-ordinary.md](./import-immediate-vs-ordinary.md) for the
pattern, including the optional-member case.

`rule_hint=cxx.link` only nominates the link rule while the *imported*
target is resolved. It does not change how the consumer's own already
matched link rule treats that target as a prerequisite. A dependency you
never link (`include = adhoc`, `dlopen` only) therefore still contributes
no rpath. Set `bin.rpath` from an always-absolute exported `dir_path`
instead. See
[rpath-unlinked-dependency.md](./rpath-unlinked-dependency.md). Do not
feed `bin.rpath` a `.for_install` value that is relative to `install.root`.

## Installed case: executables

This is for an executable with **no dev build present** -- located via
`PATH`, with metadata queried from the running binary itself. For the
simpler, much more common case of testscript-testing an imported executable
that **is** dev-built alongside the tester (e.g. a package's own `exe{}`
re-imported into its `tests/` subproject), see
[test-imported-executable.md](./test-imported-executable.md) instead -- no
metadata protocol needed.

For executables, metadata is embedded in the binary itself. The executable
must handle `--build2-metadata=<version>` by printing a buildfile fragment to
`stdout` and exiting 0:

```cpp
if (argc == 2 && strncmp (argv[1], "--build2-metadata=", 18) == 0)
{
  cout << "# build2 buildfile hello\n"
       << "export.metadata = 1 hello\n"
       << "hello.fancy = [bool] " << (HELLO_FANCY ? "true" : "false") << '\n';
  return 0;
}
```

The first line is the metadata signature. `<key>` (after `buildfile`) must
match the target name as spelled in `exe{...}`. `<prefix>` is the variable
namespace and may differ from `<key>` (use `_` instead of `-`):

```
# build2 buildfile hello-there
export.metadata = 1 fancy_hello
fancy_hello.fancy = false
```

Import an executable with metadata:

```
import! [metadata] hello = hello%exe{hello}
```

### Predefined executable metadata variables

build2 uses these variables to improve diagnostics and change tracking when
the executable is used as a build tool (e.g., a source code generator):

```
<prefix>.name        = [string]   # stable name for diagnostics
<prefix>.version     = [string]   # version for diagnostics
<prefix>.checksum    = [string]   # checksum for recipe change tracking
<prefix>.environment = [strings]  # env vars that affect output
```

Add a comment in both the buildfile and `main()` to keep the two copies in
sync:

```
exe{hello}:
{
  # Metadata (see also --build2-metadata in main.cxx).
  export.metadata = 1 hello
  hello.fancy = [bool] $config.hello.fancy
}
```

## See Also

- [third-party-private-headers](./third-party-private-headers.md) -- applying the `[path, null]` / `.for_install` metadata pattern to share generated file paths (config headers, data archives) across packages in a multi-package repository
- [test-imported-executable](./test-imported-executable.md) -- testing a dev-built imported executable, no metadata protocol needed
- [import-immediate-vs-ordinary](./import-immediate-vs-ordinary.md) -- do not link the immediately imported target; the two-variable pattern for also linking a queried library
- [rpath-unlinked-dependency](./rpath-unlinked-dependency.md) -- `bin.rpath` from always-absolute metadata for a dependency you never link
- [local-installed-import](./local-installed-import.md) -- verify `import! [metadata]` against a real install prefix
