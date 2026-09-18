# Workflow skills

Procedures that use the guides and HOWTOs in this repository. Each
subdirectory is a standalone skill (`SKILL.md`). The root `SKILL.md` of
this repository remains the `build2` reference skill.

| Skill | Slash command | Purpose |
|-------|---------------|---------|
| [build2-package/SKILL.md](build2-package/SKILL.md) | `/build2-package` | End-to-end third-party cppget.org packaging (new package, new upstream version, packaging revision) |
| [build2-review/SKILL.md](build2-review/SKILL.md) | `/build2-review` | Local pre-publish packaging sanity check (initial, version, and revision). Read-only |

## Discovery

Clients that walk nested `SKILL.md` files pick these up as
`/build2-package` and `/build2-review` when this repository is installed
as the `build2` skill.

Clients that only scan one level of a skills directory need a sibling
copy next to the `build2` skill:

```
cp -r skills/build2-package skills/build2-review <skills-root>/
```

That assumes this repository is already at `<skills-root>/build2/`.

## ROOT

Each skill resolves `ROOT` (the `build2` tree: `guides/`, `HOWTO/`, and
so on) to the first candidate that contains its probe guide:

1. `HERE/../build2` (sibling layout, including the copy above)
2. `HERE/../..` (nested layout in this repository)

`read_file` paths are `${ROOT}/...`. Do not add `../build2/guides/...`
links. Sibling links between these two skills (`../build2-review/SKILL.md`
and `../build2-package/SKILL.md`) are valid in both layouts.
