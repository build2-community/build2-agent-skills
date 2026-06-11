# CI/CD Setup with build2

A typical CI pipeline for a build2 project runs `bdep update` and `bdep test`
inside one or more bpkg build configurations.

## Minimal pipeline (no bdep, single package)

For projects not using the full bdep workflow:

```yaml
# GitHub Actions example
steps:
  - uses: actions/checkout@v4
  - name: Install build2
    run: |
      curl -sSfO https://download.build2.org/X.Y.Z/build2-install-X.Y.Z.sh
      sh build2-install-X.Y.Z.sh --yes
  - name: Create configuration
    run: bpkg create -d build cc config.cxx=g++
  - name: Build and test
    run: |
      cd build
      bpkg build hello/
      bpkg test hello/
```

## Full bdep workflow

For projects with a `manifest` and dependencies:

```yaml
steps:
  - uses: actions/checkout@v4
  - name: Install build2
    run: |
      curl -sSfO https://download.build2.org/X.Y.Z/build2-install-X.Y.Z.sh
      sh build2-install-X.Y.Z.sh --yes
  - name: Initialize
    run: |
      bdep init --empty
      bdep config create -d ../build @ci cc config.cxx=g++
      bdep init @ci
  - name: Update and test
    run: |
      bdep update @ci
      bdep test @ci
```

## Using bdep ci for remote CI

build2 has a built-in CI submission command that submits the project to a
remote CI server (e.g., builds.cppget.org):

```
$ bdep ci
```

This submits a CI request for all or selected build configurations. See
[`bdep-ci`](../bdep/bdep-ci.md) for options.

## Caching the build configuration directory

To avoid recreating configurations on every run, cache the bpkg configuration
directory. The directory contains `build/` output and fetched package archives.
Include the build2 version in the cache key to invalidate on upgrades.

## See also

- [`bdep-ci`](../bdep/bdep-ci.md) -- submitting to a remote CI server
- [`install-bootstrap`](../guides/install-bootstrap.md) -- installing the build2 toolchain
- [`multiple-configurations`](./multiple-configurations.md) -- managing multiple build configurations
