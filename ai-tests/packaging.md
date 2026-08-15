# Tests: packaging -- third-party packaging workflow

Source documentation: `guides/packaging-guide-summary.md`, `guides/packaging-guide-testing.md`, `guides/packaging-guide-version-management.md`, `bdep/bdep-publish.md`, `bdep/bdep-release.md`, `HOWTO/require-dependency-feature.md`


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


## T007 -- require vs reflect

**Query:** In a multi-line `depends` clause, what is the difference between
`require` and `reflect`?

**Key facts** (all must appear in a correct answer):
- `require` sets the dependency's `bool` config vars to `true`.
- `reflect` copies a negotiated value into the dependent's own `config.*`
  vars.
- `require` and `reflect` are not a pair.
- A `depends` alternative is `require` or `prefer`/`accept`, and optionally
  `reflect` after that.

**Source:** `HOWTO/require-dependency-feature.md`


## T008 -- require alone is valid

**Query:** How do you turn on a sibling package's boolean feature from a
`depends` entry, and do you need `reflect`?

**Key facts** (all must appear in a correct answer):
- Use a multi-line `depends` with `require` alone.
- Example shape: `require { config.liblodepng.cpp = true }`.
- Do not add `reflect` unless this package must read the negotiated value in
  a later `depends` or in its own buildfile.

**Source:** `HOWTO/require-dependency-feature.md`


## T009 -- Initial packaging review branch

**Query:** For a new third-party package, which commit belongs on main, where
does the rest of the initial packaging work happen, and how does that work
land on main?

**Key facts** (all must appear in a correct answer):
- The first commit on `main` is the `bdep new --type empty,third-party` project commit.
- That first commit contains only files generated by `bdep new`.
- After that first commit, leave `main` untouched until the publish-time merge.
- Further initial packaging work happens on a branch named `review`, created from that same `main` commit.
- Do not check out `main` or merge into it during the packaging stretch.
- At publish time, merge `review` into `main` with a fast-forward merge.
- Release and publish from `main` after that merge.

**Source:** `guides/packaging-guide-summary.md`, `guides/packaging-guide-testing.md`


## T010 -- Which repositories.manifest is consulted

**Query:** When package B depends on package A, which `repositories.manifest`
is consulted, and does a nested copy inside a published package archive
participate?

**Key facts** (all must appear in a correct answer):
- Resolution follows the repository the consumer added, plus that repository's own complements and prerequisites.
- It does not follow a nested `repositories.manifest` inside a package archive.
- For a `git` or `dir` repository, the project's `repositories.manifest` is the repository manifest.
- For a `pkg` repository, the section directory has its own `repositories.manifest`.

**Source:** `guides/packaging-guide-summary.md`


## T011 -- Complements, prerequisites, and same-section visibility

**Query:** In a `pkg` section, how do complements and prerequisites differ, and
do packages that already live in the same section need to list each other?

**Key facts** (all must appear in a correct answer):
- Complements make another repository's packages look as if they were in this one.
- Prerequisites make another repository's packages available as dependencies only.
- Packages that already live in the same section are visible to each other with no extra listing.
- A package in a more-stable section cannot see one that exists only in a less-stable complement.

**Source:** `guides/packaging-guide-summary.md`


## T012 -- Queue publish and git fallbacks

**Query:** Can package B be published to `queue.cppget.org` without listing
package A's git URL if A is already in the queue, and should a long-lived
project keep git fallbacks or the queue itself in `repositories.manifest`?

**Key facts** (all must appear in a correct answer):
- The queue is a `pkg` repository that recreates the public sections.
- Same-section queued packages see each other.
- `queue/testing` prerequisites public `testing`.
- `queue/beta` complements `queue/testing`.
- A queued testing package cannot see a queued alpha package.
- B can be published without A's git URL once A is in the same queue section or the matching public section.
- A published archive is just the package directory, so project-level git fallbacks have no effect on `pkg` consumers.
- Git prerequisite lines exist only for git/dir consumers.
- Do not leave a transient repository (the queue is the usual example) in a long-lived project's `repositories.manifest`.

**Source:** `guides/packaging-guide-summary.md`, `guides/packaging-guide-testing.md`, `bdep/bdep-publish.md`
