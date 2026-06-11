# build2 Toolchain Upgrade

Upgrading an installed build2 toolchain via the `bpkg` configuration in
`build2-toolchain-X.Y/`.

See [install-bootstrap.md](install-bootstrap.md) for initial installation and
[install-toolchain.md](install-toolchain.md) for the full install procedure.

## Upgrade Methods

Use the **dirty upgrade** when the new version shares the same `X.Y`
(MAJOR.MINOR) as the installed one. With patch releases the installed file
set is guaranteed not to change.

Use the **staged upgrade** when the MAJOR or MINOR version changes.

## Dirty Upgrade

```
$ cd build2-toolchain-X.Y
$ bpkg uninstall '!config.install.scope=project' \
  --all-pattern=libbuild2-*
$ bpkg drop --all-pattern=libbuild2-*
$ bpkg fetch
$ bpkg build --for install -pr
$ bpkg install --all
$ bpkg build --for install libbuild2-autoconf libbuild2-kconfig
$ bpkg install '!config.install.scope=project' \
  --all-pattern=libbuild2-*
```

`-pr` means `--patch --recursive`: upgrade to the latest patch version for
all packages and their dependencies. To check available versions before
upgrading:

```
$ bpkg status
```

To pin a specific version:

```
$ bpkg build --for install build2/X.Y.Z
```

## Staged Upgrade (X.Y to X.Z)

**Step 0 -- check for updates:**

```
$ cd build2-toolchain-X.Y
$ bpkg fetch
$ bpkg status build2 bpkg bdep
```

**Step 1 -- copy the configuration:**

```
# UNIX
$ cd ..
$ cp -rp build2-toolchain-X.Y build2-toolchain-X.Z

# Windows
> cd ..
> xcopy /s /q /i build2-toolchain-X.Y build2-toolchain-X.Z
```

**Step 2 -- build and install as `-stage`:**

```
$ cd build2-toolchain-X.Z
$ bpkg drop --all-pattern=libbuild2-*
$ bpkg build --for install -ur
$ bpkg install                        \
  config.bin.suffix=-stage            \
  config.install.data_root=root/stage \
  --all
```

**Step 3 -- test the staged toolchain:**

```
$ b-stage --version
$ bpkg-stage --version
$ bdep-stage --version
```

**Step 4 -- uninstall old, install new:**

```
$ cd ../build2-toolchain-X.Y
$ bpkg uninstall --all

$ cd ../build2-toolchain-X.Z
$ bpkg-stage install --all
$ bpkg build --for install libbuild2-autoconf libbuild2-kconfig
$ bpkg install '!config.install.scope=project' \
  --all-pattern=libbuild2-*
```

**Step 5 -- uninstall staged:**

```
$ bpkg uninstall                      \
  config.bin.suffix=-stage            \
  config.install.data_root=root/stage \
  --all
```

The `build2-toolchain-X.Y/` directory can be removed once you are satisfied
with the new version.

## Recreating the bpkg Configuration

If the `bpkg` configuration was lost but the toolchain is still installed:

```
# UNIX
$ bpkg create                   \
  cc                             \
  config.config.hermetic=true    \
  config.cxx=g++                 \
  config.cc.coptions=-O3         \
  config.bin.lib=shared          \
  config.bin.rpath=/usr/local/lib \
  config.install.root=/usr/local  \
  config.install.sudo=sudo

# Windows MSVC
> bpkg create               ^
  cc                         ^
  config.config.hermetic=true ^
  config.cxx=cl               ^
  config.cc.coptions=/O2      ^
  config.bin.lib=shared       ^
  config.install.root=C:\build2
```

Then re-add and fetch from the package repository as in the install step.

## Default Installation Paths

| Platform | Default path |
|---|---|
| UNIX / Linux / FreeBSD | `/usr/local/bin/` for executables, `/usr/local/lib/` for libraries |
| macOS | `/usr/local/bin/` (same as UNIX) |
| Windows | `C:\build2\bin\` |

On UNIX, `/usr/local/bin/` is typically already on PATH. On Windows, the
bootstrap steps add `C:\build2\bin\` to PATH manually.

Executables installed are `b` (build system), `bpkg` (package manager), and
`bdep` (project dependency manager). Build system modules (e.g.
`libbuild2-kconfig`) are installed into `lib/` under the same root.

## See Also

- [install-bootstrap.md](install-bootstrap.md) -- initial bootstrap and installation
- [install-toolchain.md](install-toolchain.md) -- full install from repository
- [b README](../b/README.md)
- [bpkg README](../bpkg/README.md)
- [`verify-install.sh`](../scripts/verify-install.sh) -- verify toolchain installation
