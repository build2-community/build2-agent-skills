# Tests: bpkg (advanced) -- pkg-build, pkg-status, pkg-bindist, brep-load

Source documentation: `bpkg/bpkg-pkg-build.md`, `bpkg/bpkg-pkg-status.md`, `bpkg/bpkg-pkg-bindist.md`, `brep/brep-load.md`, `bdep/bdep-release.md`


## T001 -- ? prefix in pkg-build

**Query:** What does the `?` prefix on a package name in `bpkg pkg-build`
mean, and how does it differ from a held package in terms of automatic removal?

**Key facts** (all must appear in a correct answer):
- The `?` prefix (equivalent to `--dependency`) builds the package as a
  dependency rather than to hold.
- A dependency package is only kept while it has dependents and is dropped
  automatically when it no longer has any.
- A held package will not be automatically removed even if it loses all
  dependents.

**Source:** `bpkg/bpkg-pkg-build.md`


## T002 -- sys: scheme

**Query:** What does the `sys:` prefix mean in `bpkg pkg-build`, what does the
`/*` wildcard version indicate, and what does `--sys-no-query` do?

**Key facts** (all must appear in a correct answer):
- The `sys:` prefix treats the package as provided by the system rather than
  building it from source.
- The `/*` wildcard version means the version is unknown but satisfies any
  version constraint.
- Without an explicit version, `pkg-build` queries the system package manager
  for the installed version (unless unsupported or disabled), falling back to
  `/*`.
- `--sys-no-query` disables querying the system package manager for the
  installed version.

**Source:** `bpkg/bpkg-pkg-build.md`


## T003 -- pkg-bindist formats

**Query:** What are the three supported output format names for
`bpkg pkg-bindist` and what does each produce?

**Key facts** (all must appear in a correct answer):
- `debian` -- produces `.deb` packages via `dpkg-buildpackage`, for Debian
  and similar distributions (Ubuntu, etc.).
- `fedora` -- produces `.rpm` packages via `rpmbuild`, for Fedora and similar
  distributions (RHEL, CentOS, etc.).
- `archive` -- produces an installation archive (`tar.xz`, `tar.gz`, `zip`,
  etc. via `tar`/`zip`) on any OS.

**Source:** `bpkg/bpkg-pkg-bindist.md`


## T004 -- pkg-status status words

**Query:** What are all the status words that `bpkg pkg-status` can output,
and what does each one mean?

**Key facts** (all must appear in a correct answer):
- `unknown` -- the package is not part of the configuration nor available from
  any of the repositories.
- `available` -- the package is not part of the configuration but is available
  from one of the repositories.
- `fetched` -- the package is part of the configuration and is fetched.
- `unpacked` -- the package is part of the configuration and is unpacked.
- `configured` -- the package is part of the configuration and is configured.
- `broken` -- the package is part of the configuration and is broken; broken
  packages can only be purged.

**Source:** `bpkg/bpkg-pkg-status.md`


## T005 -- brep-load exit codes

**Query:** What are all the exit codes for `brep-load` and what does each mean?

**Key facts** (all must appear in a correct answer):
- `0` -- success.
- `1` -- fatal error.
- `2` -- an instance of `brep-load` or another `brep` utility is already
  running; try again.
- `3` -- recoverable database error; try again.

**Source:** `brep/brep-load.md`


## T006 -- bdep release modes

**Query:** What are the two main modes of `bdep release` and which flag
triggers revision mode?

**Key facts** (all must appear in a correct answer):
- Version mode (default) changes the snapshot version to the corresponding
  release version in each package's `manifest`, commits, tags, and optionally
  opens the next development cycle.
- Revision mode increments the current version's revision component in each
  package's `manifest`, commits, and tags the result.
- The `--revision` flag triggers revision mode.

**Source:** `bdep/bdep-release.md`
