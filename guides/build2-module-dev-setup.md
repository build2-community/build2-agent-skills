# Build2 Module Development Setup

This guide covers the two ways to set up a development environment for a
custom build2 module: build-system-only (for quick testing) and project
manager (for real development with CI, releases, and publishing). The
examples use `libbuild2-hello` as the concrete module name.

For the module API itself, see
[build2-module-hello.md](build2-module-hello.md).

---

## Why Modules Need Split Configurations

A build system module is a library that the build system itself loads. The
module must be compiled by the _host_ build system (running on the host
machine), not the target build system (which might be cross-compiling). This
means:

- The module package (`libbuild2-hello`) must be built in a `--type build2`
  configuration, which targets the host platform and loads `~build2`
  (the running build system's own configuration variables).
- The test package (`libbuild2-hello-tests`) must be built in a normal C++
  configuration, which uses the module at build time.

These two packages cannot share a single build configuration.

---

## Build-System-Only Quick Start

Best for kicking the tires or a quick test without `bdep`:

```
git clone .../libbuild2-hello.git
cd libbuild2-hello/

b configure: libbuild2-hello/ config.config.load=~build2
b configure: libbuild2-hello-tests/ \
    config.import.libbuild2_hello=libbuild2-hello/
b test
```

`config.config.load=~build2` loads the configuration of the running build
system into the module's configuration, making `build2%lib{build2}` and all
associated headers available without a separate installation step.

`config.import.libbuild2_hello=libbuild2-hello/` tells the test package
where to find the freshly configured module.

For cross-compilation (building the module together with a cross build
system), suppress the host build system import to avoid importing the wrong
build system:

```
b configure: libbuild2-hello/ config.config.load=~build2 \
    "config.build2.options=import.build2=[null]"
```

---

## Project Manager Setup (Two Configurations)

Use this for any module intended to be CI'd, released, or published:

```
git clone .../libbuild2-hello.git
cd libbuild2-hello/

bdep init --empty

bdep config create @module ../libbuild2-hello-build/module/ \
    --type build2 cc config.config.load=~build2
bdep config create @target ../libbuild2-hello-build/target/ \
    cc config.cxx=g++

bdep init @module -d libbuild2-hello/
bdep init @target -d libbuild2-hello-tests/
```

`--type build2` creates a build configuration typed for build system module
development. It adds the standard constraints that keep the module compatible
with the build system it will be loaded into.

`--empty` initialises an empty `bdep` project state without associating any
packages, so you can then associate the two packages to different
configurations.

### Three-Configuration Pattern (Module With a Tool)

If the module also ships a code-generation tool or other host executable,
add a `@host` configuration for it:

```
bdep config create @host   ../libbuild2-hello-build/host/   --type host cc config.cxx=g++
bdep config create @module ../libbuild2-hello-build/module/ --type build2 cc config.config.load=~build2
bdep config create @target ../libbuild2-hello-build/target/ cc config.cxx=g++

bdep init @host   -d hello-tool/
bdep init @module -d libbuild2-hello/
bdep init @target -d libbuild2-hello-tests/
```

`--type host` is like a normal C++ configuration but marks it as targeting
the host, which is needed for tools that will run during a cross build.

---

## No Root Buildfile

There is no `buildfile` at the repository root. Building the module and its
tests in the same build context would be incorrect (they need separate build
configurations). `bdep` knows which packages belong to which configuration
from the `bdep init` calls above.

---

## Day-to-Day Workflow

```
bdep test                        # run tests across configured configurations
bdep update                      # update (build) without running tests
b libbuild2-hello/               # update just the module (build system shorthand)
b test: libbuild2-hello-tests/   # run only the external tests
```

The build system shorthand (`b libbuild2-hello/`) is useful when iterating
on module code without going through `bdep`.

---

## Using the Dev Version in Other Projects

`bdep init` writes a `config.import.libbuild2_hello` variable into the test
configuration's `build/config.build`. That tells the tests where to find the
module. However, if you want to use your development version in a different
project that happens to use the same module, you would need to configure it
explicitly each time.

Instead, add a global override to `~/.build2/b.options`:

```
!config.import.libbuild2_hello=/home/.../libbuild2-hello-build/module/
```

The leading `!` makes it a global override that applies to every project
built by `b`, regardless of any project-local configuration. This is also
the required approach for bootstrap modules (see below), because
`config.import.*` variables written by `bdep` are not available at bootstrap
time.

Remove or comment out this line when you no longer need the dev version.

---

## Bootstrap Module Development

When developing a module that is loaded in `build/bootstrap.build`, the
usual `bdep`-written `config.import.*` entry has no effect during bootstrap
(project configuration is not yet loaded at that point).

Use the global override in `~/.build2/b.options` from the start:

```
!config.import.libbuild2_hello=/home/.../libbuild2-hello-build/module/
```

Add this line before running `bdep init @target -d libbuild2-hello-tests/`.

If you plan to CI a bootstrap module, add to its `manifest`:

```
requires: bootstrap
```

This tells the CI infrastructure that the module must be loaded at bootstrap
so the build of the test package is set up correctly.

---

## CI, Release, and Publish

Once the `@module` configuration is set up with `bdep`:

```
bdep ci @module    # submit only the module (CI pulls in the tests automatically)
bdep release       # bump version in both the module and the tests
bdep publish       # submit both packages to a package repository
```

`bdep ci` submits only the module package. The CI server resolves the
`tests:` dependency from the module's `manifest` and builds the tests
automatically.

`bdep release` and `bdep publish` operate on all packages associated with
the project (both the module and the tests).

---

## See Also

- [build2-module-hello.md](build2-module-hello.md) -- module API, entry points, manifest
- [bdep reference](../bdep/README.md) -- full bdep command reference
- [bdep-init](../bdep/bdep-init.md) -- initialize project in build configurations
- [bdep-config](../bdep/bdep-config.md) -- manage build configurations
- [HOWTO/toolchain-dev-setup.md](../HOWTO/toolchain-dev-setup.md) -- setting up build2 for toolchain development
