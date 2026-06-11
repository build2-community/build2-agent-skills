# bdep-new -- create and initialize new project

## Synopsis

```
bdep new [<options>] [--no-init] <spec> [<name>]
bdep new [<options>] --config-add|-A <cfg-dir> [@<cfg-name>] <spec> [<name>]
bdep new [<options>] --config-create|-C <cfg-dir> [@<cfg-name>] <spec> [<name>]
         [<cfg-args>]
bdep new [<options>] --package [<prj-spec>] <spec> [<name>]
bdep new [<options>] --source  [<prj-spec>] <spec> [<name>]

<spec>     = [<lang>] [<type>] [<vcs>]
<lang>     = --lang|-l (c|c++)[,<lang-opt>...]
<type>     = --type|-t (exe|lib|bare|empty)[,<type-opt>...]
<vcs>      = --vcs|-s  (git|none)[,<vcs-opt>...]
<prj-spec> = --directory|-d <prj-dir>
<cfg-args> = [-- [<bpkg-options>]] [--existing|-e | (<module> | <cfg-var>)...]
```

## Description

The `new` command creates and initializes a new project (first three forms), a
new package inside an existing project (`--package`), or a new source
subdirectory inside an existing project or package (`--source`).

All forms except `--source` create a new build2 project/package called `<name>`
inside a `<name>` subdirectory of the current working directory (unless
overridden with `--output-dir|-o` or, for `--package`, with `--directory|-d`).
If `<name>` contains a directory component the project/package is created
there as if `--output-dir|-o` had been given.

The first form then, unless `--no-init` is given, initializes an empty project
database as if by running `bdep-init --empty`. Example:

```
$ bdep new -l c++ -t exe hello
```

The second and third forms add or create a build configuration and initialize
the project in it as if by running `bdep-init --config-add` or
`bdep-init --config-create`. Example:

```
$ bdep new -l c++ -t exe -C @gcc hello cc config.cxx=g++
```

The `--package` form adds the new package to `packages.manifest` (creating the
file if needed). Nested packages are not allowed. Example:

```
$ bdep new -t empty hello
$ cd hello
$ bdep new --package -l c++ -t lib libhello
$ bdep new --package -l c++ -t exe hello
$ bdep init -C @gcc cc config.cxx=g++
```

The `--source` form acts as if it first creates a temporary project called
`<name>` then copies its source subdirectory (`name/name/` by default) into the
current working directory (unless overridden with `--output-dir|-o`). Example:

```
$ bdep new -l c++ -t bare hello
$ cd hello
$ bdep new --source -l c++ -t lib libhello
$ bdep new --source -l c++ -t exe hello
$ bdep init -C @gcc cc config.cxx=g++
```

If `<name>` is omitted the current working directory name is used as the
project/package/source subdirectory name.

The output directory may already contain files provided they do not clash with
files to be created. The `new` command recognizes certain well-known files and
tries to use the extracted information in `manifest`. Specifically, it tries to
guess the license from `LICENSE` and extract the summary from `README.md`. This
supports the following workflow:

```
# Create a project with LICENSE and README.md on a Git hosting service.
$ git clone .../libhello.git
$ cd libhello
$ bdep new -l c++ -t lib
```

Pre and post-creation hooks can be specified with `--pre-hook` and
`--post-hook`. Pre hooks run before any files are created. Post hooks run after
all files have been created. Both run in the project/package/source directory
as their working directory. Example:

```
$ bdep new --post-hook "echo .idea/ >>.gitignore" hello
```

The source subdirectory can be customized with the `subdir` type sub-option:

```
$ bdep new -l c++ -t lib,subdir=libhello/io libhello-io
```

