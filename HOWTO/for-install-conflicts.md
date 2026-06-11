# Resolving For-Install Build Conflicts

## What the error means

build2 can build targets slightly differently depending on whether they are
being built for [installation](../guides/build2-projects-advanced.md#installation)
(`install` operation) or for development (`update`). On POSIX, shared
libraries and executables are re-linked without `rpath` for install. Projects
can also customise the for-install build explicitly via the `for_install`
target-specific variable.

Because the for-install and for-development variants of a target are
incompatible, build2 fails if two targets in the same build require the same
dependency in different flavours:

```
error: incompatible exe{hello} build
  info: target is already updated but for install
```

or:

```
error: incompatible lib{hello} build
  info: target is already updated but not for install
```

## Common cause

The most frequent trigger is an executable that is both being installed *and*
run during the build (e.g., a source code generator). build2 needs it
for-install (to produce the installed binary) and for-development (to execute
it), at the same time.

A variant occurs when an internal utility executable is not installed but
depends on a library that is. The executable needs the library
for-development; the install operation needs it for-install.

## Solution

The situation is analogous to cross-compilation: the fix is to use a separate
build configuration for installation where the executable does not need to be
run (for example, by caching its output). See the
[CLI compiler](https://github.com/codesynthesis-com/cli) for a real-world
example of this pattern.

## See Also

- [build2 core modules: install](../guides/build2-modules-core.md) -- install layout and operations
- [troubleshooting.md](./troubleshooting.md) -- common error messages and fixes
