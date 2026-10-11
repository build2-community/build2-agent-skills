# Testing an Imported Executable

The [testscript integration pattern](../guides/testscript-summary.md#integration-with-build-system)
(`exe{hello}: cxx{hello} testscript`) associates a testscript with a target
**built in the same buildfile**. A `tests/` subproject that imports its own
package's `exe{}` -- the common shape for a package smoke test, and the
shape `bpkg`'s and `bdep`'s own test suites use to test themselves -- needs a
different mechanism: the testscript's `test` variable, overridden to name
the imported target.

## The pattern

```
# tests/build/root.build (or wherever the import happens)
import t = repro-tool%exe{repro-tool}
testscript{*}: test = $t
```

```
# tests/buildfile
./: testscript $t
```

This is the real, current pattern used unchanged since 2018 in
`bpkg/tests/` and `bdep/tests/` to test `exe{bpkg}` and `exe{bdep}`
themselves, split across the same two files: `test = $t` (in `root.build`)
tells the test rule what to run; `$t` as a prerequisite of `./:` (in
`buildfile`) keeps it up to date.

**Prerequisite: the imported package needs a `build/export.build`.**
`bdep new -t exe` does not generate one -- only library projects get it by
default -- but importing your own package's `exe{}` from a `tests/`
subproject is still a cross-project import (of the `repro-tool` project,
from the unnamed `tests` subproject), and fails without it:

```
error: unable to read buildfile build/export.build: no such file or directory
  info: while loading export stub for imported target 'exe{repro-tool}'
```

Add one, mirroring `bpkg/build/export.build`:

```
# build/export.build
$out_root/
{
  include repro-tool/
}

export $out_root/repro-tool/exe{repro-tool}
```

## Named testscript files

A testscript does not have to use the reserved default filename (`testscript`). A
file named `trtexec.testscript` becomes `testscript{trtexec}` in buildfile syntax,
and the pattern must be adjusted for out-of-source builds. Add `@./`
src-qualification to both places:

```
# tests/build/root.build
import t = repro-tool%exe{repro-tool}
testscript{trtexec}@./: test = $t
```

```
# tests/buildfile
./: testscript{trtexec}@./ $t
```

Omitting `@./` from either line causes build2 to look in the out tree, where no
such target exists, and fail:

```
error: no rule to update testscript{trtexec} (implicitly declared in a buildfile)
```

**Why the default filename does not need `@./`.** The wildcard form
`testscript{*}: test = $t` sets a variable on any testscript target that is
resolved, without declaring a specific target itself. The prerequisite reference
`testscript` (no type qualifier) in `./: testscript $t` uses the file-based
out-then-src fallback: build2 searches out first, then falls back to an existing
file in src, finding the source file there.

By contrast, `testscript{trtexec}: test = $t` (without `@./`) implicitly declares
a specific target in the out tree -- where the file does not exist and there is no
rule to create it. `@./` on the left-hand side pins the declaration to the src tree
instead. The matching `@./` on the prerequisite line ensures the reference resolves
to that same src-tree target rather than looking for an out-tree one. See
[build2-targets-variables.md#srcout-qualification](../guides/build2-targets-variables.md#srcout-qualification)
for the full src/out target-resolution rules.

## Ordering: why the `./:` prerequisite matters

`test = $t` only tells the test rule *what* to run -- it resolves `$t` with
a lookup (`search_existing()`), never an update. Testing the whole project
(`b test`, `bdep test`) works even without listing `$t` as a prerequisite
anywhere, because the `test` operation's `update` pre-operation updates the
whole project first, including `exe{repro-tool}`, as a side effect.

But testing the `tests/` subproject **in isolation** -- `b test: tests/`, or
any workflow that scopes testing to just that subdirectory -- fails if
`exe{repro-tool}` isn't otherwise guaranteed up to date:

```
$ b test: tests/
error: target repro-tool/exe{repro-tool} specified in the test variable is out of date
  info: consider specifying it as a prerequisite of dir{tests/}
  info: while testing dir{tests/}
```

The fix is exactly what the diagnostic suggests, and what `bpkg/tests/` and
`bdep/tests/` already do: list the imported target as a prerequisite of the
directory alias, alongside the testscript --

```
./: testscript $t
```

-- **not** by giving `testscript{}` its own separate, named dependency
declaration. That's a different, already-documented footgun: see
["Why the executable, not the
testscript"](./test-runtime-fixtures.md#why-the-executable-not-the-testscript)
and [troubleshooting.md's "no rule to
clean"](./troubleshooting.md#error-no-rule-to-clean-target) entry. `./:` is
the pre-existing directory alias target -- adding a prerequisite to it
doesn't declare anything new, so it doesn't reintroduce that bug.

**Always verify with the full recipe, not `bdep ci`.** A plain `bdep ci`
(git-based) does not reliably catch a broken `clean` rule the same way the
archive-based `cppget.org` publish-test step does (build2/build2#533) --
see [packaging-guide-testing.md](../guides/packaging-guide-testing.md) for
why and for the exact recipe.

## Do not use the imported target as the declaration's left-hand side

Mirroring the local-target pattern exactly -- giving the imported target
itself a testscript prerequisite (`$t: testscript{...}`) instead of
overriding `test` -- is not rejected outright by the parser, but is broken
in practice, in one of two ways depending on context:

- If the imported target already has its own local testscript (the common
  case: a package's own `exe{}` is usually already testscripted locally),
  this conflicts with that association:
  ```
  error: both 'testscript' and other names specified for .../exe{repro-tool}
  ```
- If it does not, the declaration parses, but `$*` inside the testscript
  resolves incorrectly at test-execution time:
  ```
  tests/testscript:3:1: error: unable to execute .../tests: no such file or directory
  ```

Use the `test = $var` override instead.

## See Also

- [testscript-summary.md](../guides/testscript-summary.md) -- local-target association and `test.*` variables
- [test-runtime-fixtures.md](./test-runtime-fixtures.md) -- why runtime fixtures attach to the executable, not the testscript
- [troubleshooting.md](./troubleshooting.md) -- the `clean` and test-ordering failures this page's patterns avoid
- [build2-targets-variables.md](../guides/build2-targets-variables.md#srcout-qualification) -- src/out qualification (`@./`), the related but distinct concept
- [target-metadata.md](./target-metadata.md) -- importing an *installed*, no-dev-build executable (a different, heavier case)
- [packaging-guide-testing.md](../guides/packaging-guide-testing.md) -- the full dist-test-clean recipe this pattern must be verified against
- [tests-extra-dependencies.md](./tests-extra-dependencies.md) -- when the imported executable lives in a separate package, not a `tests/` subproject
