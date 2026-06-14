# Tests: bdep -- project dependency manager

Source documentation: `bdep/README.md`, `bdep/bdep-new.md`, `bdep/bdep-init.md`


## T001 -- Project types for bdep new

**Query:** What are the four project types available with `bdep new --type`?

**Key facts** (all must appear in a correct answer):
- `exe` -- builds a sample executable.
- `lib` -- builds a sample library.
- `bare` -- project skeleton without source files.
- `empty` -- empty project to be filled with packages.

**Source:** `bdep/bdep-new.md`


## T002 -- Default project type

**Query:** What project type does `bdep new` use when `--type` is not specified?

**Key facts** (all must appear in a correct answer):
- The default type is `exe`.

**Source:** `bdep/bdep-new.md`


## T003 -- Language and type flags

**Query:** What are the short flag aliases for specifying language and type
in `bdep new`?

**Key facts** (all must appear in a correct answer):
- `-l` is the short alias for `--lang`.
- `-t` is the short alias for `--type`.

**Source:** `bdep/bdep-new.md`


## T004 -- Header-only library

**Query:** How do you create a header-only (binless) library project with
`bdep new`?

**Key facts** (all must appear in a correct answer):
- Use `--type lib` (or `-t lib`) with the `binless` sub-option.
- Example: `-t lib,binless`

**Source:** `bdep/bdep-new.md`


## T005 -- bdep init --empty

**Query:** What does `bdep init --empty` do?

**Key facts** (all must appear in a correct answer):
- It initializes an empty project database.
- No packages are added to any build configuration.
- It is equivalent to the `--empty` / `-E` flag.

**Source:** `bdep/bdep-init.md`


## T006 -- bdep sync purpose

**Query:** What is the purpose of `bdep sync`?

**Key facts** (all must appear in a correct answer):
- It synchronizes the project's `manifest`/`lockfile` dependency declarations
  with the actual state of the linked build configurations.
- It resolves and fetches any missing or updated dependencies.

**Source:** `bdep/README.md`
