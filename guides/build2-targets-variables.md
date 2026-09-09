# build2 Targets and Variables Reference

## Built-in Target Types

build2 organises target types in a base-derived inheritance tree. The root is
the abstract `target{}` type. The core defines the standard types listed here.
Modules add further types (for example the `cxx` module adds `cxx{}`, `hxx{}`).

### Type hierarchy (core)

```
                   .-----target*------------.
                   |                 |      |
              mtime_target*---.    alias  fsdir
                   |          |      |
              path_target*  group   dir
                   |
        .---------file----------.
        |          |     |      |
  .----doc-----.  exe  json  buildfile
  |     |      |
legal  man  manifest
        |
       man<N>
```

Types marked with `*` are abstract and normally appear only in patterns and
rule definitions, not in dependency declarations.

### Core target type table

| Target type | Description |
|---|---|
| `target{}` | Abstract root of all target types |
| `mtime_target{}` | Abstract, uses modification time to detect staleness |
| `path_target{}` | Abstract, has a corresponding filesystem path |
| `alias{}` | Non-file target that acts as an alias for its prerequisites (like a phony `make` target) |
| `dir{}` | Special alias representing a directory; building it builds everything in that directory |
| `fsdir{}` | Filesystem directory. Listed as a prerequisite it is created on `update` and removed on `clean`. Parent directories are auto-created only out-of-tree (see [fsdir-parent-chain](../HOWTO/fsdir-parent-chain.md)) |
| `group{}` | User-defined explicit target group whose members are all built by a single recipe |
| `file{}` | Generic file with no default extension; base for most file-based types |
| `doc{}` | Generic documentation file, installed to `doc/` by default |
| `legal{}` | Legal documentation (licenses, notices); installed to `legal/` |
| `man{}` | Manual page; requires an explicit extension; installed to `man/` |
| `man1{}` .. `man9{}` | Manual page sections 1-9; fixed default extension `.<N>`; installed to `man<N>/` |
| `exe{}` | Executable file; extension assigned by the link rule (host platform for input targets) |
| `json{}` | JSON text file; default extension `.json` |
| `buildfile{}` | build2 buildfile fragment |
| `manifest{}` | Package manifest file |

The built-in `fsdir{}` rule auto-creates parent directories only when the
target is out-of-tree. In-source (`b dist` then `configure` then `update` of
the unpacked archive) every missing level needs an explicit
`fsdir{}`-to-`fsdir{}` prerequisite. See
[fsdir-parent-chain.md](../HOWTO/fsdir-parent-chain.md).

### Module-provided target types (C/C++)

| Target type | Description |
|---|---|
| `c{}` | C source file (default extension `.c`) |
| `h{}` | C header file (default extension `.h`) |
| `cxx{}` | C++ source file (default extension `.cxx`, customisable) |
| `hxx{}` | C++ header file (default extension `.hxx`, customisable) |
| `ixx{}` | C++ inline implementation file |
| `txx{}` | C++ template implementation file |
| `mxx{}` | C++ module interface unit |
| `obj{}` | Object file (abstract synonym for `obje{}` / `obja{}` / `objs{}`) |
| `obje{}` | Object file for an executable |
| `obja{}` | Object file for a static library |
| `objs{}` | Object file for a shared library |
| `lib{}` | Library convenience alias for `liba{}` or `libs{}` or both |
| `liba{}` | Static library |
| `libs{}` | Shared library |
| `libue{}` | Utility static library (linked into executables) |
| `libua{}` | Utility static library (linked into static libraries) |
| `libus{}` | Utility static library (linked into shared libraries) |

## Target Qualification and Naming

A target is written as `<type>{<name>}`. The name may include a relative or
absolute directory path prefix. Examples:

```
exe{hello}
cxx{hello}
doc{README.md}
man1{foo}
```

Multiple names sharing the same type can be grouped with a compound form:

```
{hxx ixx}{string}        # hxx{string} and ixx{string}
{hxx cxx}{**}            # all C++ headers and sources recursively
```

Extensions can be specified explicitly inside the name to override or supply
what the type's default does not provide:

```
exe{utility.com}         # explicit .com extension
cxx{utility.cc}          # override default .cxx
hxx{utility.}            # name without extension (trailing dot)
```

Project-qualified names cross project boundaries for importation:

```
libs{libhello%lib{hello}}
```

To define a new project-local target type, use `define`:

```
define md: doc
doc{*}: extension = md

./: md{README PACKAGE-README INSTALL}
```

### Src/out qualification

Every build has two parallel directory trees, **src** and **out** (the same
directory in an in-source build). A **target** named in a buildfile is, by
default, resolved in **out**. **Prerequisites** (the right-hand side of a
dependency) have no src/out notion of their own: they are resolved however
their target type's rule prefers -- for `file{}`-based prerequisites, out is
searched first and, failing that, an existing file in src is used. This is
why ordinary source files listed as prerequisites (`exe{hello}: cxx{hello}`)
never need any `@`-qualification: the fallback finds them in src on its own.

