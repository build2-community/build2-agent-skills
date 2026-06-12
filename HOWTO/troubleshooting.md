# Troubleshooting Common build2 Errors

Common error messages and their resolutions, organised by tool. Each entry
shows the exact error text (or a representative prefix), the cause, and the
fix.

---

## b errors

### `error: no rule to update target <path>`

**Cause:** The target type is not declared, the required module is not loaded,
or the target name does not match any pattern.

**Fix:**
- Ensure the correct module is loaded in `root.build` (e.g., `using cxx` for
  `.cxx` files, `using c` for `.c` files).
- Verify the target type suffix matches the `extension` variable setting.
- Check that the file actually exists in the source directory.

### `error: unknown module <name>`

**Cause:** The module name is misspelled, or the module is not part of the
build2 toolchain installed on this system.

**Fix:** Verify the module name. Standard modules: `c`, `cxx`, `cc`, `bin`,
`config`, `test`, `install`, `dist`, `version`, `in`. Third-party modules
must be installed separately.

### `error: unknown operation <name>`

**Cause:** The operation name is misspelled, or the module that provides it
(e.g., `test`, `install`, `dist`) is not loaded in `bootstrap.build`.

**Fix:** Add `using test` (or `using install`, `using dist`) to
`build/bootstrap.build`, not to `root.build` -- operations must be registered
at bootstrap time.

### `error: <path>/: not a simple project`

**Cause:** `b` was run inside a bpkg configuration directory (an amalgamation)
directly. bpkg configurations must be managed with `bpkg` or `bdep`.

**Fix:** Run `b` from within a package source directory inside the
configuration, or use `bdep update` / `bdep test`.

### `error: already updated <target> but not for install`

**Cause:** A target was built for development (`update`) and then a
second pass attempts to build it for installation, which requires different
flags (e.g., no `rpath`). This happens when the same target appears in both
the `update` and `install` phases.

**Fix:** See [`for-install-conflicts`](./for-install-conflicts.md) for the
complete resolution strategies.

### `error: multiple rules matching ... <target>`

**Cause:** Two `in`-based rules both match the same target. This typically
happens when both `version` and `autoconf` are loaded: `version.in` and
`autoconf.in` each register a rule for `.in` prerequisites, and a target
such as `hxx{version}` can satisfy both.

**Fix:** Add a `rule_hint` attribute to each ambiguous target:

```
[rule_hint=version.in]  hxx{version}: in{version}
[rule_hint=autoconf.in] h{config}:    in{config}
```

