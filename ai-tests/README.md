# AI Test Queries

Sanity tests for evaluating whether an AI assistant can correctly answer
questions about the build2 ecosystem using this repository as its knowledge
source.

## Format

Each test file covers one section of the documentation (b, bpkg, bdep, brep,
manifest, testscript). Tests follow this layout:

```
## T<N> -- <title>

**Query:** <the question to ask>

**Key facts** (all must appear in a correct answer):
- <fact>

**Source:** `<path to source file>`
```

"Key facts" are short, unambiguous statements that must all be present in a
correct answer. They are intentionally phrased to avoid synonyms so they can
be checked mechanically (substring or semantic match).

## Files

| File | Section |
|------|---------|
| [b.md](b.md) | `b` -- build system driver |
| [bpkg.md](bpkg.md) | `bpkg` -- package dependency manager |
| [bdep.md](bdep.md) | `bdep` -- project dependency manager |
| [brep.md](brep.md) | `brep` -- package repository web interface |
| [manifest.md](manifest.md) | Package manifest format |
| [testscript.md](testscript.md) | Testscript language |
| [version.md](version.md) | Package version format |
