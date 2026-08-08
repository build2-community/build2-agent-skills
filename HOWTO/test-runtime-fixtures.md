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

## Attach built fixtures with `include = adhoc` (preferred)

For Testscript-driven tests, attach runtime fixtures as `include = adhoc`
prerequisites of the **test executable**, not of the testscript:

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

  # Runtime fixture: attached to the executable (not the testscript) so it
  # stays on a target that already has update and clean rules.
  #
  exe{unit-$n}: ../resources/exe{$n}: include = adhoc
}
```

### Why the executable, not the testscript

A testscript is normally only ever consumed as a **prerequisite** of a
testable target (`exe{hello}: cxx{hello} testscript`); that association is
handled specially by the `test` module, not by generic dependency-graph
traversal (see [testscript-summary.md](../guides/testscript-summary.md)).

Giving the testscript a **separate** dependency declaration of its own,
`testscript{name}@./: <target>`, is different: it makes `testscript{name}`
a target this buildfile independently declares, like any other. In an
in-source build `src_base` and `out_base` are the same directory, so that
independently-declared target sits right where a directory-scoped
`b clean` -- what the cppget.org publish queue runs against a plain,
non-forwarded build -- walks looking for things to clean. `testscript{}`
has no `clean` rule (it is only ever *prepared* by the `test` operation,
never independently updated or cleaned outside that), so this fails with
`error: no rule to clean .../testscript{name}`; see
[troubleshooting.md](./troubleshooting.md).

`@./` is not what causes this -- it only pins the target to `src` instead
of the default `out`, and is required here regardless, since the
`.testscript` file genuinely lives in `src`. See ["Src/out
qualification"](../guides/build2-targets-variables.md#srcout-qualification)
for the general rule this is a special case of: `@./` decides which
directory a target resolves against; the *separate declaration* is what
registers it as a target at all.

`include = adhoc` sidesteps the whole issue: the fixture stays an ordinary
prerequisite of the executable -- a target that already has update and
clean rules -- and is never separately declared as a target of its own.
`adhoc` additionally tells build2 to track and update that prerequisite
without treating it as a compile/link input. This is also how
`third-party-private-headers.md` attaches symlinked headers build2 must
track but not compile; see [`include = adhoc`
there](./third-party-private-headers.md#thunk-headers-and-symlinks-cross-package-in-place-workaround).

This pattern (and the `clean` failure it fixes) was confirmed and released
upstream in `build2-reproc`: `libreproc`/`libreprocxx` revision 14.2.7+1
replaced `testscript{common}@./: ../resources/exe{$n}` with
`exe{unit-$n}: ../resources/exe{$n}: include = adhoc` in both
`tests/unit/buildfile` and `tests/examples/buildfile`.

### Shared testscript

Because each fixture is now attached directly to the executable that needs
it, there is no fan-out to worry about: sharing one `testscript{common}`
across many unit exes no longer pulls in every fixture for every test --
each executable only gets the fixtures listed on its own `adhoc`
prerequisites.

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

For Testscript + spawn-by-path fixtures, use the `include = adhoc` pattern
above instead.

## Anti-patterns

```
# Wrong: link line may try to use the helper as a link input.
./: exe{unit-foo}: c{foo} $libs testscript{common} ../resources/exe{foo}

# Wrong: looks like "update for test" but changes argv and is simple-test only.
exe{unit-foo}: ../resources/exe{foo}: test.input = true

# Wrong: registers testscript{} as an out-tree build target with no clean
# rule -- "error: no rule to clean .../testscript{common}" in a plain build.
testscript{common}@./: ../resources/exe{foo}

# Wrong: fixture is not on any testable target's update path.
./: ../resources/exe{foo}   # with exe{*}: test = false in resources/
```

## See Also

- [troubleshooting.md](./troubleshooting.md) -- the `clean` failure this pattern avoids
- [update-for-test-install.md](./update-for-test-install.md) -- for-test closure
- [testscript-summary.md](../guides/testscript-summary.md) -- Testscript integration and `test.*` variables
- [packaging-guide-testing.md](../guides/packaging-guide-testing.md) -- packaging workflow, test-installed
- [config-independent-build-graph.md](./config-independent-build-graph.md) -- platform-specific tests with `include =`
- [third-party-private-headers.md](./third-party-private-headers.md) -- `include = adhoc` for tracked, non-compiled prerequisites
- [build2-projects-advanced.md](../guides/build2-projects-advanced.md) -- `@./` for src-side targets
- [test-imported-executable.md](./test-imported-executable.md) -- testing an imported executable without repeating this file's `clean` footgun in a new context
