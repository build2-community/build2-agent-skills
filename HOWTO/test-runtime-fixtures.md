# Runtime Test Fixtures

Tests often need extra files at runtime that are not themselves smoke tests.
Those are three different patterns, not one recipe.

1. **Built fixtures** (helper executables, generated data). Attach them as
   `include = adhoc` prerequisites of the test executable so they sit on
   the **test update path**. `update-for-test`, `b test`, and out-of-source
   **test-installed** builds then still produce them. That is this file
   except the source-tree section.

2. **Source-tree test data** (files or directories the test opens by
   relative name, such as `"inputs/..."`). List them as `include = adhoc`
   `file{}` prerequisites of the executable so `dist` and
   `update-for-test` see them, then `ln` them into `$~` in the testscript.
   See [Source-tree test data](#source-tree-test-data).

3. **NEWS `fsdir{}` directory symlink.** `build2/NEWS` shows `fsdir{assets}`
   with an ad hoc `ln -s $src_base/assets $out_base/assets` recipe, attached
   to `exe{hello}`. That is for a program that needs an asset directory next
   to it at runtime. It is not a test-fixture recipe. The ad hoc runner
   special-cases `fsdir{}` for this (skip update if the path already exists
   as a directory, still run clean if any filesystem entry exists).

## Mark fixtures as non-tests

If every `exe{}` in the tests subproject defaults to `test = true`, turn that
off for fixtures:

```
# tests/resources/buildfile (or equivalent)
exe{*}: test = false

for t: c{*}
  ./: exe{$name($t)}: $t
```

Listing a fixture only as a member of `./:` with `test = false` is **not**
enough for `update-for-test`. The test rule updates testable targets and what
they need for testing. A non-test directory member is skipped.

## Attach built fixtures with `include = adhoc` (preferred)

For Testscript-driven tests, attach runtime fixtures as `include = adhoc`
prerequisites of the **test executable**, not of the testscript:

```
import libs = libreproc%lib{reproc}

include ../resources/

resource_dir = $posix_string([dir_path] $out_root/resources)

for t: c{* -fork}
{
  n = $name($t)

  ./: exe{unit-$n}: $t $libs testscript{common}
  {
    c.poptions += "-DRESOURCE_DIRECTORY=\"$resource_dir\""
  }

  # Runtime fixture: attached to the executable (not the testscript) so it
  # stays on a target that already has update and clean rules.
  #
  exe{unit-$n}: ../resources/exe{$n}: include = adhoc
}
```

### Why the executable, not the testscript

A testscript is normally only ever consumed as a **prerequisite** of a
testable target (`exe{hello}: cxx{hello} testscript`); that association is
handled specially by the `test` module, not by generic dependency-graph
traversal (see [testscript-summary.md](../guides/testscript-summary.md)).

Giving the testscript a **separate** dependency declaration of its own,
`testscript{name}@./: <target>`, is different: it makes `testscript{name}`
a target this buildfile independently declares, like any other. In an
in-source build `src_base` and `out_base` are the same directory, so that
independently-declared target sits right where a directory-scoped
`b clean` -- what the cppget.org publish queue runs against a plain,
non-forwarded build -- walks looking for things to clean. `testscript{}`
has no `clean` rule (it is only ever *prepared* by the `test` operation,
never independently updated or cleaned outside that), so this fails with
`error: no rule to clean .../testscript{name}`; see
[troubleshooting.md](./troubleshooting.md).

`@./` is not what causes this -- it only pins the target to `src` instead
of the default `out`, and is required here regardless, since the
`.testscript` file genuinely lives in `src`. See ["Src/out
qualification"](../guides/build2-targets-variables.md#srcout-qualification)
for the general rule this is a special case of: `@./` decides which
directory a target resolves against; the *separate declaration* is what
registers it as a target at all.

`include = adhoc` sidesteps the whole issue: the fixture stays an ordinary
prerequisite of the executable -- a target that already has update and
clean rules -- and is never separately declared as a target of its own.
`adhoc` additionally tells build2 to track and update that prerequisite
without treating it as a compile/link input. This is also how
`third-party-private-headers.md` attaches symlinked headers build2 must
track but not compile; see [`include = adhoc`
there](./third-party-private-headers.md#thunk-headers-and-symlinks-cross-package-in-place-workaround).

This pattern (and the `clean` failure it fixes) was confirmed and released
upstream in `build2-reproc`: `libreproc`/`libreprocxx` revision 14.2.7+1
replaced `testscript{common}@./: ../resources/exe{$n}` with
`exe{unit-$n}: ../resources/exe{$n}: include = adhoc` in both
`tests/unit/buildfile` and `tests/examples/buildfile`.

### Shared testscript

Because each fixture is now attached directly to the executable that needs
it, there is no fan-out to worry about: sharing one `testscript{common}`
across many unit exes no longer pulls in every fixture for every test --
each executable only gets the fixtures listed on its own `adhoc`
prerequisites.

## Paths for spawn-by-name tests

When the unit binary opens a helper under a fixed directory (upstream often
uses `-DRESOURCE_DIRECTORY=...`), point that define at the **tests project**
out tree, not the library out tree:

```
resource_dir = $posix_string([dir_path] $out_root/resources)
```

`$out_root` here is the tests subproject root out directory. That stays
correct for in-tree, out-of-source, and test-installed layouts.

## Do not use `test.input` for this

Prerequisite-specific `test.input = true` is a **simple-test** mechanism
(no testscript). It means: make the prerequisite up to date and **append its
path as an extra command-line argument** after `test.options` /
`test.arguments`. It is not currently applied to Testscript-driven tests, and
it changes argv (wrong if the test finds helpers via `RESOURCE_DIRECTORY` or
similar).

| Variable | Role |
|---|---|
| `test.stdin` | Prerequisite file is the test's stdin (simple tests) |
| `test.stdout` | Prerequisite file is compared to stdout (simple tests) |
| `test.roundtrip` | Both stdin and stdout (simple tests) |
| `test.input` | Update + path appended as argv (simple tests only) |

For simple tests that intentionally want "run me with this child path as an
argument":

```
exe{parent}: exe{child}: test.input = true
```

For Testscript + spawn-by-path fixtures, use the `include = adhoc` pattern
above instead.

## Source-tree test data

Tests that open files or directories by relative name (`"inputs/..."`,
`"json-patch-tests/..."`) need those paths in the test working directory.
That is not a built fixture. Do not copy the NEWS `fsdir{}` asset recipe
into the test buildfile.

This distinction showed up while packaging `libcjson`
(`build2-packaging/cJSON`). Upstream tests open relative input paths. The
first packaging used NEWS-style `fsdir{}` recipes that `ln -s` those src
directories into `$out_base`, then `env -c $out_base` in the testscript so
the relative names resolved. That is the wrong tool for tests.

### Keep the files on the executable

In the buildfile, keep the files on the executable that opens them so `dist`
and `update-for-test` see them:

```
exe{test-parse_examples}: file{inputs/**}: include = adhoc
```

`include = adhoc` tracks the files without treating them as compile or link
inputs. That is the same attachment used for built fixtures.

This gets the files *into* the archive and the test tree. For the opposite
problem -- keeping large or generated fixtures *out* of the `b dist`
archive -- see [exclude-test-data-from-dist.md](./exclude-test-data-from-dist.md).

### Link into `$~` in the testscript

In the testscript, link into `$~` and run there (one test scope, so the
links and the executable share a working directory). Trailing slash on the
source is directory syntax (always `/`, including on Windows):

```
{
  ln -s $src_base/inputs/ inputs
  $* 1>! == 0
}
```

Do not `env -c $out_base` or `env -c $src_base`. Testscript will not
auto-clean files the test writes outside `$~`. Registering a cleanup path
outside the script working directory is an error. See
[testscript-commands.md](../guides/testscript-commands.md).

`$src_base/inputs/` must be a real directory (or a file). Link the src
directory itself, with a trailing slash on the source. Linking an out-tree
dir-symlink into `$~` is the failure mode the NEWS recipe produces on
Windows.

The same `ln` idea for a single file is in
[sanitize-tests.md](./sanitize-tests.md). This section is the directory
case plus the buildfile side `dist` needs.

### Why the NEWS `fsdir{}` recipe fails for tests

The NEWS example is:

```
exe{hello}: ... fsdir{assets}

fsdir{assets}:
% update
{{
  ln -s $src_base/assets $out_base/assets
}}
% clean
{{
  rm $out_base/assets
}}
```

That belongs on a program that needs `assets/` next to the binary at
runtime. For tests it fails in three ways:

- `env -c $out_base` leaves `$~`. Testscript will not auto-clean files the
  test writes outside the script working directory.
- In-source (`src_base == out_base`, which is how `b dist` then `b configure`
  in the unpacked archive works, and what the cppget.org queue runs),
  `fsdir{inputs/}` is the real source directory. Update is a no-op (the
  directory already exists). Clean still runs `rm` on that path and fails
  (`rm: '...' is a directory`). `bdep test` is out-of-source and hides this.
- `include = ($out_base != $src_base)` on the exe-to-`fsdir` edge does not
  fix it. The `fsdir{}: file{inputs/**}` declaration still independently
  registers the target, and directory-scoped `b clean` still finds it.

`clean = ($src_root != $out_root)` is the documented in-source clean
attribute, but only for generated files that overlay a distributed src
file (see [generated-headers.md](./generated-headers.md)). It is a patch
if someone insists on NEWS-style `fsdir{}`, not the recommended design for
test data.

There is no production `fsdir{}` plus `ln` buildfile in the toolchain
submodules. The only `fsdir{}` in a buildfile is
`build2/old-tests/postponed/buildfile`, and that only creates an empty
out directory.

## Anti-patterns

```
# Wrong: link line may try to use the helper as a link input.
./: exe{unit-foo}: c{foo} $libs testscript{common} ../resources/exe{foo}

# Wrong: looks like "update for test" but changes argv and is simple-test only.
exe{unit-foo}: ../resources/exe{foo}: test.input = true

# Wrong: registers testscript{} as an out-tree build target with no clean
# rule -- "error: no rule to clean .../testscript{common}" in a plain build.
testscript{common}@./: ../resources/exe{foo}

# Wrong: fixture is not on any testable target's update path.
./: ../resources/exe{foo}   # with exe{*}: test = false in resources/

# Wrong: NEWS fsdir{} asset recipe used as a test-data fixture.
# In-source clean then rm's the real src directory.
exe{test}: fsdir{inputs}
fsdir{inputs}:
% update
{{
  ln -s $src_base/inputs $out_base/inputs
}}
% clean
{{
  rm $out_base/inputs
}}
```

Wrong in the testscript (leaves `$~`, no auto-cleanup of test writes):

```
env -c $out_base -- $*
```

## See Also

- [sanitize-tests.md](./sanitize-tests.md): `ln` of src files and directories into `$~`
- [troubleshooting.md](./troubleshooting.md): the `clean` failures these patterns avoid
- [update-for-test-install.md](./update-for-test-install.md): for-test closure
- [testscript-summary.md](../guides/testscript-summary.md): Testscript integration and `test.*` variables
- [testscript-commands.md](../guides/testscript-commands.md): `$~`, `ln`, `env -c`, cleanup
- [packaging-guide-testing.md](../guides/packaging-guide-testing.md): packaging workflow, dist-test, test-installed
- [generated-headers.md](./generated-headers.md): `clean = ($src_root != $out_root)` for generated files overlaying src
- [config-independent-build-graph.md](./config-independent-build-graph.md): platform-specific tests with `include =`
- [exclude-test-data-from-dist.md](./exclude-test-data-from-dist.md): keep fixtures out of the `b dist` archive instead of into the test tree
- [third-party-private-headers.md](./third-party-private-headers.md): `include = adhoc` for tracked, non-compiled prerequisites
- [build2-projects-advanced.md](../guides/build2-projects-advanced.md): `@./` for src-side targets
- [test-imported-executable.md](./test-imported-executable.md): testing an imported executable without repeating this file's `clean` footgun in a new context
