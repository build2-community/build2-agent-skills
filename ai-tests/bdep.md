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


## T007 -- Default executable source layout

**Query:** What source directory does `bdep new -l c++ -t exe hello` create?

**Key facts** (all must appear in a correct answer):
- Source lives in `hello/hello/`.
- The sample source file is `hello.cxx`.

**Source:** `bdep/bdep-new-layouts.md`


## T008 -- Split library layout

**Query:** What source layout does `bdep new -l c++ -t lib,split libhello` create?

**Key facts** (all must appear in a correct answer):
- Public headers go under `include/libhello/`.
- Sources go under `src/libhello/`.
- `split` is a shortcut for `prefix-include=include,prefix-source=src`.

**Source:** `bdep/bdep-new-layouts.md`


## T009 -- package vs source modes

**Query:** What is the difference between `bdep new --package` and `bdep new --source`?

**Key facts** (all must appear in a correct answer):
- `--package` adds a new package inside an existing project and updates
  `packages.manifest`.
- `--source` adds a source subdirectory inside an existing project or package.
- `--package` is used after `-t empty` for a multi-package repository.
- `--source` is used after `-t bare` for one package with several source
  directories.

**Source:** `bdep/bdep-new-layouts.md`
