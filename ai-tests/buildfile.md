# Tests: buildfile -- language and directives

Source documentation: `guides/build2-buildfile-language.md`,
`guides/build2-directives-patterns.md`, `guides/build2-intro-concepts.md`,
`guides/build2-targets-variables.md`


## T001 -- Variable assignment operators

**Query:** What are the four variable assignment operators in build2 buildfiles
and what does each one do?

**Key facts** (all must appear in a correct answer):
- `=` replaces the existing value with the new one.
- `+=` appends the right-hand side to the end of the existing value.
- `=+` prepends the right-hand side before the existing value.
- `?=` assigns the value only if the variable is currently undefined.

**Source:** `guides/build2-targets-variables.md`


## T002 -- Automatic scope variables

**Query:** What are the four path variables set automatically in every build2
scope, and what does each hold?

**Key facts** (all must appear in a correct answer):
- `src_root` holds the absolute path to the project's source root directory.
- `out_root` holds the absolute path to the project's output root directory.
- `src_base` holds the absolute path to the current scope's source directory.
- `out_base` holds the absolute path to the current scope's output directory.
- `src_root` and `out_root` are set on the project root scope.
- `src_base` and `out_base` are set on each directory scope.

**Source:** `guides/build2-targets-variables.md`, `guides/build2-intro-concepts.md`


## T003 -- Wildcard pattern characters

**Query:** What do the wildcard characters `*`, `?`, `**`, and `***` each match
in build2 name patterns, and how do `**` and `***` differ?

**Key facts** (all must appear in a correct answer):
- `*` matches any number of characters within a single directory.
- `?` matches any single character.
- `**` matches any number of characters across subdirectories recursively,
  excluding `.buildignore` directories, but does not include the starting
  directory itself.
- `***` is like `**` but also includes the starting directory itself.

**Source:** `guides/build2-directives-patterns.md`


## T004 -- include vs source directives

**Query:** What is the difference between the `include` and `source` directives
in build2 buildfiles?

**Key facts** (all must appear in a correct answer):
- `include` loads the specified file into its corresponding directory scope.
- `source` loads the specified file into the current scope (as if the contents
  were pasted inline).
- `include` automatically ignores subsequent inclusions of the same file
  (re-inclusion is silently skipped).
- `source` can load the same file multiple times.

**Source:** `guides/build2-directives-patterns.md`


## T005 -- import directive

**Query:** What is the syntax of the `import` directive in build2, what does
the `!` form do, and can you show a concrete example?

**Key facts** (all must appear in a correct answer):
- The basic syntax is `import <var> = <project>%<target>`.
- The build system locates the named project and makes its exported target
  available as the value of `<var>`.
- The `!` form (`import! <var> = <project>%<target>`) makes the import
  required: the build fails with an error if the project is not found.
- Example: `import libs = libhello%lib{hello}` (optional import).
- Example: `import! foo = foo%exe{foo}` (required import).

**Source:** `guides/build2-directives-patterns.md`


## T006 -- define directive

**Query:** What does the `define` directive do in build2, what is its syntax,
and can you show a short example?

**Key facts** (all must appear in a correct answer):
- `define` derives a new project-local target type from an existing base type.
- The syntax is `define <derived>: <base>`.
- The new type can be assigned a default extension via a type/pattern-specific
  variable.
- Example: `define md: doc` derives a new type `md` from `doc`, and
  `doc{*}: extension = md` sets the default extension to `.md`.

**Source:** `guides/build2-directives-patterns.md`
