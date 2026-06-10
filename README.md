# ai-skills-build2

Structured, AI-consumable knowledge of the [build2](https://build2.org)
C/C++ toolchain ecosystem, generated from the canonical `.cli` source
documentation in `raw-docs/`.

## What is here

| Path | Contents |
|------|----------|
| `INDEX.md` | Start here: ecosystem overview, full command lookup table, navigation links |
| `GLOSSARY.md` | Cross-tool terminology (targets, configurations, manifests, etc.) |
| `b/` | `b` build system driver -- summary and full option reference |
| `bx/` | `bx` shell script and task runner -- full reference |
| `bpkg/` | `bpkg` package manager -- all 28 commands plus manifest and repository references |
| `bdep/` | `bdep` project manager -- all 13 commands |
| `guides/` | Condensed summaries of the large manuals: build system, testscript, packaging, kconfig, install/bootstrap |
| `raw-docs/` | Original `.cli` source files from the build2 toolchain amalgamation |

## How to use

An LLM should read `INDEX.md` first to orient itself, then follow links to the
relevant component summary or command reference. Each command reference file is
self-contained: synopsis, full description, all options in table form, and
cross-references to related commands.

The `raw-docs/` directory is the authoritative source. The markdown files are
derived from it and are the intended consumption format for AI agents.
