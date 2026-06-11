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
| `fsdir{}` | Filesystem directory; listed as a prerequisite it is created on `update` and removed on `clean` |
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
| `config.src_root` | Source root recorded for an out-of-source build |
| `config.cxx` | C++ compiler executable (set by `config.cxx=...` on command line) |
| `config.cxx.coptions` | C++ compile options |
| `config.cxx.poptions` | C++ preprocessor options |
| `config.cxx.loptions` | C++ link options |
| `config.cxx.aoptions` | C++ archive options |
| `config.cxx.libs` | Extra C++ link libraries |
| `config.import.<project>` | Import override for a project |

## Built-in Functions

Functions are organised into families. All functions can be called with the
family prefix. Some can be called unqualified when the argument type is
unambiguous.

### Builtin functions (`$builtin.*()`)

| Function | Description |
|---|---|
| `$defined(var)` | Return `true` if variable is defined (not undefined) |
| `$null(val)` | Return `true` if value is null |
| `$empty(val)` | Return `true` if value is null or an empty list |
| `$size(list)` | Return number of elements in a list |
| `$type(val)` | Return the type name of a value as a string |
| `$getenv(name)` | Return the value of an environment variable, or null |

### String functions (`$string.*()`)

| Function | Description |
|---|---|
| `$string(val)` | Convert value to a string |
| `$string.contains(str, substr)` | Return `true` if string contains substring |
| `$string.starts_with(str, prefix)` | Return `true` if string starts with prefix |
| `$string.ends_with(str, suffix)` | Return `true` if string ends with suffix |
| `$string.trim(str)` | Return string with leading and trailing whitespace removed |
| `$string.upcase(str)` | Return string converted to upper case |
| `$string.downcase(str)` | Return string converted to lower case |
| `$string.length(str)` | Return the number of characters |

### Integer functions (`$integer.*()`)

| Function | Description |
|---|---|
| `$integer.string(n)` | Convert integer to string |

### Path functions (`$path.*()`)

| Function | Description |
|---|---|
| `$path(target)` | Return the filesystem path of a target |
| `$path.base(path)` | Return path without the extension |
| `$path.extension(path)` | Return the file extension (without leading `.`) |
| `$path.leaf(path)` | Return the filename component |
| `$path.directory(path)` | Return the directory component |
| `$path.complete(path)` | Return an absolute path (relative to `src_base`) |
| `$path.canonicalize(path)` | Return a canonicalized path |
| `$path.normalize(path)` | Return a normalized path |

### Name functions (`$name.*()`)

| Function | Description |
|---|---|
| `$name.name(name)` | Return the unqualified name |
| `$name.type(name)` | Return the target type of a name |
| `$name.dir(name)` | Return the directory component of a name |
| `$recall(process_path)` | Return the recall path of an executable |

### Target functions (`$target.*()`)

| Function | Description |
|---|---|
| `$path(target)` | Return the filesystem path of a target |
| `$process_path(target)` | Return the process path for an executable target |

### Regex functions (`$regex.*()`, always require family prefix)

| Function | Description |
|---|---|
| `$regex.match(str, pattern)` | Return `true` if string matches ECMAScript regex |
| `$regex.search(str, pattern)` | Return `true` if regex matches anywhere in string |
| `$regex.replace(str, pattern, fmt)` | Return string with regex substitution applied |
| `$regex.split(str, pattern, fmt)` | Split string by regex pattern; return list |
| `$regex.merge(list, pattern, fmt [, delim])` | Apply regex to each element and join results |
| `$regex.apply(list, pattern, fmt)` | Apply regex substitution to each element of a list |
| `$regex.filter(list, pattern)` | Keep elements matching pattern |
| `$regex.filter_out(list, pattern)` | Remove elements matching pattern |

### JSON functions (`$json.*()`)