For the source layout reference, including split layouts, see the
[Source Layout](#source-layout) section below.


## Project Type Options

Specified with `--type|-t <type>[,<opt>...]`. Default type is `exe`.

### exe -- executable project

Builds a sample C or C++ executable.

| Sub-option | Description |
|---|---|
| `no-tests` | Don't add support for functional/integration testing. |
| `unit-tests` | Add support for unit testing. |
| `no-install` | Don't add support for installing. |
| `export-stub` | Add support for importing this project's targets from other projects. |
| `prefix=<dir>` | Optional source prefix relative to project/package root. |
| `subdir=<dir>` | Alternative source subdirectory relative to source prefix. |
| `no-subdir` | Omit the source subdirectory. |
| `buildfile-in-prefix` | Create the `buildfile` in the source prefix directory rather than in its source subdirectory. |
| `third-party` | Create a package for converting an existing third-party executable to build2. Enables `no-readme` and adds third-party `manifest` values. Generates `PACKAGE-README.md` unless `no-package-readme` is given. |
| `license=<name>` | See common sub-options below. |
| `no-readme` | See common sub-options below. |
| `no-package-readme` | See common sub-options below. |
| `alt-naming` | See common sub-options below. |

### lib -- library project

Builds a sample C or C++ library.

| Sub-option | Description |
|---|---|
| `binless` | Create a header-only library. |
| `no-tests` | Don't add support for functional/integration testing. |
| `unit-tests` | Add support for unit testing. |
| `no-install` | Don't add support for installing. |
| `no-version` | Don't add support for generating the version header. |
| `no-symexport` | Don't add support for DLL symbol exporting. |
| `auto-symexport` | Add support for automatic DLL symbol exporting. |
| `prefix-include=<dir>` | Optional public header prefix relative to project/package root. |
| `prefix-source=<dir>` | Optional source prefix relative to project/package root. |
| `prefix=<dir>` | Shortcut for `prefix-include=<dir>,prefix-source=<dir>`. |
| `split` | Shortcut for `prefix-include=include,prefix-source=src`. |
| `subdir=<dir>` | Alternative source subdirectory relative to header/source prefix. |
| `no-subdir-include` | Omit the source subdirectory relative to the header prefix. |
| `no-subdir-source` | Omit the source subdirectory relative to the source prefix. |
| `no-subdir` | Shortcut for `no-subdir-include,no-subdir-source`. |
| `buildfile-in-prefix` | Create `buildfiles` in the header/source prefix directories rather than in their source subdirectories. |
| `third-party` | Create a package for converting an existing third-party library to build2. Enables `no-version`, `no-readme`, and `no-symexport` (unless `auto-symexport` is given). Generates `PACKAGE-README.md` unless `no-package-readme` is given. |
| `license=<name>` | See common sub-options below. |
| `no-readme` | See common sub-options below. |
| `no-package-readme` | See common sub-options below. |
| `alt-naming` | See common sub-options below. |

### bare -- bare project

A project without any source code that can be filled later with `--source`.

| Sub-option | Description |
|---|---|
| `no-tests` | Don't add support for testing. |
| `no-install` | Don't add support for installing. |
| `license=<name>` | See common sub-options below. |
| `no-readme` | See common sub-options below. |
| `alt-naming` | See common sub-options below. |

### empty -- empty project

An empty project to be filled with packages using `--package`.

| Sub-option | Description |
|---|---|
| `third-party` | Create a project for converting an existing third-party project. Adjusts the generated `README.md` wording to reflect the conversion. |
| `no-readme` | See common sub-options below. |

### common sub-options

These sub-options apply to multiple types above.

**`license=<name>`** -- Specify the project's license. The value can be an
SPDX License Expression (in its simplest form just the license ID) or a free
form name in the `other:` scheme. If unspecified, `other: proprietary` is
assumed.

Common SPDX IDs:

```
MIT                MIT License
BSD-2-Clause       BSD 2-Clause "Simplified" License
BSD-3-Clause       BSD 3-Clause "New" or "Revised" License
GPL-3.0-only       GNU General Public License v3.0 only
GPL-3.0-or-later   GNU General Public License v3.0 or later
LGPL-3.0-only      GNU Lesser General Public License v3.0 only
LGPL-3.0-or-later  GNU Lesser General Public License v3.0 or later
AGPL-3.0-only      GNU Affero General Public License v3.0 only
AGPL-3.0-or-later  GNU Affero General Public License v3.0 or later
Apache-2.0         Apache License 2.0
MPL-2.0            Mozilla Public License 2.0
BSL-1.0            Boost Software License 1.0
Unlicense          The Unlicense (public domain)
```

Pre-defined `other:` names:

```
other: public domain     Released into the public domain
other: available source  Not free/open source with public source code
other: proprietary       Not free/open source
other: TODO              License is not yet decided
```

**`no-readme`** -- Don't add a new `README.md` (but still check for an
existing one).

