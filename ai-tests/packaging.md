# Tests: packaging -- third-party packaging workflow

Source documentation: `guides/packaging-guide-summary.md`, `guides/packaging-guide-version-management.md`, `bdep/bdep-publish.md`, `bdep/bdep-release.md`


## T001 -- Third-party repo layout

**Query:** Where is upstream source code placed in a third-party build2 package
repository, and what technique is used to overlay build2 files onto it?

**Key facts** (all must appear in a correct answer):
- The upstream repository is imported as a `git` submodule in the `upstream/`
  subdirectory of the package repository.
- Symlinks from the package directory tree point into `upstream/` to
  non-invasively overlay `build2` build files over the upstream source code.
- This keeps upstream source code unmodified and makes updating to a new
  upstream release straightforward.

**Source:** `guides/packaging-guide-summary.md`


## T002 -- Starting a new third-party package

**Query:** What `bdep new` invocation is used to create the initial scaffold
for a third-party package repository?

**Key facts** (all must appear in a correct answer):
- The command is `bdep new --type empty,third-party`.
- The `empty` type creates a repository scaffold without a package.
- The `third-party` sub-option sets `no-version`, `no-symexport`, and adds
  packaging metadata fields to `manifest`.

**Source:** `guides/packaging-guide-summary.md`


## T003 -- Interface vs. implementation dependencies

**Query:** What is the difference between interface dependencies and
implementation dependencies in a build2 library buildfile?

**Key facts** (all must appear in a correct answer):
- A dependency is an interface dependency (`intf_libs`) if the dependency's
  headers appear in the library's own public headers, making the dependency
  part of the library's interface.
- Otherwise the dependency is an implementation dependency (`impl_libs`).
- Interface dependencies are re-exported to consumers via
  `cxx.export.libs = $intf_libs`.

**Source:** `guides/packaging-guide-summary.md`


## T004 -- Revision release single-commit requirement

**Query:** What is the single-commit requirement for a revision release, and
which `bdep release` options can be used to meet it when working on a separate
branch?

**Key facts** (all must appear in a correct answer):
- All changes in a revision, including the version increment, must belong to a
  single commit (continuous versioning requires every commit to carry the
  revision increment).
- `--amend` releases a revision by amending the latest commit.
- `--squash <num>` squashes the specified number of previous commits before
  amending. Requires `--amend`.

**Source:** `guides/packaging-guide-version-management.md`


## T005 -- bdep publish default repository

**Query:** What is the default repository that `bdep publish` submits to, and
how is the repository section determined when none is specified explicitly?

**Key facts** (all must appear in a correct answer):
- The default repository is `cppget.org`.
- If no section is specified with `--section`, one of `alpha`, `beta`, or
  `stable` is automatically derived from the package version.

**Source:** `bdep/bdep-publish.md`


## T006 -- build2-control branch

**Query:** What is the `build2-control` branch used for during publishing, and
what is added to it?

**Key facts** (all must appear in a correct answer):
- Before sending the submission request, `bdep publish` adds the package
  archive checksum to the `build2-control` branch of the project's version
  control repository.
- The archive repository uses this branch to verify that the submitter is
  authorized to publish the archive under the package name.

**Source:** `bdep/bdep-publish.md`
