# build2 Installation and Bootstrap Guide

## Overview

Bootstrapping means building the `build2` toolchain from its own source. It is
necessary the first time you install `build2` on a machine where no pre-built
packages are available or when you need a configuration not covered by
pre-built packages. Once the toolchain is installed, all future upgrades are
handled uniformly through `bpkg` on any platform.

The bootstrap process follows 5 phases on every platform:

1. Bootstrap Phase 1 -- build a minimal `b` executable from a shell script or
   batch file.
2. Bootstrap Phase 2 -- rebuild `b` with static libraries using the Phase 1
   result.
3. Stage -- build `b` and `bpkg` with shared libraries and install them with a
   `-stage` suffix.
4. Install -- use the staged tools to fetch and install the full toolchain from
   the package repository.
5. Clean -- uninstall the staged tools.

The end result is the installed toolchain (`b`, `bpkg`, `bdep`) plus a `bpkg`
configuration directory (`build2-toolchain-X.Y/`) used for future upgrades.

**Bootstrapping vs. pre-built packages.** If your platform is supported and
you have network access, downloading the pre-built toolchain archive from
https://build2.org/download.xhtml is faster and simpler. Use bootstrapping
when pre-built packages are unavailable, you are on an airgapped machine, or
you want to select a specific compiler or installation path.

In this guide `$` denotes a UNIX shell prompt and `>` denotes the Windows
command prompt. Line continuations use `\` on UNIX and `^` on Windows.
Replace `X.Y.Z` with the actual release version throughout.


## Option 1: Install from Pre-built Packages

Pre-built toolchain archives for common platforms are published at
https://build2.org/download.xhtml.

For UNIX-like systems the archive is `build2-toolchain-X.Y.Z.tar.xz` (or
`.tar.gz` if `xz` is unavailable). For Windows, a separate
`build2-baseutils-X.Y.Z-x86_64-windows.zip` provides the required POSIX
utilities, and an optional `build2-mingw-X.Y.Z-x86_64-windows.tar.xz`
provides a minimal MinGW-W64 GCC.

**Verify the download** before unpacking. A `.sha256` checksum file accompanies
each archive:

```
# Linux / WSL / MSYS / Cygwin:
$ sha256sum -c build2-toolchain-X.Y.Z.tar.xz.sha256

# macOS:
$ shasum -a 256 -c build2-toolchain-X.Y.Z.tar.xz.sha256

# FreeBSD (compare visually):
$ cat build2-toolchain-X.Y.Z.tar.xz.sha256
$ sha256 -r build2-toolchain-X.Y.Z.tar.xz

# Windows (compare visually):
> type *.sha256
> for %f in (*.zip *.xz) do certutil -hashfile %f SHA256
```

After verifying, unpack, run the appropriate automated build script (see
Option 2 below for the full manual procedure), or follow the platform
bootstrap steps directly.


## Option 2: Bootstrap from Source

### Prerequisites

The `build2` toolchain requires a C++14 compiler to build. The compiler used
to build `build2` does not need to match the compiler used for your own
projects.

| Platform | Minimum requirement |
|---|---|
| GNU/Linux, FreeBSD | GCC 4.9 or Clang 3.7 |
| macOS | Apple Clang (Xcode Command Line Tools) or GCC via Homebrew |
| Windows MSVC | Visual Studio 2015 Update 3 (MSVC 14) or later |
| Windows Clang | Clang 8 or later (bundled with MSVC or separate) |
| Windows MinGW | MinGW-W64 GCC 4.9 or later, built with `posix` threading model |
| WSL / MSYS / Cygwin | GCC 4.9 or Clang 3.7 (follow UNIX instructions) |

On Windows, the `build2-baseutils` package provides required utilities
(`install`, `diff`, `curl`, `tar`, etc.). It must be installed before
bootstrapping. The `build2-mingw` package provides a ready-made MinGW-W64 GCC
if you do not have your own. Both packages are available from the download page.

On macOS, verify that Command Line Tools are installed:

```
$ clang++ --version
```

If not present, install them:

```
$ xcode-select --install
```


### Step 1: Download the Amalgamation

**UNIX and macOS:**

```
$ cd
$ mkdir build2-build
$ cd build2-build
```

Download `build2-toolchain-X.Y.Z.tar.xz` and its `.sha256` checksum from
https://build2.org/download.xhtml, place both in `~/build2-build/`, verify,
then unpack:

```
$ sha256sum -c build2-toolchain-X.Y.Z.tar.xz.sha256
$ tar -xf build2-toolchain-X.Y.Z.tar.xz
$ cd build2-toolchain-X.Y.Z
```

**Windows:**

```
> cd /D C:\
> mkdir build2-build
> cd build2-build
```

Download the following files from https://build2.org/download.xhtml into
`C:\build2-build\`:

```
build2-baseutils-X.Y.Z-x86_64-windows.zip
build2-mingw-X.Y.Z-x86_64-windows.tar.xz   (if using the bundled MinGW)
build2-toolchain-X.Y.Z.tar.xz
```

Verify checksums (compare visually):

```
> type *.sha256
> for %f in (*.zip *.xz) do certutil -hashfile %f SHA256
```

Unpack `build2-baseutils` to `C:\build2\` (this is the installation
directory):

```
(use Windows Explorer to extract the zip, then rename the folder to C:\build2)
```

Set PATH and verify utilities:

```
> set "PATH=C:\build2\bin;%PATH%"
> where tar
> tar --version
```

Optionally unpack the MinGW package into `C:\build2\`:

```
> xz -d build2-mingw-X.Y.Z-x86_64-windows.tar.xz
> tar -xf build2-mingw-X.Y.Z-x86_64-windows.tar ^
  --one-top-level=C:\build2 --strip-components=1
