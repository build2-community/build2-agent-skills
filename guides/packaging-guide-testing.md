# build2 Packaging Guide -- Testing and Publishing

Steps 8-10 of the third-party packaging workflow: writing tests, validating
the package, merging the `review` branch into `main`, and publishing to
`cppget.org`.

See [packaging-guide-summary.md](packaging-guide-summary.md) for the full
context, concepts, and steps 1-7 (repository setup through installation).

## Step 8: Write Tests

**Smoke test.** Start with a minimal test that includes the library's main
public headers, calls a few functions (at least one non-inline function to
verify symbol exporting), and passes. Place it under `tests/basics/`:

```cpp
#include <foo/core.hpp>
#include <foo/util.hpp>

#undef NDEBUG
#include <cassert>

int main ()
{
  foo::context* c (foo::init (0));
  assert (c != nullptr);
  foo::deinit (c);
}
```

Test `buildfile`:

```
import libs = libfoo%lib{foo}
exe{driver}: {hxx cxx}{**} $libs
```

**Executable smoke test.** For executables, use a `testscript` in the source
directory. A version check is always a viable last resort:

```
: version
:
$* --version >>~"/EOO/"
/.*$(version.major)\.$(version.minor)\.$(version.patch).*/
EOO
```

**Replacing with upstream tests.** Study the upstream test structure before
converting:
- Unit tests (needing internal symbols) vs. integration tests (public API only)
- External testing framework usage (if so, factor tests into a separate
  accompanying package to avoid making the library depend on the testing
  framework). The same split applies to examples and benchmarks. Name the
  sibling `libfoo-tests`, `libfoo-examples`, or `libfoo-benchmarks`, and
  declare it from the primary package with `tests:`, `examples:`, or
  `benchmarks:` (`tests: libfoo-tests == $`). Copy the primary package
  `summary` unchanged and append ` (tests)`, ` (examples)`, or
  ` (benchmarks)`. Do not rewrite the summary. See
  [tests-extra-dependencies.md](../HOWTO/tests-extra-dependencies.md) for
  the manifest and `PACKAGE-README.md` conventions.
- Single or multiple test executables
- Internal utility libraries shared across test executables (use `libue{}`
  utility libraries in `build2`)
- Built runtime fixtures: child processes or data built alongside the tests
  (mark with `test = false`, attach as `include = adhoc` prerequisites of
  the **test executable**, not the testscript, so `update-for-test` and
  test-installed still build them). See
  [test-runtime-fixtures.md](../HOWTO/test-runtime-fixtures.md).
- Source-tree test data: files or directories the test opens by relative
  name (`"inputs/..."`, `"json-patch-tests/..."`). List them as
  `include = adhoc` `file{}` prerequisites of the test executable so
  `dist` sees them, then `ln` them into `$~` in the testscript. Do not use
  the NEWS `fsdir{}` directory-symlink recipe (that is for a program that
  needs an asset directory next to it at runtime) and do not
  `env -c $out_base`. See
  [test-runtime-fixtures.md](../HOWTO/test-runtime-fixtures.md#source-tree-test-data).
- Importing the package's own `exe{}` into `tests/` to test it (the shape
  `bpkg`'s and `bdep`'s own test suites use): see
  [test-imported-executable.md](../HOWTO/test-imported-executable.md).

Multiple test executables using a shared utility library:

```
import libs = libfoo%lib{foo}

./: exe{test1}: cxx{test1} libue{common}
./: exe{test2}: cxx{test2} libue{common}

libue{common}: {hxx cxx}{common} $libs
```

A library must have at least one test to be publishable to `cppget.org`.

If upstream tests do not terminate in a reasonable time, pass limiting options
via `test.options` or set a test execution timeout treated as success.


## Step 9: Test the Package

**Local build and test:**

```
$ bdep update
$ bdep test
$ bdep test -a    # all configurations
```

**Test the installed case.** Install the library to a temporary directory
first, then build the `tests/` subproject out-of-source against the installed
copy. This verifies that the public headers are installed in a way that
consumers can include them -- the same check consumers will perform when they
link against the installed library.

On GCC/Clang (POSIX):

```
$ b install config.install.root=/tmp/install
$ b test: tests/@/tmp/libfoo-tests-out/ \
  config.cc.loptions=-L/tmp/install/lib \
  config.bin.rpath=/tmp/install/lib
```

On MSVC (Windows), DLL lookup uses `PATH` instead of rpath, and the linker
flag uses `/LIBPATH:` syntax:

```
> b install config.install.root=c:\tmp\install
> set "PATH=c:\tmp\install\bin;%PATH%"
> b test: tests\@c:\tmp\libfoo-tests-out\^
  config.cc.loptions=/LIBPATH:c:\tmp\install\lib
```

