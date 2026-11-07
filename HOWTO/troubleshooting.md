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

### `error: no rule to clean <target>`

**Cause:** A `testscript{}` was given its own dependency declaration, e.g.
`testscript{name}@./: <target>`, instead of only being listed as a
prerequisite of the test target. Normally a testscript is only ever
consumed as a prerequisite, associated with its target by the `test`
module rather than by generic dependency traversal. A standalone
declaration makes it an independently-declared target instead, and in an
in-source build (`src_base` == `out_base`) that target sits right where a
directory-scoped `b clean` (what the cppget.org publish queue runs against
a plain, non-forwarded build) walks looking for things to clean.
`testscript{}` has no `clean` rule (it is only ever *prepared* by the
`test` operation), so this fails. `@./` is not the cause -- it only pins
the target to `src` instead of the default `out` (see ["Src/out
qualification"](../guides/build2-targets-variables.md#srcout-qualification)),
which is separately required here since the physical file lives in `src`.

**Fix:** Attach the runtime fixture as an `include = adhoc` prerequisite of
the *test executable* instead of the testscript:
```
exe{unit-foo}: ../resources/exe{foo}: include = adhoc
```
See [test-runtime-fixtures.md](./test-runtime-fixtures.md).
Reproduce locally with the expanded dist-test recipe in
[packaging-guide-testing.md](../guides/packaging-guide-testing.md) rather
than waiting on a publish-queue result.

### `rm: '<path>' is a directory`

**Cause:** A custom `fsdir{}` clean recipe (`rm $out_base/inputs`, the NEWS
directory-symlink pattern) ran during in-source `b clean`. When
`src_base == out_base` (the unpacked-dist tree the cppget.org queue
configures, and the `b dist` then in-source `configure`/`update`/`test`/`clean`
recipe), `fsdir{inputs/}` is the real source directory. Update is a no-op
because the directory already exists. Clean still runs `rm` on that path
and fails. `bdep test` is out-of-source and stays green.

`include = ($out_base != $src_base)` on the exe-to-`fsdir` edge does not
fix it. An independent `fsdir{}: file{inputs/**}` declaration still
registers the target, and directory-scoped `b clean` still finds it.

**Fix:** Do not use NEWS-style `fsdir{}` for test data. List the source
files as `include = adhoc` prerequisites of the test executable and `ln`
them into `$~` in the testscript:

```
exe{test-parse_examples}: file{inputs/**}: include = adhoc
```

```
{
  ln -s $src_base/inputs/ inputs
  $*
}
```

See [test-runtime-fixtures.md](./test-runtime-fixtures.md#source-tree-test-data).
Reproduce locally with the expanded dist-test recipe in
[packaging-guide-testing.md](../guides/packaging-guide-testing.md),
including `b clean`. A green `bdep test` is not evidence this is fine.

### `error: unable to create directory <path>: no such file or directory`

**Cause:** An `fsdir{}` target is several directory levels deep, and an
intermediate parent does not exist. The built-in rule auto-creates parents
only out-of-tree (`inject_fsdir_impl` skips anything under `src_path()`).
In-source (`out_base == src_base`, the unpacked-dist tree the cppget.org
queue configures) only an explicitly declared `fsdir{}` prerequisite is
honored. A forwarded dev config stays green because that is exactly where
the cascade fires.

**Fix:** Declare every missing intermediate as an `fsdir{}`-to-`fsdir{}`
prerequisite of the child:

```
file{bundle/Contents/icd.d/icd.json}: fsdir{bundle/Contents/icd.d/}

fsdir{bundle/Contents/icd.d/}: fsdir{bundle/Contents/}
fsdir{bundle/Contents/}:      fsdir{bundle/}
```

See [fsdir-parent-chain.md](./fsdir-parent-chain.md). Reproduce locally
with the dist-test recipe in
[packaging-guide-testing.md](../guides/packaging-guide-testing.md)
(`b dist`, then in-source `configure` / `update`). A green `bdep test` is
not evidence the chain is complete.

### `error: target <target> specified in the test variable is out of date`

**Cause:** A testscript's `test` variable was overridden to an **imported**
target (`testscript{*}: test = $t`), typically to test a package's own
`exe{}` from its `tests/` subproject. The override is resolved with a
lookup only (`search_existing()`), never an update -- if the imported target
isn't otherwise guaranteed up to date (e.g. testing the `tests/` subproject
in isolation, rather than the whole project), the test rule fails instead of
building it.

**Fix:** List the imported target as a prerequisite of the directory alias,
alongside the testscript, exactly as the diagnostic suggests:
```
./: testscript $t
```
See [test-imported-executable.md](./test-imported-executable.md).

### `error: both 'testscript' and other names specified for <target>`

**Cause:** An imported target was given a testscript prerequisite directly
(`$t: testscript{...}`), mirroring the local-target association pattern,
while that same target already has its own local testscript prerequisite
declared in its own project. The two declarations conflict on the same
target.

**Fix:** Don't declare a testscript prerequisite on an imported target.
Override the `test` variable instead (`testscript{*}: test = $t`); see
[test-imported-executable.md](./test-imported-executable.md#do-not-use-the-imported-target-as-the-declarations-left-hand-side).

### `error: unknown build system module <name>`

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

### `error: incompatible <target> build`

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

### `error: unable to import target <target>`

**Cause:** An `import` directive references a project that is not a subproject
of the current project, not in the amalgamation chain, and `config.import.<name>`
is not set. The same wording is also used when the named *member* does not
exist in this configuration, for example `import! [metadata] ... %libs{foo}`
while `config.bin.lib=static` so there is no shared member.

**Fix:** If the project is missing, add it as a subproject, place it in the
same bpkg configuration, or specify the location explicitly:
```
b configure: hello/ config.import.libhello=libhello/
```

If the member is missing under a build class, exclude that class on the
importing package (usually the tests/companion manifest):
```
builds: -static  ; Tests import libs{}, absent when only static is built.
```
See [builds-ci-filtering.md](./builds-ci-filtering.md#exclude-static-when-tests-import-libs).

For an installed `import! [metadata]` that cannot see the `.pc`, see
[local-installed-import.md](./local-installed-import.md).

### `error: static variant of <target> is not available`

**Cause:** `link_member()` (`libbuild2/bin/utility.cxx`) requires that the
`lib{}` member being linked -- `liba{}` for the static variant, `libs{}`
for the shared one -- actually exists; the symmetric `error: shared
variant of <target> is not available` is the same check failing the other
way. For a library imported through its installed `.pc` file, every bare
name in that file's `Libs`/`Libs.private` (e.g. `-lfoo` or `foo.lib`) is
first checked against a hardcoded, per-platform table of "known runtime
libraries" in `libbuild2/cc/pkgconfig.cxx` -- its own comment calls this
"a potentially very long and unstable list". On Windows that table lists
over fifty names (`kernel32`, `advapi32`, `ws2`/`ws2_32`, `psapi`, `uuid`,
and so on); on every other platform it lists common POSIX names (`-lm`,
`-ldl`, `-lrt`, `-pthread`/`-lpthread`, `-lobjc`), plus a few
platform-specific extras such as `-lSystem`/`-liconv` on macOS. A name on
the table is left as a raw linker flag, bypassing `search_library()`/
`link_member()` entirely, so whether a static archive for it exists is
never checked. A name *not* on the table (any more specialized system
dependency, for example a Windows DLL import stub such as `Tbs.lib` or
`cfgmgr32.lib`) falls through to the general resolution path, which does
call `link_member()` -- and this hard-fails if that import library has no
static archive, true of many Windows system DLL stubs regardless of
whether other, similar names happen to be allowlisted.

This only affects the installed-package / pkg-config reimport path,
including a package's own out-of-tree `test-installed` step, under a
strict, single-value `config.bin.exe.lib=static` consumer with no
fallback. An in-tree build, or a plain `exe{}` linking the system library
directly in its own buildfile (see
[link-system-library.md](./link-system-library.md)), never hits this.

**Fix:** There is no buildfile- or manifest-side override to add a missing
name to this allowlist, or to mark one dependency "shared-only, allow a
fallback regardless of the consumer's static setting".

If the system library is only needed to link the package's own objects
(an implementation dependency), keep the name out of the `.pc` entirely.
`*.libs` alone is not enough, because it still reaches the static `.pc`'s
`Libs.private`. Name the library with a force-included
`#pragma comment(lib)` header instead (see
[link-system-library.md](./link-system-library.md#windows-import-library-missing-from-the-pkg-config-allowlist)).

If the name must appear in the `.pc` (an interface dependency), a strict
single-value static consumer (for example a `*-static_*` CI bot) cannot be
made to pass by any packaging-side change today. Exclude that
configuration in the manifest instead:
```
builds: -static
```
or narrower, e.g. `builds: -( +windows &static )`. See
[builds-ci-filtering.md](./builds-ci-filtering.md).

The durable fix is upstream: add the missing name next to the existing
entries in the relevant platform branch of `pkgconfig.cxx`. build2 commit
`43a77886` ("Treat -lobjc as system in pkg-config library resolution",
[build2/build2#557](https://github.com/build2/build2/issues/557)) is
precedent for exactly this kind of addition being accepted upstream.

For the general installed `import!`/`.pc` resolution mechanics, see
[local-installed-import.md](./local-installed-import.md).

### `undefined reference to <symbol>` (GNU ld)

**Cause:** On an `exe{}` or `libs{}` target, a library prerequisite was listed
before the object or source that references it. The `c.link` / `cxx.link`
rule preserves that order on the linker command line. GNU ld is single-pass
on static archives, so `$libs` first then the `.o` drops the archive.

**Fix:** List object and source prerequisites before `$libs`:
```
exe{x}: cxx{x} $libs
```
Split declarations append, so `exe{x}: $libs` then `exe{x}: cxx{x}` is the
same bug. See [link-prerequisite-order.md](./link-prerequisite-order.md).

---

## bpkg errors

### `error: ':' expected after name`

**Cause:** A manifest comment was wrapped onto the following line, the way a
buildfile `#` comment block continues. Manifest `#` comments are whole-line
only. `;` comments are part of that line's value. Neither continues. The
wrapped line is parsed as a new name-value pair.

**Fix:** Keep the comment on the same line as the field, or start a new `#`
comment line that is a complete line by itself. `\` continues a value, not
a comment. See
[bpkg-manifest-reference.md](../bpkg/bpkg-manifest-reference.md#manifest-format).

### `error: package <name> is not found in <repository>`

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

### `error: <dir> does not look like a bpkg configuration directory`

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

### `error: package <name> is not initialized in any default configuration(s)`

**Cause:** `bdep init` has not been run for this project.

**Fix:** `bdep init -C <config-dir>` to initialize the project in an existing
bpkg configuration, or `bdep init --empty` to create a configuration
alongside the project.

### `error: no existing configurations`

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
- [`test-runtime-fixtures`](./test-runtime-fixtures.md): attaching runtime fixtures and source-tree test data without breaking `clean`
- [`test-imported-executable`](./test-imported-executable.md) -- testing an imported executable, and the two errors above
- [`bpkg-dependency-negotiation`](../bpkg/bpkg-dependency-negotiation.md) -- how dependency version constraints are resolved
- [`build2-modules-cc`](../guides/build2-modules-cc.md) -- cc module reference
- [`bx`](../bx/bx.md) -- full bx option and script reference
- [`bx-script`](./bx-script.md) -- getting started with .bx scripts
- [`bpkg-manifest-reference`](../bpkg/bpkg-manifest-reference.md) -- all manifest fields, types, and constraints
