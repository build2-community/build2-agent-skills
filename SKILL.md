---
name: build2
description: >
  Use when building, testing, packaging, or managing dependencies for C/C++
  projects with the build2 toolchain. Covers the build system driver (b),
  package manager (bpkg), project dependency manager (bdep), and task runner
  (bx). Activate for: writing or reading buildfiles, diagnosing build errors,
  resolving package dependency conflicts, packaging a library for cppget.org,
  setting up build configurations, configuring installations, authoring
  testscripts, or running any b/bpkg/bdep/bx command.
license: MIT
compatibility: build2 toolchain 0.17+; Linux, macOS, FreeBSD, Windows (MSVC/Clang/GCC)
metadata:
  author: build2-docs contributors
  generated-from: build2-toolchain .cli sources
  tools: b bpkg bdep bx
---

# build2 Skill

build2 is an integrated C/C++ build toolchain combining a build system (`b`),
package manager (`bpkg`), and project dependency manager (`bdep`). This skill
provides structured reference documentation for all four tools.

Start with [INDEX.md](INDEX.md) for the full command index and navigation, or
use the table below to jump directly to the relevant file.

## When to use

| Task | Start here |
|---|---|
| Write or read a buildfile | [guides/build2-intro-concepts.md](guides/build2-intro-concepts.md) |
| Buildfile language syntax (if/loop/switch/patterns) | [guides/build2-buildfile-language.md](guides/build2-buildfile-language.md) |
| Library projects, target importation, subprojects | [guides/build2-projects-advanced.md](guides/build2-projects-advanced.md) |
| C/C++ compile and link options, module support | [guides/build2-modules-cxx.md](guides/build2-modules-cxx.md) |
| C-common variables, DLL export, compilation database | [guides/build2-modules-cc.md](guides/build2-modules-cc.md) |
| bin/liba/libs/exe target types | [guides/build2-modules-bin.md](guides/build2-modules-bin.md) |
| Add/remove packages, resolve version conflicts | [bpkg/README.md](bpkg/README.md) |
| Build a package, upgrade, or patch | [bpkg/bpkg-pkg-build.md](bpkg/bpkg-pkg-build.md) |
| Create a bpkg configuration | [bpkg/bpkg-cfg-create.md](bpkg/bpkg-cfg-create.md) |
| Initialize a project with bdep | [bdep/bdep-init.md](bdep/bdep-init.md) |
| Sync manifest/lockfile with configuration | [bdep/bdep-sync.md](bdep/bdep-sync.md) |
| Create a new project | [bdep/bdep-new.md](bdep/bdep-new.md) |
| Publish a package | [bdep/bdep-publish.md](bdep/bdep-publish.md) |
| Release a new version | [bdep/bdep-release.md](bdep/bdep-release.md) |
| Write testscripts | [guides/testscript-summary.md](guides/testscript-summary.md) |
| Package a third-party library | [guides/packaging-guide-summary.md](guides/packaging-guide-summary.md) |
| Install or bootstrap the toolchain | [guides/install-bootstrap.md](guides/install-bootstrap.md) |
| Verify toolchain is installed | [scripts/verify-install.sh](scripts/verify-install.sh) |
| Troubleshoot errors | [HOWTO/troubleshooting.md](HOWTO/troubleshooting.md) |
| Practical recipes by topic | [HOWTO/README.md](HOWTO/README.md) |
| Terminology reference | [GLOSSARY.md](GLOSSARY.md) |

## Quick tool orientation

| Binary | Role | Load when |
|---|---|---|
| `b` | Build system driver: reads buildfiles, executes operations | writing buildfiles, diagnosing builds |
| `bpkg` | Package manager: manages packages in a build configuration | adding dependencies, publishing |
| `bdep` | Project dependency manager: syncs manifests with configurations | day-to-day project workflow |
| `bx` | Task runner: runs `.bx` scripts or named tasks | automation, scripted tasks |

## Most common invocations

```
b                              # Build default target in current directory
b test                         # Build and run tests
b clean update                 # Rebuild from scratch
b install config.install.root=/usr/local

bpkg create -d build-gcc cc config.cxx=g++
bpkg build hello               # Build a package into the configuration

bdep new -l c++ -t exe hello   # Create a new executable project
bdep init -C ../build-gcc      # Initialize project in a configuration
bdep sync                      # Sync manifest/lockfile with configurations
bdep test                      # Run tests across all configurations
bdep update                    # Update project in all configurations
```

See also [GLOSSARY.md](GLOSSARY.md) for terminology definitions.
