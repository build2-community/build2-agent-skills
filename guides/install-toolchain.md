# build2 Toolchain Install from Repository

Step 3 of the bootstrap process: building with shared libraries, installing
from the package repository, and adding optional modules.

See [install-bootstrap.md](install-bootstrap.md) for prerequisites and
Steps 1-2 (bootstrapping the `b` executable). See
[install-upgrade.md](install-upgrade.md) for the upgrade procedure.

## Step 3: Build and Install the Toolchain

After Phase 2 succeeds on any platform, the stage and install steps follow the
same pattern. Examples below show UNIX and Windows MSVC side by side where the
commands differ.

**Stage** -- build with shared libraries, install with the `-stage` suffix:

```
# UNIX (back in build2-toolchain-X.Y.Z/)
$ cd ..
$ build2/b/b-boot configure                   \
  config.build2_toolchain.build.readonly=true \
  config.cxx=g++                              \
  config.bin.lib=shared                       \
  config.bin.suffix=-stage                    \
  config.bin.rpath=/usr/local/lib             \
  config.install.root=/usr/local              \
  config.install.data_root=root/stage         \
  config.install.sudo=sudo
$ build2/b/b-boot install: build2/ bpkg/

# Windows MSVC (back in build2-toolchain-X.Y.Z\)
> cd ..
> build2\b\b-boot configure                   ^
  config.build2_toolchain.build.readonly=true ^
  config.cxx=cl                               ^
  config.bin.lib=shared                       ^
  config.bin.suffix=-stage                    ^
  config.install.root=C:\build2               ^
  config.install.data_root=root\stage
> build2\b\b-boot install: build2\ bpkg\
```

`config.install.data_root=root/stage` installs data files into a temporary
`stage/` subdirectory under the install root. This directory is removed in
Step 5.

Verify the staged tools are on PATH:

```
# UNIX
$ which b-stage
$ b-stage --version
$ bpkg-stage --version

# Windows
> where b-stage
> b-stage --version
> bpkg-stage --version
```

If the install directory is not already on PATH (e.g. `/opt/build2`), add it:

```
$ export PATH="/opt/build2/bin:$PATH"
```

**Create bpkg configuration and install from repository:**

```
# UNIX (back in build2-build/)
$ cd ..
$ mkdir build2-toolchain-X.Y
$ cd build2-toolchain-X.Y
$ bpkg-stage create               \
  cc                              \
  config.config.hermetic=true     \
  config.cxx=g++                  \
  config.cc.coptions=-O3          \
  config.bin.lib=shared           \
  config.bin.rpath=/usr/local/lib \
  config.install.root=/usr/local  \
  config.install.sudo=sudo

# Windows MSVC (back in build2-build\)
> cd ..
> md build2-toolchain-X.Y
> cd build2-toolchain-X.Y
> bpkg-stage create             ^
  cc                            ^
  config.config.hermetic=true   ^
  config.cxx=cl                 ^
  config.cc.coptions=/O2        ^
  config.bin.lib=shared         ^
  config.install.root=C:\build2
```

`config.config.hermetic=true` embeds the current environment into the `~host`
and `~build2` sub-configurations. This is important for `~build2`, which is
used to build ad hoc recipes and modules and must match the environment that
built the toolchain.

To build shared libraries only, include `config.bin.lib=shared`. Omit it to
build both shared and static. To add a custom prefix or suffix to the
installed executable names, add `config.bin.exe.prefix=...` and/or
`config.bin.exe.suffix=...`.

Fetch packages and install:

```
$ bpkg-stage add https://pkg.cppget.org/1/alpha
$ bpkg-stage fetch
$ bpkg-stage build --for install build2 bpkg bdep
$ bpkg-stage install --all
```

To pin specific versions:

```
$ bpkg-stage build --for install build2/X.Y.Z bpkg/X.Y.Z bdep/X.Y.Z
```

The script pauses at `bpkg-stage fetch` to verify the repository certificate.

Verify the final installation:

```
# UNIX
$ which b && b --version
$ which bpkg && bpkg --version
$ which bdep && bdep --version

# Windows
> where b
> b --version
```

Install the standard build system modules:

```
# UNIX
$ bpkg build --for install libbuild2-autoconf libbuild2-kconfig
$ bpkg install '!config.install.scope=project' \
  --all-pattern=libbuild2-*

# Windows
> bpkg build --for install libbuild2-autoconf libbuild2-kconfig
> bpkg install !config.install.scope=project ^
  --all-pattern=libbuild2-*
```

Verify module installation:

```
# UNIX
$ b noop: ../build2-toolchain-X.Y.Z/tests/libbuild2-*/

# Windows
> b noop: ..\build2-toolchain-X.Y.Z\tests\libbuild2-*\
```

**Clean** -- uninstall the staged tools:

```
# UNIX (back in build2-toolchain-X.Y.Z/)
$ cd ../build2-toolchain-X.Y.Z
$ b uninstall: build2/ bpkg/

# Windows
> cd ..\build2-toolchain-X.Y.Z
> b uninstall: build2\ bpkg\
```

## Local (Offline) Installation

If the machine has no network access, skip the `bpkg-stage` repository steps
and install directly from the toolchain source. Replace the Stage configure
and install commands with:

```
# UNIX
$ build2/b/b-boot configure                   \
  config.build2_toolchain.build.readonly=true \
  config.config.hermetic=true                 \
  config.cxx=g++                              \
  config.cc.coptions=-O3                      \
  config.bin.lib=shared                       \
  config.bin.rpath=/usr/local/lib             \
  config.install.root=/usr/local              \
  config.install.sudo=sudo
$ build2/b/b-boot install: build2/ bpkg/ bdep/
$ b install: '!config.install.scope=project' libbuild2-*/
```

To uninstall a local installation:

```
$ b uninstall: build2/ bpkg/ bdep/ libbuild2-*/
```

## See Also

- [install-bootstrap.md](install-bootstrap.md) -- prerequisites and bootstrap steps 1-2
- [install-upgrade.md](install-upgrade.md) -- upgrading the installed toolchain
- [`verify-install.sh`](../scripts/verify-install.sh) -- verify toolchain installation
- Download page: https://build2.org/download.xhtml
- Package repository: https://pkg.cppget.org/1/alpha
