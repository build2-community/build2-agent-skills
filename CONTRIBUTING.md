# Contributing

This document explains how to keep the three navigation indexes in sync when
adding, renaming, or removing files. Read [README.md](README.md) first for
the repository layout and structural conventions.

## Adding a new file

Three indexes must be updated every time a guide, HOWTO, reference, script,
or workflow skill file is added.

1. Add a line to `llms.txt` under the appropriate section heading. Follow the
   description style described below.

2. Add a row to the when-to-use table in `SKILL.md`. Follow the entry style
   described below.

3. Add a navigation link under the relevant heading in `INDEX.md`. The
   description should mirror the one in `llms.txt`.

4. If the file is a HOWTO or a workflow skill, also add a row to
   `HOWTO/README.md` or `skills/README.md`.

5. Run `scripts/check-links.sh` from the repository root and confirm it exits
   with status 0.

## Adding a workflow skill

A workflow skill is a procedure that sits on top of the guides and HOWTOs
in this repository (for example end-to-end packaging). It lives at
`skills/<name>/SKILL.md`. The directory name must match the YAML `name`
field.

1. Create `skills/<name>/SKILL.md` with YAML frontmatter (`name` and
   `description`).
2. Resolve `ROOT` (the `build2` skill tree) to the first candidate that
   contains a known guide file:
   - `HERE/../build2` (sibling copy into a user-level skills directory)
   - `HERE/../..` (nested under this repository's `skills/`)
   If neither exists, stop.
3. Point every `read_file` path at `${ROOT}/...`. Do not use
   `../build2/guides/...` relative links. Those break in the nested
   layout. Sibling links between workflow skills (`../<other>/SKILL.md`)
   are fine: they are peers under `skills/`.
4. Update the three indexes as for any other file, under the
   "Workflow skills" heading in `llms.txt` and `INDEX.md`, and add a row
   to `skills/README.md`.
5. Run `scripts/check-links.sh`.

## Renaming or removing a file

Apply the same index updates described above (removing or correcting the
old entry, adding the new one). In addition, search for any `See Also` links
in other files that point to the renamed or removed file and correct them.
Broken `See Also` links will be caught by `scripts/check-links.sh`.

## Description style for llms.txt

Each entry is a single line with this format:

```
- [path](path): <noun phrase> -- <topic>, <topic>, <topic>.
```

The noun phrase names the subject of the file. After ` -- `, list the major
topics covered, separated by commas, ending with a full stop. Keep the entire
entry on one line. See the existing entries in `llms.txt` for style examples.

## Entry style for SKILL.md

The when-to-use table maps a task description to a single file path:

```
| <Imperative verb phrase> | [path](path) |
```

The task column uses an imperative verb phrase (for example, "Link a system
library" or "Publish a package"). Place the new row in the section that best
matches the task's primary tool or topic. See the existing table in `SKILL.md`
for style examples.

## Entry style for INDEX.md

Navigation links appear under the heading for the relevant tool or section:

```
- [path](path): <description matching llms.txt>
```

The description should be the same noun-phrase-plus-topics form used in
`llms.txt`. See the existing navigation section in `INDEX.md` for style
examples.

## Running the link checker

Run the following command from the repository root before committing:

```sh
scripts/check-links.sh
```

The script exits 0 when all relative Markdown links in tracked files resolve
to existing paths. It exits 1 and prints any broken links found.

## Accuracy

All technical claims in contributed files must be confirmed against an
upstream source before committing. The submodule paths that provide
authoritative upstream material are:

- `.submodules/build2/` -- b, bx option descriptions, command synopses, and
  concept documentation (buildfile language, testscript)
- `.submodules/bpkg/` -- bpkg option descriptions, command synopses, and the
  package manifest reference
- `.submodules/bdep/` -- bdep option descriptions and command synopses
- `.submodules/libbutl/` -- testscript builtin command reference
- `.submodules/build2-toolchain/` -- installation and packaging guide
  concept documentation (its own top-level `doc/`, not its nested
  submodules), except for `.submodules/build2-toolchain/libbpkg/` (see
  below)
- `.submodules/build2-toolchain/libbpkg/` -- package manifest
  build-constraint resolution logic (`effective_constraints()`,
  `effective_builds()`); this nested submodule must be initialized
  separately (`git submodule update --init` from within
  `.submodules/build2-toolchain/`)
- `.submodules/build2-howto/` -- HOWTO recipe content
- `.submodules/libbuild2-autoconf/` -- autoconf module source and builtin
  check catalog
- `.submodules/libbuild2-kconfig/` -- kconfig module source and manual
- `.submodules/build2-brep/` -- brep utility option descriptions and request
  handling protocols
