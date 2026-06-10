# Glossary

**ad hoc** -- A target or prerequisite that is injected into the build graph
at match or execute time rather than being statically declared in a buildfile.
Ad hoc targets are often used for generated headers, companion files, or other
outputs whose names are not known until a rule examines its inputs.

**amalgamation** -- A build system scope that contains other projects as
sub-projects. An amalgamation provides a shared configuration and a common
import namespace so that sub-projects can find each other without explicit
path hints. In bpkg terms, every build configuration is an amalgamation: it
is a project whose sub-projects are the installed packages.

**buildfile** -- The file read by the build system driver `b` to determine
what to build and how. Buildfiles declare targets, their prerequisites, and
the scopes they belong to. A project typically has a root buildfile and one
buildfile per source subdirectory. The build system looks for a file named
`buildfile` in the target directory or the corresponding source directory when
performing an out-of-source build.

**buildspec** -- The build specification passed to `b` on the command line.
Its general form is `<meta-operation>(<operation>(<target>...))`. All parts
are optional: if the meta-operation is omitted it defaults to `perform`, if
the operation is omitted it defaults to the meta-operation's default (usually
`update`), and if the target is omitted it defaults to the current directory.
A shortcut syntax using a trailing colon is also available, for example
`b clean: foo/`.

**configuration (bpkg sense)** -- A directory that acts as a bpkg-managed
build environment. It contains packages built with a consistent set of
settings (compiler, optimisation flags, target architecture, etc.).
Configurations are ordinary directories and can be moved or copied, though a
move may mark some packages as out-of-date. In build system terms a bpkg
configuration is an amalgamation whose sub-projects are the managed packages.

**configuration linking** -- A bpkg feature that allows one configuration to
depend on packages built in another configuration. When configurations are
linked, a package in the primary configuration can list a package from a
linked configuration as a dependency without building it locally. This is
useful for separating host tools from target libraries.

**forward configuration** -- An arrangement where a project's source
directory is configured to automatically delegate builds to an out-of-source
output directory. When the build system driver is invoked from the source
directory it detects the forwarding, builds in the output directory, and
symlinks or otherwise backlinks interesting targets (executables, etc.) back
into the source tree for convenient access.

**held package** -- A package that was explicitly requested by the user via
`bpkg build`. Held packages are not automatically dropped when no other
package depends on them. Dependency packages that were pulled in automatically
are not held and can be dropped when they are no longer needed.

**iteration** -- A version refinement that does not change the version string
itself but indicates that the package manifest or build logic has been updated.
Iterations are expressed as a `#N` suffix on a version, for example
`1.0.0-a.1#2`. bdep shows a pending iteration as an available upgrade for
the project package even when the base version has not changed.

**lockfile** -- A file in a package directory that records the exact resolved
versions of all direct and transitive dependencies. The lockfile is committed
to version control and ensures that all developers and CI systems use
identical dependency versions. bdep updates the lockfile automatically when
`bdep sync` resolves or changes dependency versions.

**meta-operation** -- A higher-level build action that wraps one or more
operations. The built-in meta-operations are `perform` (execute an operation),
`configure` (save configuration to `build/config.build`), `disfigure` (remove
saved configuration), `create` (create and configure a configuration project),
`dist` (prepare a distribution), and `info` (print project metadata). Compare
with operation, which describes what to do to a target.

**module** -- A loadable extension to the build system that adds support for
a language, tool, or feature. Modules are loaded in `bootstrap.build` or
`root.build` with the `using` directive, for example `using cxx` or
`using install`. Common modules include `cxx`, `cc`, `c`, `test`, `install`,
`dist`, `config`, `version`, and `kconfig`.

**operation** -- A concrete action applied to a build target, such as
`update`, `clean`, `test`, `install`, or `uninstall`. Operations are invoked
under a meta-operation: the most common pairing is `perform(update(...))`,
which is the default when running `b` with no extra arguments. Some operations
have associated pre-operations, for example `test` automatically runs
`update` first.

