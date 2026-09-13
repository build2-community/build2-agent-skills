# Exclude Test Data From Dist

Large or generated test fixtures should stay in the git checkout but not
ship in the `b dist` archive. Three mechanisms look like they should do
this and do not: `install = false` (wrong module), `include = false` (still
collected), and wrapping the declaration in `if` (parser warning, not an
exclusion). This is verified against
`.submodules/build2/libbuild2/dist/` and confirmed with
real `b dist` runs.

## The three knobs

| Knob | What it actually controls | Effect on `b dist` |
|---|---|---|
| `install = false` | install/uninstall; `install`'s rule walks the enclosing `dir{}` chain (`libbuild2/install/rule.cxx`, `lookup_install`, "T is either scope or target") | none -- `dist` has no such lookup |
| `include = false` on a prerequisite | whether `update`/`test` require it | still collected: `dist_include()` rewrites `excluded` to `adhoc` so "every source is included into the distribution" (`libbuild2/dist/operation.cxx`) |
| `dist = false`, **target-specific**, on the file target itself | `dist`'s `collect()` walk | excluded -- the only knob that actually removes a file from the archive |
| `if` around a dependency declaration | whether the target enters the graph at all | a dist-only parser warning ("may result in incomplete distribution"); does not exclude the file under the branch that is taken |

