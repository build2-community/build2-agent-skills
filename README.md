# ai-skills-build2

Structured, AI-consumable knowledge of the [build2](https://build2.org)
C/C++ toolchain ecosystem. Content is derived from the canonical upstream
sources listed below and organised according to the
[Agent Skills specification](https://github.com/anthropics/skills).

## Authoritative upstream sources

| Source | Role |
|--------|------|
| [`build2/build2-toolchain`](https://github.com/build2/build2-toolchain) submodule | `.cli` and `.md` source files; authoritative for all option descriptions, command synopses, and concept documentation |
| [`build2/build2-howto`](https://github.com/build2/build2-howto) submodule | HOWTO entries; authoritative for all recipe content |
| [`build2/libbuild2-autoconf`](https://github.com/build2/libbuild2-autoconf) submodule | Autoconf emulation module; authoritative for builtin check catalog and module README |
| [`build2/brep`](https://github.com/build2/brep) submodule | Repository web interface; authoritative for brep utility option descriptions and request handling protocols |
| [`build2/libbuild2-hello`](https://github.com/build2/libbuild2-hello) submodule | Reference custom module implementation; authoritative for the module API pattern, development workflow, and bootstrap module guidance |
| [Agent Skills specification](https://github.com/anthropics/skills) | Governs the entry-point contract (`SKILL.md`), YAML frontmatter schema, progressive-disclosure model, and file-focus guidance applied throughout |
| [NVIDIA/skills](https://github.com/NVIDIA/skills) | Reference implementation closest in structure to this repository; used as a concrete model for the troubleshooting catalog, "When to use" hints, and per-command "See also" sections |

Content in `b/`, `bx/`, `bpkg/`, `bdep/`, and `guides/` (except
`build2-modules-autoconf.md`) is derived from `build2-toolchain`. Content in
`HOWTO/` is derived from `build2-howto`. Content in `brep/` is derived from
`build2-brep`. The builtin check catalog in `.docs/libbuild2-autoconf/checks/`
is derived from `libbuild2-autoconf`. Do not edit derived content directly.
Patch the upstream submodule instead, then re-run `./init-docs.sh false` to
regenerate `.docs/`.

## Repository layout

| Path | Contents |
|------|----------|
| `SKILL.md` | Skill entry point: YAML frontmatter and when-to-use table |
| `INDEX.md` | Ecosystem overview, full command lookup tables, all navigation links |
| `AGENTS.md` | Symlink to `INDEX.md`; entry point for AI agents that look for `AGENTS.md` by convention (e.g. GitHub Copilot Workspace). |
| `CLAUDE.md` | Symlink to `INDEX.md`; entry point for Claude Code. |
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
| `.submodules/build2-toolchain/` | Git submodule: upstream `.cli` and `.md` source files |
| `.submodules/build2-howto/` | Git submodule: upstream HOWTO entries |
| `.submodules/libbuild2-autoconf/` | Git submodule: upstream autoconf module source and checks |
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

### Indexes

`SKILL.md` (when-to-use table) and `llms.txt` (the relevant section for the
file type added) must be updated whenever a file is added, removed, or renamed. These are the two
indexes agents use to navigate. `INDEX.md` and `HOWTO/README.md` have their
own navigation tables and must be kept in sync as well.

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
