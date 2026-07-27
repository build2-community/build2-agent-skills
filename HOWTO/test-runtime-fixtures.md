# Runtime Test Fixtures

Tests often need extra built artifacts that are not themselves smoke tests:
child-process helpers, data generators, or other files the test discovers by
path at runtime. Those fixtures must sit on the **test update path** so
`update-for-test`, `b test`, and out-of-source **test-installed** builds still
produce them.

## Mark fixtures as non-tests

If every `exe{}` in the tests subproject defaults to `test = true`, turn that
off for fixtures:

```
# tests/resources/buildfile (or equivalent)
exe{*}: test = false

for t: c{*}
  ./: exe{$name($t)}: $t
```

Listing a fixture only as a member of `./:` with `test = false` is **not**
enough for `update-for-test`. The test rule updates testable targets and what
they need for testing. A non-test directory member is skipped.

## Attach fixtures to the testscript (preferred)

For Testscript-driven tests, put runtime fixtures as prerequisites of the
**testscript** target, not of the unit executable (the link rule must not see
them as link inputs):

```
import libs = libreproc%lib{reproc}

include ../resources/

resource_dir = $posix_string([dir_path] $out_root/resources)

for t: c{* -fork}
{
  n = $name($t)

  ./: exe{unit-$n}: $t $libs testscript{common}
  {
    c.poptions += "-DRESOURCE_DIRECTORY=\"$resource_dir\""
  }

  # Runtime fixture: updated when the testscript is prepared for testing.
  #
  testscript{common}@./: ../resources/exe{$n}
}
```

### Why `@./`

Targets named on the **left-hand side** of a dependency default to **out**.
A pure source file such as `common.testscript` lives in **src**. Without
`@./`, build2 looks for an out-side `testscript{common}` and fails with
"no rule to update .../testscript{common}".

`@./` pins the target to this directory's src tree (same idea as
`doc{INSTALL}@./: install = false`).

Prerequisites on the right-hand side do not need `@./`. `file{}`-based
prereqs are resolved by searching out first, then existing files in src.

See [build2 advanced projects](../guides/build2-projects-advanced.md) for the
installability example, and the build system manual section on src/out
targets.

### Shared testscript

If many unit exes share one `testscript{common}`, each

```
testscript{common}@./: ../resources/exe{$n}
```

in a loop adds another fixture prerequisite to that shared script. Any unit
test that uses `common` therefore pulls in every listed fixture. That is
usually fine for small helpers. For per-test-only fixtures, use a dedicated
testscript per executable.

## Paths for spawn-by-name tests

When the unit binary opens a helper under a fixed directory (upstream often
uses `-DRESOURCE_DIRECTORY=...`), point that define at the **tests project**
out tree, not the library out tree:

```
resource_dir = $posix_string([dir_path] $out_root/resources)
```

`$out_root` here is the tests subproject root out directory. That stays
correct for in-tree, out-of-source, and test-installed layouts.

## Do not use `test.input` for this

Prerequisite-specific `test.input = true` is a **simple-test** mechanism
(no testscript). It means: make the prerequisite up to date and **append its
path as an extra command-line argument** after `test.options` /
`test.arguments`. It is not currently applied to Testscript-driven tests, and
it changes argv (wrong if the test finds helpers via `RESOURCE_DIRECTORY` or
similar).

| Variable | Role |
|---|---|
| `test.stdin` | Prerequisite file is the test's stdin (simple tests) |
| `test.stdout` | Prerequisite file is compared to stdout (simple tests) |
| `test.roundtrip` | Both stdin and stdout (simple tests) |
| `test.input` | Update + path appended as argv (simple tests only) |

For simple tests that intentionally want "run me with this child path as an
argument":

```
exe{parent}: exe{child}: test.input = true
```

For Testscript + spawn-by-path fixtures, use the testscript prerequisite
pattern above instead.

## Anti-patterns

```
# Wrong: link line may try to use the helper as a link input.
./: exe{unit-foo}: c{foo} $libs testscript{common} ../resources/exe{foo}

# Wrong: looks like "update for test" but changes argv and is simple-test only.
exe{unit-foo}: ../resources/exe{foo}: test.input = true

# Wrong: LHS testscript defaults to out.
testscript{common}: ../resources/exe{foo}

# Wrong: fixture is not on any testable target's update path.
./: ../resources/exe{foo}   # with exe{*}: test = false in resources/
```

## See Also

- [update-for-test-install.md](./update-for-test-install.md) -- for-test closure
- [testscript-summary.md](../guides/testscript-summary.md) -- Testscript integration and `test.*` variables
- [packaging-guide-testing.md](../guides/packaging-guide-testing.md) -- packaging workflow, test-installed
- [config-independent-build-graph.md](./config-independent-build-graph.md) -- platform-specific tests with `include =`
- [build2-projects-advanced.md](../guides/build2-projects-advanced.md) -- `@./` for src-side targets