See [`build2-modules-autoconf`](../guides/build2-modules-autoconf.md#disambiguating-the-versionin-and-autoconfin-rules)
for details.

### `error: <file>: unable to map <name> to a project`

**Cause:** An `import` directive references a project that is not a subproject
of the current project, not in the amalgamation chain, and `config.import.<name>`
is not set.

**Fix:** Either add the project as a subproject, place it in the same bpkg
configuration, or specify the location explicitly:
```
b configure: hello/ config.import.libhello=libhello/
```

---

## bpkg errors

### `error: package <name> not found in <repository>`

**Cause:** The package name is misspelled, the repository does not contain
that package, or `rep-fetch` has not been run after adding the repository.

**Fix:** Run `bpkg fetch` to update the repository package list. Check the
repository URL with `bpkg rep-list`.

### `error: package <name> <version> is not available`

**Cause:** The requested version does not exist in any configured repository,
or the version constraint is too strict.

**Fix:** Run `bpkg status <name>` to see which versions are available. Relax
the version constraint in the manifest or specify an available version
explicitly.

### `error: unable to satisfy constraints on package <name>`

**Cause:** Two or more packages in the dependency graph require incompatible
versions of a shared dependency.

**Fix:** See [`bpkg-dependency-negotiation`](../bpkg/bpkg-dependency-negotiation.md)
for how build2 resolves multi-package constraints. To diagnose, run
`bpkg build --plan` to see the proposed resolution plan. A manual version
override may be needed: `bpkg build <name>/<version>`.

### `error: no build2 configuration in <dir>`

**Cause:** The directory is not a bpkg configuration (missing `.bpkg/`
metadata).

**Fix:** Create a configuration first: `bpkg create -d <dir> cc config.cxx=g++`.

### `<manifest>:<line>:<col>: error: no package name specified`

**Cause:** The `manifest` file does not contain a `name:` field, or the file
is completely absent from the package root.

**Fix:** Add `name: <package-name>` as the first field in `manifest`. See
[`bpkg-manifest-reference`](../bpkg/bpkg-manifest-reference.md) for the
required fields: `name`, `version`, `summary`, `license`.

### `<manifest>:<line>:<col>: error: unknown name '<field>' in package manifest`

**Cause:** The manifest contains a field name that is not recognised by the
manifest parser. Common causes: a typo in a field name, a field that was
removed in a newer format version, or a custom field added without the
`x-` vendor prefix.

**Fix:** Check the spelling against the field list in
[`bpkg-manifest-reference`](../bpkg/bpkg-manifest-reference.md). Private
(non-standard) fields must start with `x-` to be accepted by the parser.

---

## bdep errors

### `error: project <dir> is not initialized`

**Cause:** `bdep init` has not been run for this project.

**Fix:** `bdep init -C <config-dir>` to initialize the project in an existing
bpkg configuration, or `bdep init --empty` to create a configuration
alongside the project.

### `error: no build configurations`

**Cause:** There are no bpkg configurations associated with this project.

**Fix:** Run `bdep init` or `bdep config create`. See
[`toolchain-dev-setup`](./toolchain-dev-setup.md) for a typical setup.

### `error: package manifest and lockfile are out of sync`

**Cause:** A dependency was added to `manifest` but `bdep sync` was not run,
or the lockfile was edited manually.

**Fix:** Run `bdep sync` to reconcile the manifest with the build
configurations. If the lockfile is corrupt, delete it and run `bdep sync`
to regenerate it.

### `error: package <name> manifest is missing or invalid`

**Cause:** The `manifest` file is absent from the project root, or it is
malformed.

**Fix:** Check the `manifest` file exists and follows the format documented
in [`bpkg-manifest-reference`](../bpkg/bpkg-manifest-reference.md). Required
fields: `name`, `version`, `summary`, `license`.

---

## bx errors

### `error: task running not yet implemented`

**Cause:** `bx` was invoked with a task name (a bare word that is not a path
and does not end in `.bx`). Task execution is not yet implemented in the
current toolchain release.

**Fix:** Use script execution instead: create a `.bx` script file and invoke
it as `bx ./script.bx`. See [`bx-script`](./bx-script.md) for the script
syntax and usage.

### `error: invalid script path '<path>'`

**Cause:** The path passed as a script argument is syntactically invalid on
the host operating system.

**Fix:** Verify the path contains only valid characters and no null bytes.
Prefer simple relative paths such as `./configure.bx`.

---

## brep errors

### `error: database schema is too old`

**Cause:** The schema version in the database predates the oldest version
`brep-migrate` can migrate from. This typically happens after a large version
jump.

**Fix:** Drop the database completely and recreate it. Use
`brep-migrate --drop package && brep-migrate package` (and likewise for
`build`), or drop the database directly with `psql` and then rerun
`brep-migrate package`. All previously loaded data will be lost.

### `error: database schema is too new`

**Cause:** The database was created or last migrated by a newer version of
`brep` than the one currently installed.

**Fix:** Upgrade the `brep` installation to match the database version, or
recreate the database with `brep-migrate --drop package && brep-migrate package`.

### `error: database schema requires migration`

**Cause:** The `--drop` or `--recreate` option was passed to `brep-migrate` but
the schema is at an older version. These destructive options refuse to proceed
on an unmigrated schema.

**Fix:** Either run `brep-migrate package` first to migrate the schema, then
rerun with `--drop` or `--recreate`, or drop the database manually with `psql`
and then run `brep-migrate package`.

### `error: no database schema specified`

**Cause:** `brep-migrate` was invoked without a positional schema argument.

**Fix:** Pass either `package` or `build` as the argument:
`brep-migrate package` or `brep-migrate build`.

### `error: unable to fetch manifests for <repo>`

**Cause:** `brep-load` could not fetch the package manifest from the specified
repository. The repository may be unreachable or the URL may be wrong.

**Fix:** Verify the repository URL is correct and accessible. Check the
`base` repository location in the `brep-load` configuration file.

### `error: can't resolve <dep> for the package <name>`

**Cause:** `brep-load` found a dependency in a package manifest that cannot be
resolved to any package in the configured repositories. Typically means the
repository is inconsistent or a prerequisite repository is missing.

**Fix:** Add the prerequisite repository to the configuration or check the
package manifest for invalid dependency declarations. The `info` line printed
with the error identifies which repository appears broken.

---

## Compiler and linker errors surfaced by b

### Missing DLL export macro (`__declspec(dllexport)` / `__declspec(dllimport)`)

**Cause:** The library was not configured for automatic DLL symbol exporting.

**Fix:** Enable `bin.def` or use the automatic DLL export approach. See
[`build2-modules-cc`](../guides/build2-modules-cc.md#automatic-dll-symbol-exporting).

### Binless library missing system dependency at link time

**Cause:** A header-only library depends on a system library (e.g., `-lm`)
listed in `*.export.libs` but not in `*.libs`. When the static variant of
a binless library is linked, `*.libs` is required.

**Fix:** List the system library in both `*.libs` and `*.export.libs`. See
[`header-only-library`](./header-only-library.md#system-library-dependencies).

## See Also

- [`for-install-conflicts`](./for-install-conflicts.md) -- detailed for-install conflict resolution
- [`bpkg-dependency-negotiation`](../bpkg/bpkg-dependency-negotiation.md) -- how dependency version constraints are resolved
- [`build2-modules-cc`](../guides/build2-modules-cc.md) -- cc module reference
- [`bx`](../bx/bx.md) -- full bx option and script reference
- [`bx-script`](./bx-script.md) -- getting started with .bx scripts
- [`bpkg-manifest-reference`](../bpkg/bpkg-manifest-reference.md) -- all manifest fields, types, and constraints
