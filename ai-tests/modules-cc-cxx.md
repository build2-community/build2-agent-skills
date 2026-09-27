# Tests: modules-cc-cxx -- C/C++ compilation modules

Source documentation: `guides/build2-modules-cc.md`, `guides/build2-modules-cxx.md`, `guides/build2-modules-c.md`, `guides/build2-modules-misc.md`


## T001 -- C-common option variables

**Query:** What are the five `cc.*` option variables and what does each correspond to?

**Key facts** (all must appear in a correct answer):
- `cc.poptions` -- preprocessor options (e.g. `-I`, `-D`).
- `cc.coptions` -- compiler options (e.g. `-O2`, `-Wall`).
- `cc.loptions` -- linker options (e.g. `-L`, `-Wl,...`).
- `cc.aoptions` -- archiver options.
- `cc.libs` -- additional libraries to link (e.g. `-lfoo`).

**Source:** `guides/build2-modules-cc.md`


## T002 -- Compiler family IDs

**Query:** What are the `cc.id` / `cxx.id` values for GCC, vanilla Clang, Apple Clang, MSVC, and Clang-cl?

**Key facts** (all must appear in a correct answer):
- GCC: `gcc`.
- Vanilla Clang (including when targeting MSVC runtime): `clang`.
- Apple Clang: `clang-apple`.
- MSVC: `msvc`.
- Clang's `cl` compatibility driver: `msvc-clang`.

**Source:** `guides/build2-modules-cc.md`


## T003 -- CXX source target types

**Query:** What are the `cxx` module target types and their default extensions?

**Key facts** (all must appear in a correct answer):
- `cxx{}` -- C++ source file, default extension `.cxx`.
- `hxx{}` -- C++ header file, default extension `.hxx`.
- `ixx{}` -- C++ inline file, default extension `.ixx`.
- `txx{}` -- C++ template file, default extension `.txx`.
- `mxx{}` -- C++ module interface file, default extension `.mxx`.

**Source:** `guides/build2-modules-cxx.md`


## T004 -- C source target types

**Query:** What are the `c` module target types and their default extensions?

**Key facts** (all must appear in a correct answer):
- `c{}` -- C source file, default extension `.c`.
- `h{}` -- C header file, default extension `.h`.

**Source:** `guides/build2-modules-c.md`


## T005 -- in module substitution modes

**Query:** What are the two substitution modes of the `in` module, what does each do with unresolved symbols, and which is the default?

**Key facts** (all must appear in a correct answer):
- `strict` is the default mode. Every substitution symbol must start a valid substitution. Unresolved names are errors. `$$` is the escape sequence.
- `lax` mode only treats a symbol pair as a substitution if the enclosed text looks like a variable name. Unterminated symbols and non-variable-looking content are copied as-is. `$$` is not treated as an escape sequence. Unresolved substitutions are still errors unless `in.null` is set.

**Source:** `guides/build2-modules-misc.md`


## T006 -- in module key variables

**Query:** What do `in.symbol`, `in.mode`, and `in.substitutions` each control?

**Key facts** (all must appear in a correct answer):
- `in.symbol` -- the substitution symbol character (default: `$`). Must be a single character.
- `in.mode` -- the substitution mode: `strict` (default) or `lax`.
- `in.substitutions` -- key-value pairs in `name@value` form that provide substitution values; entries here take precedence over buildfile variables. Omitting the value (just `name`) sets a null value.

**Source:** `guides/build2-modules-misc.md`


## T007 -- Compile command line order and compiler mode

**Query:** In what order are `poptions`, `coptions`, and `*.mode` placed on
the compile command line, and where is `cxx.std` translated?

**Key facts** (all must appear in a correct answer):
- The compile command line is path, `poptions`, `coptions`, then `*.mode`.
- Mode options appear last.
- `cxx.std` is folded into mode (`-std=`, `/std:c++20`), not into `coptions`.
- To place a flag after those std-derived options, append with `cxx.mode +=`
  at project root after `using cxx`.

**Source:** `guides/build2-modules-cc.md`, `guides/build2-modules-cxx.md`


## T008 -- Compiler class vs. compiler ID vs. target class

**Query:** How many values does `cc.class` have, which compilers fall into
each, and why doesn't `$c.class != 'msvc'` reliably exclude every Clang
that defines `_MSC_VER`?

**Key facts** (all must appear in a correct answer):
- `cc.class` (`c.class`/`cxx.class`) is exactly two-valued: `gcc` or `msvc`.
- It groups compilers by command-line syntax, not identity: `gcc` covers
  GCC, Clang (including `clang-apple`/`clang-emscripten`), and non-Windows
  ICC; `msvc` covers real MSVC, `clang-cl`/`msvc-clang`, and Windows ICC.
- Vanilla Clang invoked through its native, gcc-compatible driver stays
  class `gcc` even when targeting `*-windows-msvc` and defining `_MSC_VER`
  -- only the `cl.exe`-compatible `clang-cl`/`msvc-clang` driver is class
  `msvc`.
- `cc.id`/`cc.id.type`/`cc.id.variant` identify the actual compiler
  (`gcc`, `clang`, `clang-apple`, `msvc-clang`, `msvc`); `cc.target.class`
  is a separate, target-platform axis (`linux`, `windows`, `macos`, ...).

**Source:** `guides/build2-modules-cc.md`
