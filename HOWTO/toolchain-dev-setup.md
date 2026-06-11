# Setting Up build2 for Toolchain Development

The build2 toolchain is self-hosted: it is built with itself. There is no
simple `git clone && bdep init` path. Use the `bootstrap` script from the
[`etc`](https://git.build2.org/cgit/etc/tree/) repository.

See also the [install and bootstrap guide](../guides/install-bootstrap.md)
for end-user installation.

## Prerequisites

1. Install the latest staged toolchain into a temporary location:

   ```
   $ sh build2-install-...-stage.sh --local /tmp/build2-install
   ```

2. Install the [CLI compiler](https://stage.build2.org/cli) using the staged
   toolchain. Either install from the package into `/usr/local`, or clone the
   CLI repo and symlink the binary.

3. Install the [ODB compiler](https://stage.build2.org/odb) using the staged
   toolchain. Match the ODB version to what `libbutl` currently uses (check
   `libbutl/libbutl-odb/odb/version.hxx`).

NOTE: The `bootstrap` script has been tested on Linux/macOS/FreeBSD. No
automated Windows path is currently provided.

## Running bootstrap

```
$ mkdir -p ~/work/build2 && cd ~/work/build2
$ git clone --recursive https://git.build2.org/etc.git
$ PATH="/tmp/build2-install/bin:$PATH" etc/bootstrap
```

Pass `--ssh` if you have read-write access to the repositories. Pass
`--clean` to retry without re-cloning. After success, remove the staged
toolchain.

## Resulting layout

```
~/work/build2/
├── builds/gcc/          -- default toolchain configuration
├── build2/              -- build system source
├── bpkg/                -- package manager source
├── bdep/                -- project manager source
├── libbpkg/             -- support libraries
├── libbutl/
└── libbuild2-*/         -- standard pre-installed build system modules
```

Symlinks are created in `/usr/local/bin/` by default. Pass `--no-symlink` to
skip this.

## Developing

Source directories are configured as forwarded to the default build
configuration. Use `bdep` or `b` directly from the source directories.

## Recovery when tools are broken

If the toolchain itself is partially broken (e.g., after a shared library
version change), rebuild with auto-sync disabled:

```
$ BDEP_SYNC=0 b build2/b/ bpkg/bpkg/ bdep/bdep/
$             b build2/b/ bpkg/bpkg/ bdep/bdep/
```

If the build system itself does not run, use the bootstrapped build system
(`b-boot`):

```
$ BDEP_SYNC=0 b-boot build2/b/
$ BDEP_SYNC=0 b      build2/b/
```

## Upgrading dependencies

Use the `upgrade` script rather than `bdep sync --upgrade` directly, to avoid
breaking the running toolchain mid-upgrade:

```
$ cd ~/work/build2 && etc/upgrade
```