| Function | Description |
|---|---|
| `$json.load(path)` | Load a JSON file and return the parsed value |
| `$json.value_type(val)` | Return the JSON type name of a value |
| `$json.member_name(member)` | Return the name of a JSON object member |
| `$json.member_value(member)` | Return the value of a JSON object member |

### Process functions (`$process.*()`)

| Function | Description |
|---|---|
| `$process.run(cmd...)` | Run a command and return its stdout as a string (trimmed) |
| `$process.run_regex(cmd..., pattern, fmt)` | Run a command and apply regex to stdout |
| `$process.run_regex_lines(cmd..., pattern, fmt)` | Run and apply regex per-line; return list |

### Filesystem functions (`$filesystem.*()`)

| Function | Description |
|---|---|
| `$path_search(pattern [, dir])` | Search for files matching a path pattern; return list |

## Directives

### `define`

```
define <derived>: <base>
```

Derive a new project-local target type from an existing one. The new type can
be given a default extension via a type/pattern-specific variable:

```
define md: doc
doc{*}: extension = md
```

### `using`

```
using <module>
```

Load a build system module into the current project. Must appear in
`build/root.build` for project-wide modules. Loading a module registers its
target types, rules, and variables.

```
using cxx
using config
using test
using install
```

### `import`

```
import [!] <var> = <project>%<target>
```

Import a target from another project. The build system locates the project
and makes its exported target available as the value of `<var>`. Using `!`
makes the import required (error if not found):

```
import  libs = libhello%lib{hello}
import! foo  = foo%exe{foo}
```

### `include`

```
include <file>
include <directory>
```

Load a buildfile in its corresponding directory scope. Subsequent inclusions
of the same file are automatically ignored. Use this to access non-directory
targets from another buildfile within the same project.

### `source`

```
source <file>
```

Load the specified file in the current scope (as if its contents were pasted
inline). Unlike `include`, the same file can be sourced multiple times.

### `update`

```
update <target>...
```

Update the specified targets during buildfile evaluation (load phase) before
continuing. Used when target content is needed to make conditional build
decisions. Should be limited to the `perform` meta-operation when possible:

```
if ($build.meta_operation == 'perform')
{
  update buildfile{config-info}
  source $path(buildfile{config-info})
}
```

### `if` / `elif` / `else`

```
if <condition>
  ...
elif <condition>
  ...
else
  ...
```

Conditional evaluation. The condition must expand to the literal `true` or
`false`. Negating variants `if!` and `elif!` negate the condition. Shorthand
forms `ifn` (if null), `ife` (if empty) and their negations are also available.

Use the prerequisite-specific `include` variable for conditional prerequisites
rather than `if`:

```
# Correct: lists all sources unconditionally, uses include= for conditions.
exe{hello}: cxx{hello-linux}: include = ($cxx.target.class == 'linux')
exe{hello}: cxx{hello-win32}: include = ($cxx.target.class == 'windows')
```

### `switch` / `case` / `default`

```
switch <expr> [, <expr>...]
{
  case <pattern> [, <pattern>...]
    ...
  default
    ...
}
```

Match one or more expressions against patterns. First matching `case` is
evaluated; no fall-through. Multiple `case` lines can precede a single
fragment to express OR logic.

### `for`

```
for <var>: <list>
{
  ...
}
```

Iterate over a list. Loop variable and any variables set inside are visible
after the loop. `continue` and `break` are available.

### `while`

```
while <condition>
{
  ...
}
```

Repeat while condition is `true`. Negating variant `while!` is also available.

### `assert`

```
assert <condition> ['<message>']
```

Assert that a condition is true; print the message and fail the build if not:

```
assert ($size($config.hello.database) > 0) \
  'database must be specified with config.hello.database'
```

### `fail`

```
fail '<message>'
```

Unconditionally fail the build with a diagnostic message:

```
fail "unsupported platform: $cxx.target.class"
```

### `info`, `warn`, `error`

Print a diagnostic message. `error` fails the build after printing.

```
info "building for $cxx.target"
warn "config.foo is deprecated"
error "required value missing"
```