The **elaborate target specification**, `<src-spec>@<out-spec>`, is for the
cases where the out-by-default guess is wrong and a *target* (not a
prerequisite) must resolve against a specific directory:

```
<src>@<out>
```

- On the command line, this pairs a source directory with an out-of-source
  build directory, e.g. `b hello/@hello-out/`. See ["Out of source
  builds"](build2-buildfile-language.md#out-of-source-builds).
- Inside a buildfile, `@./` pins a target that is on the **left-hand side**
  of a dependency declaration -- and would otherwise default to out -- to
  the current directory's src tree instead. This comes up for pure source
  files that are never generated, typically to attach a directory-scope
  attribute to one:

  ```
  doc{INSTALL}@./: install = false
  ```

  Without `@./`, build2 would look for a generated `INSTALL` in **out**
  and find nothing there to attach the variable to.

**`@./` only changes which directory a target's path resolves against.** It
has no bearing on whether writing `<target>: <prerequisite>` registers
`<target>` as a target this buildfile independently declares -- that
happens from the dependency declaration itself, regardless of `@`.
Conflating the two is a real pitfall: see
[test-runtime-fixtures.md](../HOWTO/test-runtime-fixtures.md#why-the-executable-not-the-testscript)
for a worked example where giving a `testscript{}` its own `@./`-qualified
dependency declaration (instead of leaving it as an ordinary prerequisite)
breaks `b clean`, even though the `@./` itself is correct and necessary
there.

## Variable Types

The following types can be used in buildfiles:

| Type | Description |
|---|---|
| `bool` | Boolean: `true` or `false` |
| `int64` | Signed 64-bit integer |
| `int64s` | List of `int64` |
| `uint64` | Unsigned 64-bit integer |
| `uint64s` | List of `uint64` |
| `string` | Single string value |
| `strings` | List of strings |
| `string_set` | Ordered set of strings |
| `string_map` | Map of string to string |
| `path` | Filesystem path |
| `paths` | List of paths |
| `dir_path` | Directory path (always ends with `/`) |
| `dir_paths` | List of directory paths |
| `json` | JSON/JSON5 value |
| `json_array` | JSON array |
| `json_object` | JSON object |
| `json_set` | JSON set |
| `json_map` | JSON map |
| `name` | build2 target/prerequisite name |
| `names` | List of names |
| `name_pair` | Pair of names |
| `cmdline` | Command-line argument list |
| `project_name` | Project name |
| `target_triplet` | `cpu-vendor-os` triplet |

Assign a type with the attribute syntax:

```
x = [uint64] 42
y = [strings] foo bar baz
```

## Variable Assignment Operators

| Operator | Name | Semantics |
|---|---|---|
| `=` | replace | Assign a new value, discarding any existing one |
| `+=` | append | Add the right-hand side to the end of the existing value |
| `=+` | prepend | Add the right-hand side before the existing value |
| `?=` | default | Assign only if the variable is currently undefined |
| `?+=` | conditional append | Append only if the variable is currently defined |

Examples:

```
x = foo            # replace
x += bar           # x is now 'foo bar'
x =+ baz           # x is now 'baz foo bar'

y ?= default       # assign 'default' only if y is undefined

cxx.poptions =+ "-I$out_root" "-I$src_root"   # prepend include paths
cxx.poptions += -DNDEBUG                       # append a define
```

The `?=` operator is mandatory inside the `config` directive for configuration
variables.

For module lists such as `cxx.poptions` and `bin.rpath`, a target-specific
`=` replaces the outer value, including `config.*`. Use `+=`. Export lists
(`*.export.*`) are assigned. See
[Assign vs append on lists](../HOWTO/buildfile-compile-options.md#assign-vs-append-on-lists).

## Variable Scopes

build2 organises variables in a hierarchical scope tree that mirrors the
directory tree of the project.

**Global scope** - the read-only root of the hierarchy, contains build-wide
variables such as `build.host`, `build.host.class`, `build.host.cpu`, etc.

**Project root scope** - loaded from `build/bootstrap.build` and
`build/root.build`; contains `src_root`, `out_root`, `project`, `version`,
and all module-level variables.

**Directory scope** - each subdirectory with a `buildfile` has its own scope
nested inside the root scope; contains `src_base` and `out_base`.

**Target scope** - a target can have variables set specifically on it using
the target-specific syntax `target{name}: variable = value`.

**Prerequisite scope** - a prerequisite can have variables set specifically
on it using the prerequisite-specific syntax
`target{t}: prereq{p}: variable = value`.

Variable lookup walks from the innermost scope outward to the global scope.
Visibility can be restricted:

- Default: visible project-wide and in outer scopes.
- Project: visible within the project only.
- Scope: visible within the current directory scope and nested scopes.
- Target: visible only on the target.
- Prerequisite: visible only on the prerequisite.

Configuration variables declared with the `config` directive are entered with
global visibility and marked as overridable (a command-line value overrides
any buildfile assignment).

Names starting with `_`, and names in the `build`, `import`, or `export`
namespaces (and any component named `build`) are reserved:

```
_x = 1        # error
build.x = 1   # error
x.build.y = 1 # error
```

## Variable Expansion

Basic expansion:

```
info $src_root          # print the src_root variable
info $project           # print the project name
```

Eval context (parentheses allow expressions):

```
cxx.poptions += "-I$(out_root)/include"
x = ($cxx.target.class == 'linux' ? linux-impl : generic-impl)
```

Null and undefined:

```
x = [null]              # assign null
if ($x == [null])       # test for null

if $defined(y)          # test whether y is defined
```

List indexing (zero-based):

```
first = $libs[0]
```

## Built-in Variables

The following variables are set automatically by the build system core.

### Scope variables (set on each scope)

| Variable | Type | Description |
|---|---|---|
| `src_base` | `dir_path` | Absolute path to the source directory for this scope |
| `out_base` | `dir_path` | Absolute path to the output directory for this scope |

### Root scope variables (set on the project root scope)

| Variable | Type | Description |
|---|---|---|
| `src_root` | `dir_path` | Absolute path to the project source root |
| `out_root` | `dir_path` | Absolute path to the project output root |
| `project` | `project_name` | Project name (set in `bootstrap.build`) |
| `version` | `string` | Full version string (set by the `version` module) |
| `version.major` | `uint64` | Major version component |
| `version.minor` | `uint64` | Minor version component |
| `version.patch` | `uint64` | Patch version component |
| `version.pre_release` | `bool` | True if this is a pre-release version |

### Global scope variables

| Variable | Type | Description |
|---|---|---|
| `build.host` | `target_triplet` | Build host `cpu-vendor-os` triplet |
| `build.host.class` | `string` | Host OS class (`linux`, `windows`, `macos`, `bsd`, etc.) |
| `build.host.cpu` | `string` | Host CPU architecture |
| `build.host.system` | `string` | Host OS system |
| `build.meta_operation` | `string` | Current meta-operation name (`perform`, `configure`, etc.) |

### Configuration root variables

| Variable | Description |
|---|---|
| `src_root` | Source root recorded for an out-of-source build |
| `config.cxx` | C++ compiler executable (set by `config.cxx=...` on command line) |
| `config.cxx.coptions` | C++ compile options |
| `config.cxx.poptions` | C++ preprocessor options |
| `config.cxx.loptions` | C++ link options |
| `config.cxx.aoptions` | C++ archive options |
| `config.cxx.libs` | Extra C++ link libraries |
| `config.import.<project>` | Import override for a project |

## Function Families

Functions in build2 are organised into families, such as `$string.*()` for
string manipulation or `$regex.*()` for regular expressions. Most functions
are pure. Impure functions (for example `$builtin.getenv()`) are explicitly
documented as such.

Every function can always be called with its full family-qualified name. Some
families additionally allow unqualified calls when the argument type makes the
family unambiguous. Functions in the `$regex.*()` family are an exception: they
must always be called with the full `$regex.` prefix.

| Family | Purpose | Qualification |
|---|---|---|
| `$builtin.*()` | Fundamental build2 functions | optional |
| `$string.*()` | String manipulation | optional |
| `$integer.*()` | Integer arithmetic | optional |
| `$bool.*()` | Boolean operations | optional |
| `$path.*()` | Filesystem path manipulation | optional |
| `$name.*()` | Target and prerequisite names | optional |
| `$target.*()` | Operate on actual targets | optional |
| `$regex.*()` | ECMAScript regex match and substitution | **required** |
| `$json.*()` | JSON, JSON5, and JSON5E values | optional |
| `$process.*()` | Process operations | optional |
| `$filesystem.*()` | Filesystem operations | optional |
| `$project_name.*()` | `project_name` type | optional |
| `$process_path.*()` | `process_path` and `process_path_ex` types | optional |
| `$target_triplet.*()` | `cpu-vendor-os` target triplets | optional |

For the complete per-function reference including all overloads, optional
arguments, flags, and purity annotations, see
[build2-functions.md](build2-functions.md).

## See Also

- [build2 built-in functions reference](build2-functions.md)
- [build2 manual summary](build2-intro-concepts.md)
- [Directives, name patterns, and attributes](build2-directives-patterns.md)
- [Buildfile language: out-of-source builds](build2-buildfile-language.md#out-of-source-builds): `@` on the command line
- [test-runtime-fixtures.md](../HOWTO/test-runtime-fixtures.md): a real-world `@./` pitfall (breaking `b clean`)
- [fsdir-parent-chain.md](../HOWTO/fsdir-parent-chain.md): `fsdir{}` parent auto-creation is out-of-tree only