**out-of-source build** -- A build where source files and generated output
files live in separate directories, referred to as `src_root` and `out_root`.
The build system driver maps between these two trees when looking for
buildfiles and target files. Out-of-source builds allow the same source tree
to be built with different configurations simultaneously.

**package** -- A directory containing a `build2` project together with a
`manifest` file that describes the package name, version, dependencies, and
other metadata. Packages are the unit of distribution and dependency
resolution in bpkg. A package can be stored in an archive (`.tar.gz`), a
directory on the filesystem, or checked out from a version control system.

**package manifest** -- The `manifest` file at the root of a package
directory. It records the package name, version, project association, license,
summary, URL, dependency constraints, and other fields. bpkg reads this file
to determine what other packages are required and what version constraints
must be satisfied. bdep reads it to detect changes that require a
re-synchronisation.

**prerequisite** -- The right-hand side of a dependency declaration in a
buildfile, for example the `libhello%lib{hello}` in `exe{hello}: libhello%lib{hello}`.
A prerequisite is a typed target reference that the build system must bring
up to date before building the dependent target. Prerequisites form the edges
of the build graph.

**project (bdep sense)** -- A VCS-managed directory (usually a git
repository) that contains one or more packages. bdep operates at the project
level: it associates the project with one or more bpkg build configurations
and synchronises the state of those configurations with the project's
`manifest` and `lockfile` files. A project's bdep state is stored under
`.bdep/` in the project root.

**project package vs dependency package** -- In bdep terminology, packages
that live inside the current project repository are called project packages.
Packages from external repositories that the project depends on are called
dependency packages. The same package can be a project package in one
developer's repository and a dependency package in another's.

**repository** -- A collection of packages that bpkg can query and fetch
from. Three types are supported: `pkg` (an archive-based repository such as
`https://pkg.cppget.org/`), `git` (a version-control repository where
packages are stored as branches or tags), and `dir` (a local directory
containing package directories). Repositories can list other repositories
as prerequisites or complements, forming a dependency network.

**rule** -- The mechanism inside the build system that knows how to produce a
specific target type from its prerequisites. When the build system matches a
target, it searches for a rule that can handle the target-prerequisite
combination and then executes that rule's update, clean, or other action.
Modules typically register rules for the target types they introduce.

**scope** -- A build system concept that groups targets, variables, and rules
within a portion of the build graph. Scopes correspond roughly to directories:
each directory processed by the build system gets a scope. Variables set in a
scope are visible to nested scopes but not to parent scopes by default.
The root scope of a project and its amalgamation scopes provide the
configuration inheritance hierarchy.

**stub** -- A minimal package that contains only a `manifest` file and no
source code of its own. Stubs are used to represent system-provided libraries
or tools in the bpkg dependency graph. A stub satisfies a dependency
constraint and prevents bpkg from trying to build the package from source.

**sys scheme** -- A package scheme prefix (`sys:`) used with `bpkg build`
to declare that a dependency should be satisfied by a system-installed
package rather than built from source. For example, `bpkg build sys:zlib`
tells bpkg to treat the system zlib as the provider of the `zlib` package.
The version can be specified explicitly or left for bpkg to query from the
system package manager.

**target type** -- A typed handle for a build artifact, written as
`type{name}` in buildfiles. Examples include `exe{hello}`, `lib{hello}`,
`cxx{hello}`, `hxx{config}`, `doc{README}`, and `dir{tests}`. Target types
determine which rules can match a target and how the target's file name is
constructed. Modules introduce new target types together with the rules that
produce them.

**target-prerequisite relationship** -- The fundamental edge in the build
graph, declared in a buildfile as `target: prereq1 prereq2 ...`. It asserts
that `target` cannot be built or considered up-to-date until all listed
prerequisites are themselves up-to-date. The build system traverses these
relationships to determine the correct build order and to detect what needs
rebuilding after a change.

**toolchain** -- The set of programs used to compile and link code: compiler,
linker, assembler, archiver, and related tools. In build2, the toolchain is
selected and configured through module variables such as `config.cxx`,
`config.cc.coptions`, and `config.cc.loptions`. A bpkg configuration is
typically created with a specific toolchain in mind, for example
`bpkg create cc config.cxx=clang++`.
