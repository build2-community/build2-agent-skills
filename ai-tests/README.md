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


## Running a test

1. **Provide context.** Load this repository as the AI's knowledge source (for
   example, by opening it as a Claude Code project, or by passing the relevant
   source file listed under **Source** directly to the model).

2. **Pose the query.** Copy the **Query** field verbatim and send it to the AI.
   Do not include the key facts or the source path -- the AI must answer from
   its context alone.

3. **Evaluate the response.** Read the **Key facts** list. The test passes if
   every fact is present in the answer, either as a direct substring match or
   an unambiguous semantic equivalent. The test fails if any fact is missing or
   contradicted.

4. **Record the outcome.** A minimal pass/fail note is enough:

   ```
   T003 PASS
   T005 FAIL -- missing: "build/config.build"
   ```

A single wrong or missing fact is a failure. Partial credit is not meaningful
for sanity tests: either the documentation was sufficient for the AI to answer
correctly, or it was not.


## Files

| File | Section |
|------|---------|
| [b.md](b.md) | `b` -- build system driver |
| [bx.md](bx.md) | `bx` -- shell script and task runner |
| [bpkg.md](bpkg.md) | `bpkg` -- package dependency manager |
| [bpkg-advanced.md](bpkg-advanced.md) | `bpkg` -- pkg-build, pkg-status, pkg-bindist, brep-load |
| [bdep.md](bdep.md) | `bdep` -- project dependency manager |
| [bdep-advanced.md](bdep-advanced.md) | `bdep` -- config, release, publish |
| [brep.md](brep.md) | `brep` -- package repository web interface |
| [manifest.md](manifest.md) | Package manifest format |
| [testscript.md](testscript.md) | Testscript language |
| [version.md](version.md) | Package version format |
| [buildfile.md](buildfile.md) | Buildfile language and directives |
| [modules-bin.md](modules-bin.md) | Binary target types (bin module) |
| [modules-cc-cxx.md](modules-cc-cxx.md) | C/C++ compilation modules (cc, cxx, c, in) |
| [packaging.md](packaging.md) | Third-party packaging workflow |
| [howto.md](howto.md) | Practical HOWTO recipes |
| [howto-libraries.md](howto-libraries.md) | HOWTO -- library design and linking |
| [howto-build.md](howto-build.md) | HOWTO -- build and configuration |
| [howto-workflow.md](howto-workflow.md) | HOWTO -- workflow and versioning |
| [testscript-commands.md](testscript-commands.md) | Testscript command mechanics |