After running the tests, look over the installed files and confirm there is
nothing unexpected -- no missing headers, no private headers installed by
mistake. Then clean up:

```
$ rm -r /tmp/install /tmp/libfoo-tests-out
```

**If the tests project queries a dependency's metadata with `import!`/
`import?` and also links that dependency**, keep the two separate: the
immediate import for metadata, an ordinary `import` into `libs` for linking.
This installed test is what actually exercises the link rule's installed
search, so it is the case that catches a library linked through its
immediate import instead -- in-tree testing can pass regardless, because the
export stub still attaches the dependency's own implementation dependencies.
See [import-immediate-vs-ordinary.md](../HOWTO/import-immediate-vs-ordinary.md).

**If a dependency exports an executable target** and the installed test fails
with `unable to import target <pkg>%exe{...}`, the dependency's executable is
not reachable from the install tree. Unlike libraries, installed executables
have no `pkg-config`-style lookup.

If the dependency is a build2 project that implements the executable metadata
protocol (`export.metadata` in its buildfile and `--build2-metadata` handling
in `main()`), build2 can find it via `PATH` when `import! [metadata]` is used
-- see [`HOWTO/target-metadata.md`](../HOWTO/target-metadata.md#installed-case-executables)
for how to author this. In that case the installed test works without any extra
configuration, provided the executable is on `PATH`.

For pre-built third-party executables that do not implement the metadata
protocol, the practical workaround is to point `config.import.<pkg>` at the
dependency's development build `out_root`, which contains the `export.build`
file that maps the exe import to the built binary:

```
$ b test: tests/@/tmp/libfoo-tests-out/ \
  config.import.libdep=../libdep-build \
  config.cc.loptions=-L/tmp/install/lib \
  config.bin.rpath=/tmp/install/lib
```

This resolves the executable (and all other targets of that dependency) from
the development tree rather than the install prefix, so it is not a fully
pure installed-case test for that dependency.

**Test the source distribution.** This is how `cppget.org` builds the package.

`bdep ci` (git-based) and the `cppget.org` publish-test step (archive-based)
are **not equivalent**: git-based CI prepares the distribution differently
and does not reliably catch buildfile-graph gaps: missing-from-`buildfile`
source files, targets unreachable from a directory's default `./:` set,
broken `clean` rules for targets only reachable via non-`./:` declarations
(build2/build2#533), custom `fsdir{}` clean recipes whose path aliases
src when `src_base == out_base` (the NEWS directory-symlink pattern used
as a test-data fixture), or a missing `fsdir{}` parent chain (auto-creation
is out-of-tree only, so a forwarded config stays green). The NEWS recipe
fails `b clean` in the unpacked archive while `bdep test` stays green. A
missing parent chain fails in-source `b update` with
`unable to create directory`. See
[test-runtime-fixtures.md](../HOWTO/test-runtime-fixtures.md#source-tree-test-data)
and [fsdir-parent-chain.md](../HOWTO/fsdir-parent-chain.md).

They also differ in which repository graph is used. `bdep ci` consumes the
git repository, so the project's `repositories.manifest` is the repository
manifest. The queue and `cppget.org` publish path is `pkg`: consumers
follow the destination section's complements and prerequisites, not a
nested copy of that file inside the archive. See
[Which repositories.manifest is consulted](packaging-guide-summary.md#which-repositoriesmanifest-is-consulted).

A green `bdep ci` is not sufficient on its own. Always run the full recipe
below, including `clean`, before `bdep publish`. Configure with strict
warnings enabled so any warning upstream source triggers surfaces during
this pass:

```
$ b dist config.dist.root=/tmp/dist config.dist.uncommitted=true
$ cd /tmp/dist/libfoo-<version>/
$ b configure config.cxx=g++ config.cxx.coptions="-Wall -Wextra -pedantic"
$ b update
$ b test
$ b clean
$ rm -r /tmp/dist
```

`config.cxx=clang++` takes the same three options. On MSVC, the equivalent
is `/W4` (breadth roughly matching `-Wall -Wextra`) and `/permissive-`
(standards conformance, roughly matching `-pedantic`):

```
> b configure config.cxx=cl config.cxx.coptions="/W4 /permissive-"
```

(`config.c.coptions` instead of `config.cxx.coptions` for a C library or
executable.)

These options are for this test build only: never add them to the package's
own default `cxx.coptions` (see [Options that do NOT
belong](../HOWTO/buildfile-compile-options.md#options-that-do-not-belong)).
If upstream source triggers a harmless warning (a genuinely unused
variable, a benign sign comparison, and the like), silence that specific
warning with a targeted `-Wno-XXX`/`/wdXXX` addition to the library's own,
non-export `cxx.coptions` instead (see [Options that are
OK](../HOWTO/buildfile-compile-options.md#options-that-are-ok)). Never add
it to `cxx.export.poptions`/`cxx.export.loptions`: exported warning
suppression is a separate, already-covered rule (see [Export
options](../HOWTO/buildfile-compile-options.md#export-options)). Give this
its own small atomic commit late in the `review` branch, scoped to the
warning(s) silenced (see [Atomic
commits](packaging-guide-summary.md#concepts)). Reserve an actual
source patch for a genuine upstream bug the warning has uncovered, and keep
patches to a minimum since each one adds to the package's maintenance
burden (see [Avoid fixing upstream issues in the
package](packaging-guide-antipatterns.md#avoid-fixing-upstream-issues-in-the-build2-package)).

If dependencies cannot be found during `configure`, set each
`config.import.<dep>` to the path of the build configuration that contains
that dependency.

**Remote CI.** These commits belong on `review`, not on `main`. Commit and
push the branch, then submit:

```
$ git add .
$ git commit -m "Add upstream tests"
$ git push -u origin review
$ bdep ci
```

The first push of `review` needs `-u origin review`. Later pushes on the same
branch can use `git push`.

The `bdep ci` command prints a link to the CI job results. Wait until no
configurations remain with `<unbuilt>` or `building` status. If platforms or
compilers are known not to be supported by upstream, exclude them using the
`builds` field in `manifest` rather than spending time on unsupported
combinations.


## Step 10: Publish

### Merge the review branch

Do not perform this merge while packaging. Stay on `review`. After the
first `bdep new` commit, `main` stays untouched until this publish-time
step. Do not `git checkout main` to land work, inspect results, or
"finish" the stretch.

When the packaging stretch is complete (local tests, installed case,
distribution, and CI are green, and the READMEs are adjusted) and you are
ready to transfer, release, and publish, merge `review` into `main`. Use a
fast-forward merge so `main` stays a linear history: the first `bdep new`
project commit, then every packaging commit from `review`.

```
$ git checkout main
$ git merge --ff-only review
$ git push origin main
```

`--ff-only` fails if `main` has moved. That is intentional. `main` should
still be the first `bdep new` commit, so the merge must be a fast-forward. If
it is not, stop and find out why `main` changed before continuing.

After this merge, `main` is the branch you transfer, release, and publish
from. Do not release or publish from `review`. You may delete `review` after
the merge, or leave it pointing at the same commit as `main`.

**Transfer first, then merge.** If you transfer the repository to
`github.com/build2-packaging` while the work is still on `review` (for
example to share a reasonably complete package under the organization), push
`review` and open a pull request with `base:` set to `main` and `compare:`
set to `review`. On `build2-packaging`, `main` is protected, so that pull
request is the only merge path. Merge it when the packaging stretch is
complete, then continue with release and publish from `main`. This is the
same `review` branch, not a new one.

**Transfer the repository** to `github.com/build2-packaging` before publishing
the first version. This is required because the `git` repository URL is used as
a proxy for package name ownership. Transfer via GitHub Settings > Danger Zone >
Transfer. Rename the repository first if it has a `build2-` prefix or
`-package` suffix. If you have not already merged `review` into `main`, do
that first (or transfer first and merge through the pull request described
above).

**Release the final version:**

```
$ bdep release --no-open --show-push
$ git diff HEAD~1
$ git push ...
```

The `--no-open` flag suppresses opening the next development version, which is
correct for third-party packages since the next upstream version is unknown.
`bdep release` updates the `version` in `manifest`, commits, and creates a
`vX.Y.Z` tag.

**Publish:**

```
$ bdep publish
```

`bdep publish` creates a source archive, uploads it to `queue.cppget.org`, and
prints a link. Review the displayed build results and package information.

The uploaded archive is the package directory. The project-level
`repositories.manifest` does not travel with it. Once the package is in a
queue section, same-section packages see each other and the section's
own complements and prerequisites supply the rest. See
[Which repositories.manifest is consulted](packaging-guide-summary.md#which-repositoriesmanifest-is-consulted).

If the package uses a zero major version but upstream does not treat it as
alpha quality, override the target section:

```
$ bdep publish --section=stable
```

After initial submission, the package enters `testing` on `cppget.org` and
awaits a review before being moved to `stable`.

**Ongoing maintenance.** For fixes to the packaging infrastructure after
release, use revisions:

```
$ bdep release --revision --show-push
$ git push ...
$ bdep publish
```

For a new upstream version, create a `wip-X.Y.Z` work branch (not `review`,
which is reserved for the initial packaging stretch), update the `upstream`
submodule, update symlinks, adjust `buildfiles`, test, then merge, release,
and publish. See
[packaging-guide-version-management.md](packaging-guide-version-management.md).


## Common Patterns and Pitfalls

**Always use `bdep new` as a starting point.** Do not write `buildfiles` from
scratch. The generated templates encode years of accumulated best practices and
make the package easier to review and maintain. When editing any scaffold file
after generation, make only package-specific adjustments and preserve the
generated structure and phrasing -- deviations increase review burden and make
the package harder to maintain.

**Keep `PACKAGE-README.md` close to the generated template.** Fill the
`<...>` placeholders with package-specific content. For the summary slot, copy
one to two paragraphs from the upstream documentation. Keep all generated
sections, trimming minimal ones to a single placeholder sentence (e.g.,
"This package has no configuration variables."). Do not add new sections or
pad with content the consumer already has from `README.md`. The generated
structure and ordering are intentional.

An accompanying package (`lib<pkg>-tests`, `-examples`, `-benchmarks`) is
the exception. It does not keep the generated Usage-style template. Use the
short form below, substituting the type in the package name, the
parenthetical heading suffix, and the opening sentence (`test suite`,
`examples`, or `benchmarks`). The title after the hyphen is the same as the
main package heading. Keep Importable targets and Configuration variables
even when empty. The peculiarities paragraph is optional. Only mention a
[patch applied to upstream
source](packaging-guide-antipatterns.md#how-do-i-patch-upstream-source-code)
there if it is useful to and actually affects consumers: a patch with no
consumer-visible effect (e.g. adding a missing `#include`) needs no mention.

```
# lib<pkg>-tests - <same title as main package> (tests)

This is a `build2` package containing the test suite for the
[`<project>`](https://github.com/<org>/<project>) library.
<brief details if there are peculiarities, e.g. a consumer-affecting
patch or noteworthy changes like "using doctest instead of catch2",
or if only a subset of the upstream tests are covered>


## Importable targets

This package exports no targets.


## Configuration variables

This package provides no configuration variables.
```

**Never bundle dependencies.** If upstream vendors a testing framework or
another library, replace it with a proper external dependency. Bundled
dependencies can cause multiple conflicting copies in the same build and make
security fixes difficult to propagate.

**Avoid fixing upstream issues in the package.** Every deviation from upstream
source increases maintenance burden. Prefer reporting issues upstream and
waiting for a fix. If you must patch, use the manual copy + `.orig` +
`.patch` pattern, the `sed`-based ad hoc recipe, or the C preprocessor trick
to avoid modifying upstream symlinks directly. Silencing a harmless compiler
warning with a targeted `-Wno-XXX`/`/wdXXX` buildfile option is not a patch
and carries none of this burden, since it touches no upstream source at all
(see [Step 9](#step-9-test-the-package)).

**Do not build main targets in the root `buildfile`.** Keep libraries and
executables in subdirectory `buildfiles`. The root `buildfile` is loaded during
target importation and loading main targets there also loads all subprojects
(`tests/`, `examples/`), which is wasteful.

**Do not make a library header-only if it can be compiled.** If upstream
provides both modes, use the compiled mode. The compiled mode offers faster
consumer build times and is why upstream provides it. If the compiled mode has
platform issues, work with upstream to fix them rather than defaulting to
header-only.

**Append to build option variables, do not assign.** Use `+=` or `=+` for
`*.poptions`, `*.coptions`, `*.libs`, etc. The user may specify values via
`config.*.*` counterparts that must not be overwritten.

**Libraries with generically named headers** (e.g., `<util.h>`) cannot
coexist. Change the inclusion scheme to use a library subdirectory prefix
(e.g., `<libfoo/util.h>`) and adjust both the installation path and the
internal header search paths accordingly. Such packages cannot use
system-installed versions of the library as a substitute.

**Revisions must be strictly backwards-compatible** and should contain only
minor infrastructure fixes. Substantial changes should wait for the next
upstream version.


## See Also

- [packaging-guide-summary.md](packaging-guide-summary.md) -- concepts, review branch, and steps 1-7
- [bpkg manifest reference](../bpkg/bpkg-manifest-reference.md)
- [build2 modules: cc/cxx](build2-modules-cc.md)
- [build2 core modules: install](build2-modules-core.md)
- [bdep-new](../bdep/bdep-new.md)
- [bdep-ci](../bdep/bdep-ci.md)
- [bdep-release](../bdep/bdep-release.md)
- [bdep-publish](../bdep/bdep-publish.md)
- [third-party-private-headers](../HOWTO/third-party-private-headers.md)
- [test-imported-executable](../HOWTO/test-imported-executable.md): testing a package's own `exe{}` imported into `tests/`
- [test-runtime-fixtures](../HOWTO/test-runtime-fixtures.md): built fixtures, source-tree test data, NEWS `fsdir{}`
- [fsdir-parent-chain](../HOWTO/fsdir-parent-chain.md): `fsdir{}` parent auto-creation is out-of-tree only
- [tests-extra-dependencies](../HOWTO/tests-extra-dependencies.md): accompanying `-tests`/`-examples`/`-benchmarks` packages, summary suffix, PACKAGE-README template