> where g++
> g++ --version
```

Unpack the toolchain source:

```
> xz -d build2-toolchain-X.Y.Z.tar.xz
> tar -xf build2-toolchain-X.Y.Z.tar
> cd build2-toolchain-X.Y.Z
```


### Step 2: Bootstrap build2

You may use the automated script or perform the steps manually. The script
and the manual steps produce identical results. Do not run both.

#### UNIX and macOS (automated)

```
$ ./build.sh g++
```

With Clang and a custom install path:

```
$ ./build.sh --install-dir /opt/build2 --sudo sudo clang++
```

With parallel compilation via GNU make:

```
$ ./build.sh --make make --make -j8 g++
```

The script pauses at `bpkg fetch` to ask you to confirm the repository
certificate. To run unattended, pass `--trust <fingerprint>` (see
`build.sh -h`).

#### UNIX and macOS (manual)

**Phase 1** -- build a minimal `b` from the bootstrap script:

```
$ cd build2
$ ./bootstrap.sh g++ -w
$ b/b-boot --version
```

Parallel alternative using GNU make:

```
$ make -f bootstrap.gmake -j8 CXX=g++ CXXFLAGS=-w
$ b/b-boot --version
```

**Phase 2** -- rebuild with static libraries:

```
$ b/b-boot                                    \
  config.build2_toolchain.build.readonly=true \
  config.cxx=g++                              \
  config.bin.lib=static                       \
  b/exe{b}
$ mv b/b b/b-boot
$ b/b-boot --version
```

#### Windows MSVC (automated)

Start the Visual Studio "x64 Native Tools Command Prompt", set PATH, then run:

```
> set "PATH=C:\build2\bin;%PATH%"
> .\build-msvc.bat
```

Pass `--trust <fingerprint>` to run unattended (see `build-msvc.bat /?`).

#### Windows MSVC (manual)

**Phase 1:**

```
> cd build2
> .\bootstrap-msvc.bat cl /w /MP8
> b\b-boot --version
```

**Phase 2:**

```
> b\b-boot                                    ^
  config.build2_toolchain.build.readonly=true ^
  config.cxx=cl                               ^
  config.bin.lib=static                       ^
  b\exe{b}
> move /y b\b.exe b\b-boot.exe
> b\b-boot --version
```

#### Windows MinGW (automated)

```
> .\build-mingw.bat C:\mingw\bin\g++
```

Or, when using the bundled `build2-mingw` package:

```
> .\build-mingw.bat g++
```

With parallel make:

```
> .\build-mingw.bat --make mingw32-make --make -j8 g++
```

If your own MinGW distribution is used, copy the required DLLs to
`C:\build2\bin\` so the resulting binaries run standalone:

```
libwinpthread-1.dll
libstdc++-6.dll
libgcc_s_*.dll
```

#### Windows MinGW (manual)

**Phase 1:**

```
> cd build2
> .\bootstrap-mingw.bat g++ -w -static
> b\b-boot --version
```

**Phase 2:**

```
> b\b-boot                                    ^
  config.build2_toolchain.build.readonly=true ^
  config.cxx=g++                              ^
  config.bin.lib=static                       ^
  b\exe{b}
> move /y b\b.exe b\b-boot.exe
> b\b-boot --version
```

#### Windows Clang (automated)

For Clang bundled with MSVC, start the "x64 Native Tools Command Prompt" and
add Clang to PATH:

```
> set "PATH=C:\build2\bin;%VCINSTALLDIR%Tools\Llvm\bin;%PATH%"
> where clang++
> .\build-clang.bat
```

For a standalone Clang installation, `clang++` is already in PATH after the
common setup steps:

```
> .\build-clang.bat
```

#### Windows Clang (manual)

**Phase 1:**

```
> cd build2
> .\bootstrap-clang.bat clang++ -m64 -w
> b\b-boot --version
```

**Phase 2:**

```
> b\b-boot                                    ^
  config.build2_toolchain.build.readonly=true ^
  "config.cxx=clang++ -m64"                   ^
  config.bin.lib=static                       ^
  b\exe{b}
> move /y b\b.exe b\b-boot.exe
> b\b-boot --version
```


### Step 3: Build and Install the Toolchain

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

#### Local (offline) installation

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


## Upgrade

Upgrades are performed through the `bpkg` configuration in
`build2-toolchain-X.Y/`. There are two methods: dirty (quick, for patch
releases) and staged (safe, for minor or major version changes).

Use the dirty upgrade when the new version shares the same `X.Y`
(MAJOR.MINOR) version. With patch releases, the installed file set is
guaranteed not to change.

Use the staged upgrade when the MAJOR or MINOR version changes.

### Dirty upgrade

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

### Staged upgrade (X.Y to X.Z)

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

### Recreating the bpkg configuration

If the `bpkg` configuration was lost but the toolchain is still installed, you
can recreate it:

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

- [b SUMMARY](../b/SUMMARY.md)
- [bpkg SUMMARY](../bpkg/SUMMARY.md)
- [`verify-install.sh`](../scripts/verify-install.sh) -- verify toolchain installation
- Download page: https://build2.org/download.xhtml
- Package repository: https://pkg.cppget.org/1/alpha
