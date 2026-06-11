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


## See Also

- [install-toolchain.md](install-toolchain.md) -- Step 3: stage, install from repository, modules
- [install-upgrade.md](install-upgrade.md) -- upgrading the installed toolchain
- [b README](../b/README.md)
- [bpkg README](../bpkg/README.md)
- [`verify-install.sh`](../scripts/verify-install.sh) -- verify toolchain installation
- Download page: https://build2.org/download.xhtml