**`no-package-readme`** -- Don't add a new `PACKAGE-README.md` (but still
check for an existing one).

**`alt-naming`** -- Use the alternative build file/directory naming scheme.


## Language Options

Specified with `--lang|-l <lang>[,<opt>...]`. Default language is `c++`.

### c -- C project

| Sub-option | Description |
|---|---|
| `c++` | Allow C++ use in the C project. If specified, the `hxx`, `cxx`, `ixx`, `txx`, and `mxx` C++ sub-options may also be given. |

### c++ -- C++ project

| Sub-option | Description |
|---|---|
| `cpp` | Use `.cpp`, `.hpp`, `.ipp`, `.tpp`, `.mpp` extensions (alias for `extension=?pp`). |
| `extension=<pattern>` | Derive extensions from _pattern_ by replacing each `?` with `c`, `h`, `i`, `t`, or `m`. Default is `?xx`. |
| `hxx=<ext>` | Extension for header files (default `.hxx`). |
| `cxx=<ext>` | Extension for source files (default `.cxx`). |
| `ixx=<ext>` | Extension for inline files (if omitted, no inline files assumed). |
| `txx=<ext>` | Extension for template files (if omitted, no template files assumed). |
| `mxx=<ext>` | Extension for module interface files (if omitted, no modules assumed). |
| `c` | Allow C use in the C++ project. |

Example -- header-only library with `.h`/`.cpp` extensions:

```
$ bdep new -l c++,hxx=h,cxx=cpp -t lib,binless libhello
```


## Version Control Options

Specified with `--vcs|-s <vcs>[,<opt>...]`. Default is `git`.

### git

Initializes a `git` repository and generates `.gitignore` files.

| Sub-option | Description |
|---|---|
| `branch=<name>` | Name to use for the initial branch. |

### none

Don't initialize any version control system inside the project.


## General Options

