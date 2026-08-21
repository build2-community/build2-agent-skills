# Requesting system-provided libraries on specific CI bots

Build classes (matched by `builds:` and its per-configuration `*-builds:`
override, see `bpkg/bpkg-manifest-reference.md`) are not limited to the five
guaranteed names (`none`, `default`, `all`, `host`, `build2`): a build-bot
deployment can define additional classes of its own choosing. On cppget.org,
one such deployment-defined class is `sys` (see
https://ci.cppget.org/?build-configs for the current list; the page lists
`sys` as an available class filter with no further explanation).


## The recipe

Pair a per-configuration `*-build-config:` value listing `sys:<pkg>`
dependency specs with a matching `*-builds:` override naming the `sys` class:

```
fedora-x11-build-config: sys:libxi sys:libxrandr ; Require system X11 libraries.
fedora-x11-builds: sys
```

Two different things happen to be called "sys" here, and it is easy to
conflate them:

- `fedora-x11` (the `<name>` in `*-build-config`/`*-builds`) is an arbitrary
  configuration name chosen by the package author. Per
  `bpkg/bpkg-manifest-reference.md`, this always defines an additional
  package-specific configuration built alongside `default`, never an existing
  bot configuration, so it does not need to match any real configuration name
  on the deployment.
- `sys` in `fedora-x11-builds: sys` is the actual deployment-defined class
  that restricts which real bot machines this additional configuration is
  attempted on.

The manifest reference's own example reuses `sys` for both roles
(`sys-build-config: ?sys:libz`), which is a natural but coincidental choice,
not a requirement.


## Bare vs `?`-prefixed dependency specs

`*-build-config` grammar allows both forms:

```
sys-build-config: sys:libz  ; Build system libz to hold.
sys-build-config: ?sys:libz ; Build system libz as a dependency.
```

This `?` is the same `pkg-spec` flag documented under "Hold vs dependency" in
`bpkg/bpkg-pkg-build.md`, not a manifest `depends:` condition. Without it, the
package is built to hold (kept explicitly, not automatically dropped). With
it, the package is built as a dependency (kept only while something still
depends on it, dropped automatically once nothing does). The manifest
reference's own example uses `?sys:` because libz there is genuinely a
dependency of the package under test.


## What has to be true for sys: resolution to succeed

Resolving a `sys:<pkg>` dependency spec (see the `sys:` scheme in
`bpkg/bpkg-pkg-build.md`) queries the system package manager for an
already-installed version of that package. It does not build from source,
and without `--sys-install` it does not install anything either.

Neither `build2-toolchain` nor cppget.org's own build-configs page documents
what selecting the `sys` class specifically does. The best-supported
explanation: it most plausibly identifies the subset of bot machines
cppget.org has provisioned with the relevant system libraries already
installed, so that `sys:<pkg>` resolution has something to find there. This
is a deployment convention, not a documented mechanism.

Note that `bbot` (the build bot software) does have a worker step named
`bbot.sys-install`, but it is unrelated to this: it installs a package's own
freshly generated binary distribution artifact (via `apt-get install` or
`dnf install`) to verify that the artifact itself installs cleanly. It plays
no part in resolving a package's `sys:` dependencies.


## Scope

This mechanism only applies to libraries an actual system package manager
(apt, dnf, Homebrew, and similar) distributes. It does not extend to
OS/SDK-bundled frameworks that ship under no installable package name (for
example Apple's Metal, Cocoa, IOKit, and CoreVideo frameworks): there is no
system-package-manager entry for `sys:` resolution to query in the first
place, so such frameworks are typically linked directly instead (for example
via `-framework`).


## See also

- `bpkg/bpkg-manifest-reference.md` -- `builds` and `*-build-config` field reference
- `bpkg/bpkg-pkg-build.md` -- hold vs dependency, and the `sys:` scheme
- `HOWTO/builds-ci-filtering.md` -- per-configuration override recipes this extends
