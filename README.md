# ai-skills-build2

Structured, AI-consumable knowledge of the [build2](https://build2.org)
C/C++ toolchain ecosystem. Content is derived from the canonical upstream
sources listed below and organised according to the
[Agent Skills specification](https://github.com/anthropics/skills).

## Authoritative upstream sources

| Source | Role |
|--------|------|
| [`build2/build2`](https://github.com/build2/build2) submodule | `b`/`bx` `.cli` source files; authoritative for the build system driver, task runner, and buildfile/testscript language documentation |
| [`build2/bpkg`](https://github.com/build2/bpkg) submodule | `.cli` source files; authoritative for all `bpkg` option descriptions, command synopses, and the package manifest reference |
| [`build2/bdep`](https://github.com/build2/bdep) submodule | `.cli` source files; authoritative for all `bdep` option descriptions and command synopses |
| [`build2/libbutl`](https://github.com/build2/libbutl) submodule | `.cli` source files; authoritative for the testscript builtin command reference |
| [`build2/build2-toolchain`](https://github.com/build2/build2-toolchain) submodule | Toolchain amalgamation's own top-level `.cli` and `.md` files; authoritative for installation and packaging guide concept documentation |
| [`build2/build2-howto`](https://github.com/build2/build2-howto) submodule | HOWTO entries; authoritative for all recipe content |
| [`build2/libbuild2-autoconf`](https://github.com/build2/libbuild2-autoconf) submodule | Autoconf emulation module; authoritative for builtin check catalog and module README |
| [`build2/libbuild2-kconfig`](https://github.com/build2/libbuild2-kconfig) submodule | Kconfig emulation module; authoritative for the module manual and README |
| [`build2/brep`](https://github.com/build2/brep) submodule | Repository web interface; authoritative for brep utility option descriptions and request handling protocols |
| [`build2/libbuild2-hello`](https://github.com/build2/libbuild2-hello) submodule | Reference custom module implementation; authoritative for the module API pattern, development workflow, and bootstrap module guidance |
| [Agent Skills specification](https://github.com/anthropics/skills) | Governs the entry-point contract (`SKILL.md`), YAML frontmatter schema, progressive-disclosure model, and file-focus guidance applied throughout |
| [NVIDIA/skills](https://github.com/NVIDIA/skills) | Reference implementation closest in structure to this repository; used as a concrete model for the troubleshooting catalog, "When to use" hints, and per-command "See also" sections |

Content in `b/`, `bx/`, and `guides/` covering the build system driver,
buildfile language, and testscript (except `build2-modules-autoconf.md` and
the kconfig guides) is derived from the `build2` submodule. Content in
`bpkg/` is derived from `bpkg`. Content in `bdep/` is derived from `bdep`.
The testscript builtin reference is derived from `libbutl`. The
installation and packaging guides are derived from `build2-toolchain`'s own
top-level files. Content in `HOWTO/` is derived from `build2-howto`. Content
in `brep/` is derived from `build2-brep`. The builtin check catalog in
`.docs/libbuild2-autoconf/checks/` is derived from `libbuild2-autoconf`. The
kconfig guides are derived from `libbuild2-kconfig`. Do not edit derived
content directly. Patch the upstream submodule instead, then re-run
`./init-docs.sh false` to regenerate `.docs/`.

## Repository layout

| Path | Contents |
|------|----------|
| `SKILL.md` | Skill entry point: YAML frontmatter and when-to-use table |
| `INDEX.md` | Ecosystem overview, full command lookup tables, all navigation links |
| `AGENTS.md` | Symlink to `INDEX.md`; entry point for AI agents that look for `AGENTS.md` by convention (e.g. GitHub Copilot Workspace). |
| `CLAUDE.md` | Symlink to `INDEX.md`; entry point for AI agents that look for `CLAUDE.md` by convention. |
| `GLOSSARY.md` | Cross-tool terminology |
| `llms.txt` | Flat file index for LLM/AI consumption |
| `b/` | `b` build system driver -- summary and full option reference |
| `bx/` | `bx` task runner -- full reference |
| `bpkg/` | `bpkg` package manager -- all commands plus manifest and repository references |
| `bdep/` | `bdep` project manager -- all commands |
| `brep/` | `brep` repository web interface -- all commands and request handling protocols |
| `guides/` | Condensed, topic-scoped guides derived from the large upstream manuals |
| `HOWTO/` | Practical recipes indexed by topic |
| `scripts/` | Utility shell scripts for AI-assisted and manual workflows |
| `skills/` | Nested workflow skills (`build2-package`, `build2-review`). See [skills/README.md](skills/README.md) |
| `.submodules/build2/` | Git submodule: upstream `b`/`bx` `.cli` source files |
| `.submodules/bpkg/` | Git submodule: upstream `bpkg` `.cli` source files |
| `.submodules/bdep/` | Git submodule: upstream `bdep` `.cli` source files |
| `.submodules/libbutl/` | Git submodule: upstream testscript builtin `.cli` source |
| `.submodules/build2-toolchain/` | Git submodule: toolchain amalgamation's own top-level `.cli` and `.md` files |
| `.submodules/build2-howto/` | Git submodule: upstream HOWTO entries |
| `.submodules/libbuild2-autoconf/` | Git submodule: upstream autoconf module source and checks |
| `.submodules/libbuild2-kconfig/` | Git submodule: upstream kconfig module source and manual |
| `.submodules/build2-brep/` | Git submodule: upstream brep source (`.cli`, `.md`, and `.in` files) |
| `.submodules/libbuild2-hello/` | Git submodule: reference custom module source (libbuild2-hello) |
| `.docs/` | Generated output of `init-docs.sh` (git-ignored) |

## Structural guidelines

The rules below follow the [Agent Skills specification](https://github.com/anthropics/skills)
and the [NVIDIA/skills](https://github.com/NVIDIA/skills) reference
implementation.

### Entry point and progressive disclosure

`SKILL.md` is the mandatory skill entry point. Its YAML frontmatter (`name`,
`description`, `license`, `compatibility`) is loaded by compliant runners at
startup (~100 tokens). The body (when-to-use table, quick orientation,
common invocations) is loaded only when the skill is activated (<5000
tokens). Keep both sections within these budgets.

### File focus

Each file should cover one topic. An agent loads only what it needs; a file
mixing several independent topics forces unnecessary token spend. Target
under ~500 lines per file. When a file grows beyond that and the topics are
independently addressable, split it along natural topic boundaries.

### Naming conventions

| Kind | Pattern | Example |
|------|---------|---------|
| Per-tool summary | `<tool>/README.md` | `bpkg/README.md` |
| Per-command reference | `<tool>/<tool>-<command>.md` | `bpkg/bpkg-pkg-build.md` |
| Condensed guide | `guides/build2-<topic>.md` | `guides/build2-modules-cxx.md` |
| HOWTO recipe | `HOWTO/<topic>.md` | `HOWTO/sanitize-tests.md` |
| Utility script | `scripts/<verb>-<noun>.sh` | `scripts/run-tests.sh` |
| Workflow skill | `skills/<name>/SKILL.md` | `skills/build2-package/SKILL.md` |

### Workflow skills

`skills/<name>/SKILL.md` is a procedure that uses the guides and HOWTOs
in this repository. The root `SKILL.md` remains the `build2` reference
skill. Nested skills are discovered by clients that walk `SKILL.md` files
under an installed skill. Clients that only scan one level of a skills
directory need a sibling copy:

```
cp -r skills/<name> <skills-root>/
```

That assumes this repository is already installed as `<skills-root>/build2/`.
Each workflow skill resolves `ROOT` (the `build2` tree) to `HERE/../build2`
first, then `HERE/../..`. Point `read_file` paths at `${ROOT}/...`. Do not
use `../build2/guides/...` links. See [skills/README.md](skills/README.md)
and [CONTRIBUTING.md](CONTRIBUTING.md).

### Indexes

`SKILL.md` (when-to-use table) and `llms.txt` (the relevant section for the
file type added) must be updated whenever a file is added, removed, or renamed. These are the two
indexes agents use to navigate. `INDEX.md`, `HOWTO/README.md`, and
`skills/README.md` have their own navigation tables and must be kept in
sync as well.

### Cross-references

Every command file that has related HOWTO recipes should have a "See also"
section linking to them. The NVIDIA/skills "Common Issues" pattern is
followed in `HOWTO/troubleshooting.md`: exact error text, cause, and fix.

### Scripts

Scripts in `scripts/` are POSIX sh (`#!/bin/sh`, `set -e`). Each must have a
header block (purpose, usage, what it creates or checks), print tabular
output with `printf '%-Ns %s\n'`, send error messages to stderr (`>&2`), and
exit 1 on any error condition.

## Initialising after clone

```sh
./init-docs.sh false   # extract current submodule state into .docs/
./init-docs.sh true    # pull submodules to latest HEAD first, then extract
```

To revert a `true` run back to pinned commits:

```sh
git submodule deinit --all -f && git submodule update --init
```
