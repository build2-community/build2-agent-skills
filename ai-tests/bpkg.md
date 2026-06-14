# Tests: bpkg -- package dependency manager

Source documentation: `bpkg/README.md`, `bpkg/bpkg-cfg-create.md`


## T001 -- Configuration types

**Query:** What are the three predefined configuration types in bpkg, and which
one is the default?

**Key facts** (all must appear in a correct answer):
- The three predefined types are `target`, `host`, and `build2`.
- The default type (when `--type` is not specified) is `target`.
- `--type` is the option used to specify the type explicitly.

**Source:** `bpkg/bpkg-cfg-create.md`


## T002 -- cfg-create alias

**Query:** What is the short alias for the `bpkg cfg-create` command?

**Key facts** (all must appear in a correct answer):
- The alias is `create`.
- The full invocation `bpkg cfg-create` and the alias `bpkg create` are
  equivalent.

**Source:** `bpkg/README.md`


## T003 -- Creating a C++ target configuration

**Query:** Write the `bpkg` command to create a new C++ build configuration
using Clang, with the install root set to `/usr/local`.

**Key facts** (all must appear in a correct answer):
- The command uses `bpkg create` (or `bpkg cfg-create`).
- The `cxx` module is listed as a positional argument.
- `config.cxx=clang++` sets the compiler.
- `config.install.root=/usr/local` sets the install root.

**Source:** `bpkg/bpkg-cfg-create.md`


## T004 -- Private host configuration

**Query:** What does bpkg do when a dependency requires a host configuration
but none is linked to the current configuration?

**Key facts** (all must appear in a correct answer):
- bpkg automatically creates a private host configuration named `host`.
- Similarly, a private build system module configuration named `build2` is
  created if none is linked and the `build2` type is needed.

**Source:** `bpkg/bpkg-cfg-create.md`


## T005 -- pkg-build alias

**Query:** What is the short alias for `bpkg pkg-build`?

**Key facts** (all must appear in a correct answer):
- The alias is `build`.

**Source:** `bpkg/README.md`


## T006 -- rep-fetch purpose

**Query:** What does `bpkg rep-fetch` do?

**Key facts** (all must appear in a correct answer):
- It fetches the list of available packages from added repositories.
- It does not build or install anything; it only updates the local package
  index.

**Source:** `bpkg/bpkg-rep-fetch.md`
