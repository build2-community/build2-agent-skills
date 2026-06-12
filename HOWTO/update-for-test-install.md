# Building Only What Is Needed for Test or Install

`update-for-test` and `update-for-install` are b operations that build the
minimum set of targets required for a specific purpose without performing that
operation itself. They are equivalent to the `update` pre-operation that `test`
and `install` would run internally.

Use these when you want to verify that targets build correctly for a given
operation without actually executing that operation.

## update-for-test

Builds only what is needed for testing -- test executables and their
dependencies -- while skipping targets that are only relevant for installation.

```
$ b update-for-test
$ b update-for-test: foo/
```

Typical use in CI: verify that the test build succeeds on a fast check step
before committing time to a full test run.

```
$ b update-for-test && b test
```

## update-for-install

Builds only what is needed for installation -- the install-mode variants of
libraries and executables -- while skipping test-only targets.

```
$ b update-for-install
$ b update-for-install: config.install.root=/usr/local/ ./
```

Typical use: verify that an install build succeeds (including correct rpath
stripping on POSIX) before running `b install`.

```
$ b update-for-install && b install: config.install.root=/usr/local/
```

## Why these differ from plain update

`build2` can build the same target in two incompatible flavours depending on
context: for-install (shared libraries and executables are re-linked without
rpath) and for-development. The pre-operations `update-for-test` and
`update-for-install` request the correct flavour without the side effects of
running tests or writing files into the install root.

## See Also

- [b README](../b/README.md) -- operations table and buildspec syntax
- [for-install-conflicts](./for-install-conflicts.md) -- resolving errors when both flavours are required simultaneously
- [build2 core modules: install](../guides/build2-modules-core.md) -- install layout and the for-install build model
