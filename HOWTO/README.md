# build2 HOWTO

Condensed, AI-indexed versions of the
[upstream HOWTO entries](../.submodules/build2-howto/entries/).

## Build system

| File | Topic |
|------|-------|
| [alias-targets.md](./alias-targets.md) | PHONY-equivalent targets using `alias{}` |
| [buildfile-compile-options.md](./buildfile-compile-options.md) | Which compile/link options belong in a buildfile |
| [config-independent-build-graph.md](./config-independent-build-graph.md) | Keeping the build graph configuration-independent |
| [for-install-conflicts.md](./for-install-conflicts.md) | Resolving "already updated but [not] for install" errors |
| [generated-headers.md](./generated-headers.md) | Auto-generated C/C++ headers |
| [disable-shared-lib-per-platform.md](./disable-shared-lib-per-platform.md) | Disabling the shared library variant per platform |
| [update-for-test-install.md](./update-for-test-install.md) | Building only what is needed for test or install |

## Libraries

| File | Topic |
|------|-------|
| [header-only-library.md](./header-only-library.md) | Binless (header-only) libraries |
| [library-provides-main.md](./library-provides-main.md) | Library that provides `main()` |
| [link-pthread.md](./link-pthread.md) | Linking `pthread` |
| [link-system-library.md](./link-system-library.md) | Linking system libraries (`-lm`, `-ldl`, `advapi32.lib`) |
| [link-prerequisite-order.md](./link-prerequisite-order.md) | Prerequisite order on link-rule targets (sources before `$libs`) |
| [optional-library-components.md](./optional-library-components.md) | Making library components optional |
| [target-metadata.md](./target-metadata.md) | Exporting metadata with executables and libraries |

## Testing

| File | Topic |
|------|-------|
| [assert-in-tests.md](./assert-in-tests.md) | Correctly using `assert()` in tests |
| [sanitize-tests.md](./sanitize-tests.md) | Sanitizing misbehaving tests with Testscript |
| [test-runtime-fixtures.md](./test-runtime-fixtures.md) | Runtime fixtures (child helpers) for tests and update-for-test |
| [tests-extra-dependencies.md](./tests-extra-dependencies.md) | Tests with extra dependencies (separate test package) |
| [test-imported-executable.md](./test-imported-executable.md) | Testscript-testing an imported executable (e.g. a package's own `exe{}` from `tests/`) |

## Packaging third-party projects

| File | Topic |
|------|-------|
| [convert-source-to-utf8.md](./convert-source-to-utf8.md) | Converting source file encoding to UTF-8 |
| [package-naming.md](./package-naming.md) | Naming packages for third-party projects |
| [package-changes-file.md](./package-changes-file.md) | Packaging an upstream changelog with a non-canonical name |
| [package-version-non-semver.md](./package-version-non-semver.md) | Projects that don't use semantic versioning |
| [package-version-none.md](./package-version-none.md) | Projects with no version at all |
| [third-party-private-headers.md](./third-party-private-headers.md) | Private implementation headers and generated config headers shared across internal targets |
| [require-dependency-feature.md](./require-dependency-feature.md) | Requiring a dependency boolean feature with `require` (not `reflect`) |

## Build configurations

| File | Topic |
|------|-------|
| [multiple-configurations.md](./multiple-configurations.md) | Managing debug/release/sanitize configurations with bdep |
| [cross-compilation.md](./cross-compilation.md) | Setting up a cross-compilation configuration with target triplets |
| [ci-cd-setup.md](./ci-cd-setup.md) | Typical CI pipeline using bdep update/test |
| [builds-ci-filtering.md](./builds-ci-filtering.md) | Filtering automated CI builds with `builds:`, `build-include:`, and `build-exclude:` |
| [conditional-dependency-config.md](./conditional-dependency-config.md) | Passing package config variables via `bdep init -C` for conditional dependencies |

## Migrating to build2

| File | Topic |
|------|-------|
| [migrate-from-cmake.md](./migrate-from-cmake.md) | Porting a CMake project to build2 buildfiles |

## bx scripts and tasks

| File | Topic |
|------|-------|
| [bx-script.md](./bx-script.md) | Running `.bx` scripts and tasks with bx |

## Toolchain development

| File | Topic |
|------|-------|
| [toolchain-dev-setup.md](./toolchain-dev-setup.md) | Setting up build2 for toolchain development |
| [write-build2-rule.md](./write-build2-rule.md) | Writing a custom build2 rule from match() to execute phase |

## Troubleshooting

| File | Topic |
|------|-------|
| [troubleshooting.md](./troubleshooting.md) | Common error messages and resolutions for b, bpkg, bdep, bx, and brep |

## See Also

- [`INDEX.md`](../INDEX.md) -- full command index and navigation across all tools
- [`SKILL.md`](../SKILL.md) -- when-to-use table for direct lookup by task
- [`GLOSSARY.md`](../GLOSSARY.md) -- cross-tool terminology definitions