`dist` (like `test`, `install`, `extension`) has `variable_visibility::target`
(`libbuild2/dist/init.cxx`, NEWS 0.4.0: "to prevent accidental 'reuse' for
other purposes"). `collect()` (`libbuild2/dist/operation.cxx`) only ever
walks `file` targets and only ever reads *that target's own* `dist` value
(`ft[dist_var]`) -- never a parent directory's. `install`'s rule was written
with an explicit scope-chain walk for exactly this reason; `dist`'s was not.

## The gotcha: target-specific, not prerequisite-specific

`dist = false` must be a **target-specific** assignment -- its own buildfile
line, naming the target itself on the left of the colon. Chaining it after
a single prerequisite on someone else's declaration line sets a
**prerequisite-specific** value instead (the same mechanism as `include =`
or `test.input =`), which `collect()` never looks at and which silently
does nothing:

```
# Wrong: prerequisite-specific dist on the ./: -> file{} edge. Silently
# ignored by collect(); the file still ships.
./: file{data/fixture.txt}: dist = false

# Correct: target-specific, its own line.
./: file{data/fixture.txt}
file{data/fixture.txt}: dist = false
```

Confirmed with a real `b dist` run: the chained form leaves the file in the
archive with no warning; the standalone form removes it.

## Recipe: selected files

Combine target-specific `dist = false` (out of the archive) with
prerequisite-specific `include = false` (off the default `update`/`test`
path), so an in-source rebuild of the unpacked archive never tries to touch
a file that was never copied there:

```
./: file{data/fixture-excluded.txt}: include = false
file{data/fixture-excluded.txt}: dist = false
```

Without `include = false`, `b dist` still succeeds, but `b update` on the
unpacked, in-source archive (`src_base == out_base`, exactly what
`guides/packaging-guide-testing.md`'s dist-test loop and the cppget.org
build queue run) fails outright, because the buildfile still declares the
prerequisite and the physical file is genuinely absent:

```
error: no rule to update data/file{fixture-excluded.txt}
  info: target data/file{fixture-excluded.txt} is implicitly declared in a buildfile
```

`dist = false` removes the file from the archive; it does not remove the
declaration from the (always-distributed) buildfile. `include = false`
is what keeps that now-dangling declaration off the default build path.

ODB's vendored buildfiles use the same target-specific knob at scale for
generated/pregenerated headers, conditioned on a config variable instead of
hardcoded `false` (`libbutl/upstream/odb/odb/odb/buildfile`):

```
pregenerated/{hxx ixx cxx}{*}: dist = (!$develop)
```

## Recipe: a whole directory

There is no directory-level shortcut (that is precisely the `install`
idiom that does not carry over -- see above). Apply the same two knobs as a
target-type pattern, recursive if the directory nests further:

```
./: file{tests/data/**}: include = false
file{tests/data/**}: dist = false
```

Confirmed end to end: `tests/data/` (including a nested subdirectory) is
completely absent from the `b dist` archive, and `configure`/`update`/
`test`/`clean` all succeed on the unpacked, in-source archive.

The pattern must cover **every target type** actually present in the
directory -- `file{**}` does not match `c{**}`, `testscript{**}`, etc. Add
one pattern line per type. If the directory is itself a build2 scope (has
its own `buildfile`), that scope's own `file{*}: dist = false` also
suppresses the scope's `buildfile` from the archive. Omitting it produces a
duplicate-collection warning instead of a clean exclusion, since `dist`
auto-collects each scope's `buildfile` independently of the prerequisite
graph:

```
warning: multiple files are distributed as .../tests/data/buildfile
  info: second file is .../tests/data/buildfile
```

## Failing lookalikes

- **`dir{resources}/: dist = false`** (target-specific, standalone line, on
  the `dir{}` target rather than a `file{}` target) -- parses fine, has zero
  effect. Confirmed: the file inside still ships. `collect()` skips every
  non-`file` target (`libbuild2/dist/operation.cxx`), so nothing ever reads
  this value.
- **`resources/ { dist = false }`** (brace-block scope assignment) -- a hard
  parse error, confirmed:
  ```
  error: variable dist has target visibility but is assigned on a scope
    info: consider changing it to '*: dist'
  ```
  (`libbuild2/parser.cxx`.)
- **`include = false` alone**, with no `dist = false`. Confirmed still
  collected -- `dist_include()` exists specifically to force excluded
  prerequisites onto the dist graph.
- **`tests/: install = false`** reused for dist. Confirmed no effect: this
  is the `install` module's own scope-chain lookup, which `dist` does not
  have.
- **`if ($build.meta_operation != 'dist') { ./: file{...} }`** (or any
  `if`-guarded dependency declaration loaded during `dist`). Confirmed
  warning:
  ```
  warning: conditional dependency declaration may result in incomplete distribution
    info: instead use 'include' prerequisite-specific variable to conditionally include prerequisites
    info: for example: <target>: <prerequisite>: include = (<condition>)
  ```
  This does not exclude the file under the branch that is actually taken --
  it still ships. The warning exists because a *different* configuration
  taking the other branch would silently produce a different, incomplete
  archive, not because this is a working exclusion mechanism. ODB's own use
  of `if ($build.meta_operation != 'dist')` in `odb-tests/` (69
  occurrences) wraps only `assert` statements, never a dependency
  declaration, which is why it never trips this warning -- do not copy that
  guard onto a target declaration.

## Runtime caveat

`include = false` + `dist = false` keeps the *build* clean on the unpacked
archive, but if a test genuinely reads the excluded data at runtime, that
specific test will fail there, not merely be skipped. There is no
first-party precedent (in the toolchain or howto submodules) for a
perform-side "skip this test if its data is missing" idiom --
`$src_root != $out_root` is used 19 times in this toolchain, always for
`clean =`, never for `test =`. If the data is essential to a test's
correctness, either keep it in the archive or gate that test's own
`test =` on the same condition; do not invent an unverified `test =`
pattern.

## Bootstrap dist mode

None of this applies under `config.dist.bootstrap`: that mode never loads
buildfiles at all, instead walking the filesystem directly and copying
everything except `.git*`, `.bdep`, `.bpkg`, `.build2`
(`libbuild2/dist/operation.cxx`, `add_subdir()`). The `dist` target
variable and `dist_include()` are both unused in this mode.

## See Also

- [test-runtime-fixtures.md](./test-runtime-fixtures.md): getting fixtures
  *into* the test tree with `include = adhoc` -- the complementary problem
- [config-independent-build-graph.md](./config-independent-build-graph.md):
  `include = (condition)`, and why `if` around a dependency declaration is
  unsafe under `dist`
- [for-install-conflicts.md](./for-install-conflicts.md): another
  install-vs-other-operation mismatch
- [packaging-guide-testing.md](../guides/packaging-guide-testing.md): the
  unpacked in-source dist-test loop this HOWTO's recipes are verified
  against
