# build2 Packaging Guide -- Testing and Publishing

Steps 8-10 of the third-party packaging workflow: writing tests, validating
the package, and publishing to `cppget.org`.

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
  package to avoid making the library depend on the testing framework)
- Single or multiple test executables
- Internal utility libraries shared across test executables (use `libue{}`
  utility libraries in `build2`)
- Runtime fixtures: child processes or data built alongside the tests (mark
  with `test = false`, attach as `include = adhoc` prerequisites of the
  **test executable**, not the testscript, so `update-for-test` and
  test-installed still build them). See
  [test-runtime-fixtures.md](../HOWTO/test-runtime-fixtures.md).
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
and does not reliably catch buildfile-graph gaps -- missing-from-`buildfile`
source files, targets unreachable from a directory's default `./:` set, or
broken `clean` rules for targets only reachable via non-`./:` declarations
(build2/build2#533). A green `bdep ci` is not sufficient on its own. Always
run the full recipe below, including `clean`, before `bdep publish`:

```
$ b dist config.dist.root=/tmp/dist config.dist.uncommitted=true
$ cd /tmp/dist/libfoo-<version>/
$ b configure config.cxx=g++
$ b update
$ b test
$ b clean
$ rm -r /tmp/dist
```

If dependencies cannot be found during `configure`, set each
`config.import.<dep>` to the path of the build configuration that contains
that dependency.

**Remote CI.** Commit and push, then submit:

```
$ git add .
$ git commit -m "Add upstream tests"
$ git push
$ bdep ci
```

The `bdep ci` command prints a link to the CI job results. Wait until no
configurations remain with `<unbuilt>` or `building` status. If platforms or
compilers are known not to be supported by upstream, exclude them using the
`builds` field in `manifest` rather than spending time on unsupported
combinations.


## Step 10: Publish

**Transfer the repository** to `github.com/build2-packaging` before publishing
the first version. This is required because the `git` repository URL is used as
a proxy for package name ownership. Transfer via GitHub Settings > Danger Zone >
Transfer. Rename the repository first if it has a `build2-` prefix or
`-package` suffix.

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

For a new upstream version, create a work branch, update the `upstream`
submodule, update symlinks, adjust `buildfiles`, test, then merge, release,
and publish.


## Common Patterns and Pitfalls

**Always use `bdep new` as a starting point.** Do not write `buildfiles` from
scratch. The generated templates encode years of accumulated best practices and
make the package easier to review and maintain. When editing any scaffold file
after generation, make only package-specific adjustments and preserve the
generated structure and phrasing -- deviations increase review burden and make
the package harder to maintain.

**Keep `PACKAGE-README.md` close to the generated template.** Fill the
`<...>` placeholders with package-specific content; for the summary slot, copy
one to two paragraphs from the upstream documentation. Keep all generated
sections, trimming minimal ones to a single placeholder sentence (e.g.,
"This package has no configuration variables."). Do not add new sections or
pad with content the consumer already has from `README.md`. The generated
structure and ordering are intentional.

**Never bundle dependencies.** If upstream vendors a testing framework or
another library, replace it with a proper external dependency. Bundled
dependencies can cause multiple conflicting copies in the same build and make
security fixes difficult to propagate.

**Avoid fixing upstream issues in the package.** Every deviation from upstream
source increases maintenance burden. Prefer reporting issues upstream and
waiting for a fix. If you must patch, use the manual copy + `.orig` +
`.patch` pattern, the `sed`-based ad hoc recipe, or the C preprocessor trick
to avoid modifying upstream symlinks directly.

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

- [packaging-guide-summary.md](packaging-guide-summary.md) -- concepts and steps 1-7
- [bpkg manifest reference](../bpkg/bpkg-manifest-reference.md)
- [build2 modules: cc/cxx](build2-modules-cc.md)
- [build2 core modules: install](build2-modules-core.md)
- [bdep-new](../bdep/bdep-new.md)
- [bdep-ci](../bdep/bdep-ci.md)
- [bdep-release](../bdep/bdep-release.md)
- [bdep-publish](../bdep/bdep-publish.md)
- [third-party-private-headers](../HOWTO/third-party-private-headers.md)
- [test-imported-executable](../HOWTO/test-imported-executable.md) -- testing a package's own `exe{}` imported into `tests/`
