---
name: build2
description: >
  Use when building, testing, packaging, or managing dependencies for C/C++
  projects with the build2 toolchain. Covers the build system driver (b),
  package manager (bpkg), project dependency manager (bdep), task runner (bx),
  and repository web interface (brep). Activate for: writing or reading
  buildfiles, diagnosing build errors, resolving package dependency conflicts,
  packaging a library for cppget.org, setting up build configurations,
  configuring installations, authoring testscripts, hosting package
  repositories, or running any b/bpkg/bdep/bx/brep-* command.
license: MIT
compatibility: build2 toolchain 0.17+; Linux, macOS, FreeBSD, Windows (MSVC/Clang/GCC)
metadata:
  author: build2-docs contributors
  generated-from: build2-toolchain, build2-howto, build2-brep, libbuild2-autoconf, libbuild2-hello
  tools: b bpkg bdep bx brep
---

# build2 Skill

build2 is an integrated C/C++ build toolchain combining a build system (`b`),
package manager (`bpkg`), project dependency manager (`bdep`), task runner
(`bx`), and repository web interface (`brep`). This skill provides structured
reference documentation for all five tools.

Start with [INDEX.md](INDEX.md) for the full command index and navigation, or
use the table below to jump directly to the relevant file.

## When to use

| Task | Start here |
|---|---|
| Write or read a buildfile | [guides/build2-intro-concepts.md](guides/build2-intro-concepts.md) |
| Buildfile language syntax (if/loop/switch/patterns) | [guides/build2-buildfile-language.md](guides/build2-buildfile-language.md) |
| Buildfile directives, name patterns, and attributes | [guides/build2-directives-patterns.md](guides/build2-directives-patterns.md) |
| Pin a target to src instead of out (`@./` qualification) | [guides/build2-targets-variables.md](guides/build2-targets-variables.md) |
| Create nested directories with fsdir{} | [HOWTO/fsdir-parent-chain.md](HOWTO/fsdir-parent-chain.md) |
| Look up a buildfile function signature, flags, or purity | [guides/build2-functions.md](guides/build2-functions.md) |
| Library projects, target importation, subprojects | [guides/build2-projects-advanced.md](guides/build2-projects-advanced.md) |
| Import a library for metadata and still link it (including installed) | [HOWTO/import-immediate-vs-ordinary.md](HOWTO/import-immediate-vs-ordinary.md) |
| Add rpath for a dlopen-only (never linked) dependency | [HOWTO/rpath-unlinked-dependency.md](HOWTO/rpath-unlinked-dependency.md) |
| Write an ad hoc recipe (`{{ }}`) | [HOWTO/ad-hoc-recipe.md](HOWTO/ad-hoc-recipe.md) |
| Share one recipe body across several targets via `~`/`^` name patterns | [HOWTO/ad-hoc-pattern-rule.md](HOWTO/ad-hoc-pattern-rule.md) |
| Create a PHONY-equivalent (alias{}) target | [HOWTO/alias-targets.md](HOWTO/alias-targets.md) |
| Which compile/link options belong in a buildfile | [HOWTO/buildfile-compile-options.md](HOWTO/buildfile-compile-options.md) |
| Place a compile flag after compiler mode or -std | [HOWTO/buildfile-compile-options.md](HOWTO/buildfile-compile-options.md) |
| Choose += vs = for a target-specific list | [HOWTO/buildfile-compile-options.md](HOWTO/buildfile-compile-options.md) |
| Port a CMake project to build2 buildfiles | [HOWTO/migrate-from-cmake.md](HOWTO/migrate-from-cmake.md) |
| Keep the build graph configuration-independent | [HOWTO/config-independent-build-graph.md](HOWTO/config-independent-build-graph.md) |
| C/C++ compile and link options, module support | [guides/build2-modules-cxx.md](guides/build2-modules-cxx.md) |
| C-common variables, DLL export, compilation database, compiler class vs. ID | [guides/build2-modules-cc.md](guides/build2-modules-cc.md) |
| bin/liba/libs/exe target types | [guides/build2-modules-bin.md](guides/build2-modules-bin.md) |
| Match an upstream shared library name or SONAME | [HOWTO/match-upstream-library-name.md](HOWTO/match-upstream-library-name.md) |
| Create a header-only (binless) library | [HOWTO/header-only-library.md](HOWTO/header-only-library.md) |
| Link pthread | [HOWTO/link-pthread.md](HOWTO/link-pthread.md) |
| Link a system library (-lm, -ldl, advapi32.lib) | [HOWTO/link-system-library.md](HOWTO/link-system-library.md) |
| Order sources before libraries on a link target | [HOWTO/link-prerequisite-order.md](HOWTO/link-prerequisite-order.md) |
| Make library components optional | [HOWTO/optional-library-components.md](HOWTO/optional-library-components.md) |
| Use auto-generated C/C++ headers | [HOWTO/generated-headers.md](HOWTO/generated-headers.md) |
| Create a library that provides main() | [HOWTO/library-provides-main.md](HOWTO/library-provides-main.md) |
| Disable shared library variant per platform | [HOWTO/disable-shared-lib-per-platform.md](HOWTO/disable-shared-lib-per-platform.md) |
| Export metadata from executables or libraries | [HOWTO/target-metadata.md](HOWTO/target-metadata.md) |
| Test an installed import! locally against a real prefix | [HOWTO/local-installed-import.md](HOWTO/local-installed-import.md) |
| Add/remove packages, resolve version conflicts | [bpkg/README.md](bpkg/README.md) |
| Build a package, upgrade, or patch | [bpkg/bpkg-pkg-build.md](bpkg/bpkg-pkg-build.md) |
| Create a bpkg configuration (standalone, no bdep project) | [bpkg/bpkg-cfg-create.md](bpkg/bpkg-cfg-create.md) |
| Create a configuration and initialize a bdep project in it | [bdep/bdep-init.md](bdep/bdep-init.md) |
| Initialize a project in an existing configuration | [bdep/bdep-init.md](bdep/bdep-init.md) |
| Sync manifest/lockfile with configuration | [bdep/bdep-sync.md](bdep/bdep-sync.md) |
| Create a new project | [bdep/bdep-new.md](bdep/bdep-new.md) |
| See what a `bdep new` option combination creates | [bdep/bdep-new-layouts.md](bdep/bdep-new-layouts.md) |
| Publish a package | [bdep/bdep-publish.md](bdep/bdep-publish.md) |
| Release a new version | [bdep/bdep-release.md](bdep/bdep-release.md) |
| Write testscripts | [guides/testscript-summary.md](guides/testscript-summary.md) |
| Testscript commands, redirections, regex, cleanup, builtins | [guides/testscript-commands.md](guides/testscript-commands.md) |
| Sanitize misbehaving tests with Testscript | [HOWTO/sanitize-tests.md](HOWTO/sanitize-tests.md) |
| Use assert() correctly in tests | [HOWTO/assert-in-tests.md](HOWTO/assert-in-tests.md) |
| Tests with extra dependencies (separate test package) | [HOWTO/tests-extra-dependencies.md](HOWTO/tests-extra-dependencies.md) |
| Write a lib<pkg>-tests/examples/benchmarks summary or PACKAGE-README | [HOWTO/tests-extra-dependencies.md](HOWTO/tests-extra-dependencies.md) |
| Build only what is needed for test or install | [HOWTO/update-for-test-install.md](HOWTO/update-for-test-install.md) |
| Wire runtime test fixtures (child helpers, source-tree data) | [HOWTO/test-runtime-fixtures.md](HOWTO/test-runtime-fixtures.md) |
| Give tests access to source-tree data directories | [HOWTO/test-runtime-fixtures.md](HOWTO/test-runtime-fixtures.md) |
| Exclude test fixtures/resources from a b dist archive | [HOWTO/exclude-test-data-from-dist.md](HOWTO/exclude-test-data-from-dist.md) |
| Testscript-test an imported executable (e.g. a package's own `exe{}` from `tests/`) | [HOWTO/test-imported-executable.md](HOWTO/test-imported-executable.md) |
| Resolve "already updated but [not] for install" conflicts | [HOWTO/for-install-conflicts.md](HOWTO/for-install-conflicts.md) |
| Package a third-party library | [guides/packaging-guide-summary.md](guides/packaging-guide-summary.md) |
| Run the end-to-end cppget.org packaging workflow | [skills/build2-package/SKILL.md](skills/build2-package/SKILL.md) |
| Run the local pre-publish packaging sanity check | [skills/build2-review/SKILL.md](skills/build2-review/SKILL.md) |
| Name a third-party package, project, and repository | [HOWTO/package-naming.md](HOWTO/package-naming.md) |
| Start a third-party package on the review branch | [guides/packaging-guide-summary.md](guides/packaging-guide-summary.md) |
| Require a dependency feature from a `depends` clause | [HOWTO/require-dependency-feature.md](HOWTO/require-dependency-feature.md) |
| How a pkg vs git repository finds dependencies | [guides/packaging-guide-summary.md](guides/packaging-guide-summary.md#which-repositoriesmanifest-is-consulted) |
| Test and publish a third-party package | [guides/packaging-guide-testing.md](guides/packaging-guide-testing.md) |
| Review a third-party package submission | [guides/packaging-guide-review.md](guides/packaging-guide-review.md) |
| Packaging version management (new revision, new version) | [guides/packaging-guide-version-management.md](guides/packaging-guide-version-management.md) |
| Packaging antipatterns, what not to do | [guides/packaging-guide-antipatterns.md](guides/packaging-guide-antipatterns.md) |
| Handle private headers when packaging a third-party project | [HOWTO/third-party-private-headers.md](HOWTO/third-party-private-headers.md) |
| Install man pages (any section other than 1) | [HOWTO/man-pages-install.md](HOWTO/man-pages-install.md) |
| Package an upstream changelog with a non-canonical name | [HOWTO/package-changes-file.md](HOWTO/package-changes-file.md) |
| bpkg package name rules, version format, constraint syntax | [guides/bpkg-package-name-version.md](guides/bpkg-package-name-version.md) |
| Express a package license in the manifest (SPDX, other:, multiple licenses) | [guides/packaging-license.md](guides/packaging-license.md) |
| Install or bootstrap the toolchain | [guides/install-bootstrap.md](guides/install-bootstrap.md) |
| Install toolchain from repository (step 3) | [guides/install-toolchain.md](guides/install-toolchain.md) |
| Upgrade an installed toolchain (dirty or staged) | [guides/install-upgrade.md](guides/install-upgrade.md) |
| Use .in template preprocessing or bash module | [guides/build2-modules-misc.md](guides/build2-modules-misc.md) |
| version module: variables, snapshot versions, version headers | [guides/build2-module-version.md](guides/build2-module-version.md) |
| Process config.h.in / config.h.cmake / config.h.meson | [guides/build2-modules-autoconf.md](guides/build2-modules-autoconf.md) |
| Add project-specific autoconf checks | [guides/build2-autoconf-project-checks.md](guides/build2-autoconf-project-checks.md) |
| Contribute a check to the autoconf builtin catalog | [guides/build2-autoconf-contributing-checks.md](guides/build2-autoconf-contributing-checks.md) |
| Use autoconf check results in buildfiles | [guides/build2-autoconf-buildfile.md](guides/build2-autoconf-buildfile.md) |
| kconfig: Kconfig language reference (config entries, dependencies, menus, choices) | [guides/kconfig-summary.md](guides/kconfig-summary.md) |
| kconfig: build system integration and examples | [guides/kconfig-integration.md](guides/kconfig-integration.md) |
| kconfig: helper options, non-interactive/random configuration recipes | [guides/kconfig-patterns.md](guides/kconfig-patterns.md) |
| Create a custom build2 module (rules, init, boot) | [guides/build2-module-hello.md](guides/build2-module-hello.md) |
| Understand the build2 module API (entry points, module_functions) | [guides/build2-module-hello.md](guides/build2-module-hello.md) |
| Develop a bootstrap-phase build2 module | [guides/build2-module-hello.md](guides/build2-module-hello.md) |
| Write a custom build2 rule (match, apply, recipe, register) | [HOWTO/write-build2-rule.md](HOWTO/write-build2-rule.md) |
| Set up a build2 module development environment | [guides/build2-module-dev-setup.md](guides/build2-module-dev-setup.md) |
| Split host/target build configurations for module development | [guides/build2-module-dev-setup.md](guides/build2-module-dev-setup.md) |
| Use a dev-version module in other projects | [guides/build2-module-dev-setup.md](guides/build2-module-dev-setup.md) |
| Set up cross-compilation with target triplets | [HOWTO/cross-compilation.md](HOWTO/cross-compilation.md) |
| Manage debug/release/sanitize configurations | [HOWTO/multiple-configurations.md](HOWTO/multiple-configurations.md) |
| Set up a CI/CD pipeline for a build2 project | [HOWTO/ci-cd-setup.md](HOWTO/ci-cd-setup.md) |
| Filter automated CI builds for specific platforms | [HOWTO/builds-ci-filtering.md](HOWTO/builds-ci-filtering.md) |
| Trace whether a build-include/build-exclude pattern matches a bot name | [HOWTO/builds-ci-filtering.md](HOWTO/builds-ci-filtering.md) |
| Read cppget.org CI results (test-installed badges) | [HOWTO/ci-results.md](HOWTO/ci-results.md) |
| Request a system-provided library on a specific CI bot | [HOWTO/sys-build-config.md](HOWTO/sys-build-config.md) |
| Set up build2 for toolchain development | [HOWTO/toolchain-dev-setup.md](HOWTO/toolchain-dev-setup.md) |
| Scaffold a new bpkg package directory | [scripts/new-package.sh](scripts/new-package.sh) |
| Run .bx scripts or named tasks | [bx/bx.md](bx/bx.md) |
| Get started with .bx scripts (practical walkthrough) | [HOWTO/bx-script.md](HOWTO/bx-script.md) |
| Verify toolchain is installed | [scripts/verify-install.sh](scripts/verify-install.sh) |
| Find a C++ compiler for config.cxx= | [scripts/probe-compiler.sh](scripts/probe-compiler.sh) |
| Validate a package manifest file | [scripts/check-manifest.sh](scripts/check-manifest.sh) |
| Run tests in a bpkg configuration | [scripts/run-tests.sh](scripts/run-tests.sh) |
| Inspect project name/version/roots | [scripts/show-project-info.sh](scripts/show-project-info.sh) |
| Check for broken links in documentation | [scripts/check-links.sh](scripts/check-links.sh) |
| Deploy a brep package repository web interface | [brep/README.md](brep/README.md) |
| Load repository data into brep | [brep/brep-load.md](brep/brep-load.md) |
| Expire old builds or archive tenants in brep | [brep/brep-clean.md](brep/brep-clean.md) |
| Set up or migrate brep databases | [brep/brep-migrate.md](brep/brep-migrate.md) |
| Monitor brep build infrastructure for delays | [brep/brep-monitor.md](brep/brep-monitor.md) |
| Clean up binary distribution upload directories | [brep/brep-upload-bindist-clean.md](brep/brep-upload-bindist-clean.md) |
| Implement a package submission or CI handler | [brep/brep-request-handling.md](brep/brep-request-handling.md) |
| Understand the brep package submission protocol | [brep/brep-request-handling.md](brep/brep-request-handling.md) |
| Understand the brep CI request protocol | [brep/brep-request-handling.md](brep/brep-request-handling.md) |
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
| `brep-load` et al. | Repository web interface: hosts packages, handles CI and submission | deploying or operating a package repository |

## Most common invocations

```
b                              # Build default target in current directory
b test                         # Build and run tests
b clean update                 # Rebuild from scratch
b install config.install.root=/usr/local

bpkg create -d build-gcc cc config.cxx=g++
bpkg build hello               # Build a package into the configuration

bdep new -l c++ -t exe hello   # Create a new executable project
bdep init -C ../build-gcc @gcc cc config.cxx=g++  # Create config and initialize project in it
bdep sync                      # Sync manifest/lockfile with configurations
bdep test                      # Run tests across all configurations
bdep update                    # Update project in all configurations
```

See also [GLOSSARY.md](GLOSSARY.md) for terminology definitions.