Note: also see [common options](bdep-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--no-init` | | Don't initialize an empty build configuration set. |
| `--package` | | Create a new package inside an already existing project. |
| `--source` | | Create a new source subdirectory inside an existing project or package. |
| `--output-dir` / `-o` | `<dir>` | Create the project, package, or source subdirectory in the specified directory. |
| `--directory` / `-d` | `<dir>` | Assume the project/package is in the specified directory rather than the current working directory. Only used with `--package` or `--source`. |
| `--type` / `-t` | `<type>[,<opt>...]` | Specify project type and options (`exe`, `lib`, `bare`, `empty`). |
| `--lang` / `-l` | `<lang>[,<opt>...]` | Specify project language and options (`c`, `c++`). |
| `--vcs` / `-s` | `<vcs>[,<opt>...]` | Specify version control system and options (`git`, `none`). |
| `--pre-hook` | `<command>` | Run the specified command before creating the project/package/source directory. May be given multiple times. |
| `--post-hook` | `<command>` | Run the specified command after creating the project/package/source directory. May be given multiple times. |
| `--config-add` / `-A` | `<dir>` | Add an existing build configuration at `<dir>`. |
| `--config-create` / `-C` | `<dir>` | Create a new build configuration in `<dir>`. |
| `--no-amalgamation` | | Create a project with disabled amalgamation support (normally only used for testing). |
| `--no-checks` | | Suppress nested project/package checks (normally only used for testing). |

### Hook command details

The `<command>` value is interpreted as a whitespace-separated, potentially
quoted command line consisting of a program or a portable builtin optionally
followed by arguments and redirects. A single level of single or double quotes
is removed and whitespaces are not treated as separators inside quoted
fragments. Only `stdout` redirect to a file is currently supported.

Command line elements may contain substitutions: variable names enclosed in
`@` characters, replaced with their values at run time. Use `@@` as an escape
for a literal `@`.

Available substitution variables (also set as `BDEP_NEW_*` environment
variables):

```
@mode@ - one of 'project', 'package', or 'source'
@name@ - project, package, or source subdirectory name
@base@ - name base (name without extension)
@stem@ - name stem (name base without 'lib' prefix)
@root@ - project/package root directory
@pfx@  - combined prefix relative to project/package root
@inc@  - split header prefix relative to project/package root
@src@  - split source prefix relative to project/package root
@sub@  - source subdirectory relative to header/source prefix
@type@ - type (--type|-t value: 'exe', 'lib', etc)
@lang@ - language (--lang|-l value: 'c', 'c++', etc)
@vcs@  - version control system (--vcs|-s value: 'git', etc)
```

`@inc@` and `@src@` are only set when the prefix is split. The combined
`@pfx@` is set otherwise.

Example:

```
$ bdep new --post-hook "echo bin/ >>@name@/.gitignore" hello
```


## Source Layout

C and C++ projects use a variety of source layouts. The `new` command breaks
the path to source code into customizable components:

```
libhello/{include,src}/hello/
    ^         ^          ^
    |         |          |
 project/   source    source
 package    prefix  subdirectory
  root
```

Headers are included with the source subdirectory (if any) as a prefix, so
different combinations of prefix and subdirectory produce different include
paths even if they yield the same physical layout.

Selected layout examples:

```
# combined -- libhello/hello/
$ bdep new -l c++ -t lib,subdir=hello libhello

# combined with prefix -- hello/src/hello/
$ bdep new -l c++ -t exe,prefix=src hello

# split -- libhello/{include,src}/libhello/
$ bdep new -l c++ -t lib,split libhello

# split, header prefix only -- libhello/{include,.}/libhello/
$ bdep new -l c++ -t lib,prefix-include=include libhello

# no source subdirectory -- hello/src/
$ bdep new -l c++ -t exe,prefix=src,no-subdir hello

# all in root -- libhello/
$ bdep new -l c++ -t lib,no-subdir,no-version,no-tests libhello

# split, no subdir in source only -- libhello/{include/hello,src}/
$ bdep new -l c++ -t lib,split,subdir=hello,no-subdir-source libhello

# buildfiles in prefix (third-party packaging pattern)
$ bdep new -l c -t lib,split,subdir=hello,no-version,no-symexport,buildfile-in-prefix libhello
```

The `split` sub-option is a convenient shortcut for
`prefix-include=include,prefix-source=src`.

When packaging a third-party project, a common approach is to create a split
layout with `buildfile-in-prefix`, then add the upstream project as a `git`
submodule and replace the source subdirectories with symlinks into it.


## Default Options Files

See [bdep-default-options-files](bdep-default-options-files.md) for an
overview. For the `new` command the search start directory is the project
directory in package and source modes, and the parent directory of the new
project in all other modes. Files searched in each directory, loaded in order:

```
bdep.options
bdep-{config config-add}.options                # if --config-add|-A
bdep-{config config-add config-create}.options  # if --config-create|-C
bdep-new.options
bdep-new-{project|package|source}.options       # mode-dependent
```

The following options cannot appear in default options files:

```
--output-dir|-o
--directory|-d
--package
--source
--no-checks
--config-add|-A
--config-create|-C
--wipe
```

`--pre-hook` or `--post-hook` in remote default options files will trigger a
prompt.


## Environment

`BDEP_AUTHOR_EMAIL` -- Specifies the package email address. If not set, the
`new` command first tries to obtain the email from the version control system
(if used) then from the `EMAIL` environment variable. If all these methods
fail, a dummy `you@example.org` email is used.


## See Also

- [bdep SUMMARY](SUMMARY.md)
- [bdep-init](bdep-init.md)
- [bdep-default-options-files](bdep-default-options-files.md)
- [`header-only-library`](../HOWTO/header-only-library.md) -- binless (header-only) libraries
- [`library-provides-main`](../HOWTO/library-provides-main.md) -- library that provides main()
- [`optional-library-components`](../HOWTO/optional-library-components.md) -- making library components optional