### `print`

Print a value to stdout (used for debugging):

```
print $x
```

### `dump`

Dump the current scope or a target's variable state to stderr:

```
dump
```

Also available as the command-line option `--dump match` or
`--dump-scope <path>` for selective inspection.

### `run`

```
run <program> [<args>...]
```

Run a program during buildfile evaluation and read its stdout output line by
line, each sourced into the current scope as a buildfile fragment.

### `config.environment`

```
config.environment <VAR> [<VAR>...]
```

Report environment variables that affect the build result (used for hermetic
configurations and dependency tracking in ad hoc recipes).

## Name Patterns

In prerequisite lists, names can be generated by wildcard patterns. A pattern
is any name value containing unquoted wildcard characters.

### Wildcard characters

| Pattern | Matches |
|---|---|
| `*` | Any number of characters in a single directory |
| `?` | Any single character |
| `[...]` | A character matching the bracket expression |
| `**` | Any number of characters across subdirectories recursively (excluding `.buildignore` directories) |
| `***` | Like `**` but also includes the starting directory itself |

Examples:

```
exe{hello}: cxx{**}          # all .cxx files recursively
exe{hello}: {hxx cxx}{**}    # all headers and sources recursively
./: */                        # all immediate subdirectories
```

Patterns are performed in prerequisite names but not in target names (where
they denote type/pattern-specific variable assignments):

```
./: cxx{*}            # prerequisite name pattern: performed
cxx{*}: dist = false  # target pattern-specific variable: not performed
```

### Inclusions and exclusions

A pattern group may be followed by `+pattern` (include) and `-pattern`
(exclude) values. These are applied in order and only to the result so far.

```
exe{hello}: cxx{f* -foo}             # exclude foo.cxx
exe{hello}: cxx{f* +bar}             # include bar.cxx if present
exe{hello}: cxx{** -***/test/**}     # exclude any test/ subtree
exe{hello}: cxx{** -**-test}         # exclude files ending in -test
exe{hello}: cxx{+{f* b*} -{foo bar}} # explicit inclusion + exclusion group
```

To avoid duplicates when auto-generated files appear in the tree, list the
generated files explicitly and exclude them from the pattern:

```
exe{hello}: {hxx cxx}{* -options} {hxx cxx}{options}
```

### Pattern base directory

Relative patterns are searched in `src_base`. Absolute patterns are searched
in the given absolute directory. Generated names are relative to the base for
relative patterns, or absolute for absolute patterns.

## Attributes

Attributes appear in `[...]` before a target, variable, or prerequisite.

### Target attributes

| Attribute | Description |
|---|---|
| `rule_hint=<hint>` | Resolve ambiguous or override unambiguous rule matching |
| `see_through` | (on a derived group type) Make the group transparent so rules see its members |

Example:

```
[rule_hint=cxx] exe{hello}: c{hello}   # force C++ linker rule
define [see_through] thrift_cxx: group
```

### Variable attributes

| Attribute | Description |
|---|---|
| `<type>` | Assign a static type (e.g. `[string]`, `[bool]`, `[dir_paths]`) |
| `null` | Make the variable nullable |
| `config.report` | Control inclusion/format in the project configuration report |
| `config.report=false` | Exclude from the configuration report |
| `config.report=multiline` | Print list values one element per line |
| `config.report.variable=<var>` | Report a derived variable instead of the raw one |
| `config.report.module=<name>` | Override the module name in the report header |

### Prerequisite-specific variable attributes

The `include` variable controls whether a prerequisite participates in a
given build:

```
lib{hello}: cxx{hello-io}: include = $config.libhello.io
exe{hello}: cxx{hello-linux}: include = ($cxx.target.class == 'linux')
```

The `noinstall` attribute (or the `install` variable set to `false`) prevents
a prerequisite from being installed:

```
hxx{config}: in{config}
{
  install = false
}
```

## See Also

- [build2 manual summary](build2-intro-concepts.md)
