# Sanitizing Misbehaving Tests

The easiest way to sanitize test execution is via
[Testscript](../guides/testscript-summary.md#overview). Each test gets its own
temporary working directory, and Testscript provides output redirection,
cleanup, timeouts, and environment control.

## Running multiple executables through one testscript

List the same `testscript` as a prerequisite for multiple targets:

```
for t: cxx{test-*}
{
  ./: exe{$name($t)}: $t $libs testscript
}
```

## Redirecting output and cleaning up files

The [redirections](../guides/testscript-summary.md#redirections) and
[cleanup](../guides/testscript-summary.md#cleanup) directives cover the common
cases:

```
# Redirect stdout to stderr (1>&2), let stderr through (2>|),
# and clean up anything the test creates recursively (&***).
$* 1>&2 2>| &***
```

## Environment variables and timeouts

The [`env` builtin](../guides/testscript-summary.md#builtins) handles
environment variables and timeouts:

```
# Set or unset environment variables.
env VAR=value -- $*

# Impose a timeout; treat expiry as success (useful for servers/daemons).
env --timeout 60 --timeout-success -- $*
```

## Arranging files in the test working directory

Use the `ln` builtin to symlink files from the source tree:

```
ln -s $src_base/test.config ./ ;
$*
```

Combined with wildcard cleanup (disabling auto-cleanup on the symlink since
`&***` handles it):

```
ln --no-cleanup -s $src_base/test.config ./ ;
$* 1>&2 2>| &***
```

The same idea works for a directory. Trailing slash on the source is
directory syntax (always `/`, including on Windows). Use a test scope so
the links and the executable share `$~`:

```
{
  ln -s $src_base/inputs/ inputs
  $*
}
```

Do not `env -c $out_base` (or `env -c $src_base`) to make those relative
names resolve. Cleanup cannot register paths outside `$~`. List the files
on the test executable as `include = adhoc` so `dist` and
`update-for-test` see them:

```
exe{test-parse_examples}: file{inputs/**}: include = adhoc
```

See [test-runtime-fixtures.md](./test-runtime-fixtures.md#source-tree-test-data)
for why that buildfile side is required, and why the NEWS `fsdir{}` asset
recipe is the wrong tool for test data.

## See Also

- [assert-in-tests.md](./assert-in-tests.md): correctly using assert() in tests
- [test-runtime-fixtures.md](./test-runtime-fixtures.md): source-tree data vs built fixtures vs NEWS `fsdir{}`
- [testscript-summary.md](../guides/testscript-summary.md): Testscript language reference
- [testscript-commands.md](../guides/testscript-commands.md): Testscript commands and redirections
