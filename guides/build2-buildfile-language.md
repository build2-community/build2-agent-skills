# build2 Buildfile Language Reference

_Use for: buildfile language syntax including name patterns, dependency
chains, directives, conditions (if/elif/else), pattern matching (switch/case),
loops, eval contexts, quoting, and out-of-source build configuration._

## When to use

- You need the syntax for a specific buildfile construct (if, switch, for,
  import, etc.).
- You are setting up out-of-source builds, forwarded configurations, or
  build configuration amalgamations.
- You have a complete minimal project example to follow.
- You need `b` invocation patterns for common operations.

---

## Minimal working example

Complete standard-layout `hello` project:

```
hello/
+-- build/
|   +-- bootstrap.build
|   +-- root.build
+-- hello/
|   +-- hello.cxx
|   +-- buildfile
+-- buildfile
+-- manifest
```

**`build/bootstrap.build`:**

```
project = hello

using version
using config
using test
using install
using dist
```

**`build/root.build`:**

```
cxx.std = latest

using cxx

hxx{*}: extension = hxx
cxx{*}: extension = cxx
```

**`buildfile` (root):**

```
./: {*/ -build/} manifest
```

**`hello/buildfile`:**

```
exe{hello}: {hxx cxx}{**}

cxx.poptions =+ "-I$out_root" "-I$src_root"
```

**`manifest`:**

```
: 1
name: hello
version: 0.1.0
summary: hello C++ executable
```

**`hello/hello.cxx`:**

```cpp
#include <iostream>

int main ()
{
  std::cout << "Hello, World!" << std::endl;
}
```

---

## How to build -- invoking `b`

`b` is the build system driver. The command-line argument is a **buildspec**:
a list of `[meta-op '('] [op ':'] target [')']` entries.

### Basic invocations

```
b                          # Update default target in current directory
b ./                       # Same
b update                   # Same
b update: ./               # Same

b clean                    # Clean current directory
b clean update             # Rebuild

b hello/                   # Build specific directory
b hello/exe{hello}         # Build specific target
b hello/ libhello/         # Build multiple targets
```

### Specifying configuration on the command line

```
b config.cxx=clang++
b config.cxx=clang++ config.cxx.coptions=-g
b config.cxx.coptions=-O3
```

### Persistent configuration

```
b configure config.cxx=clang++ config.cxx.coptions=-g
b                              # Uses saved configuration
b disfigure                    # Remove saved configuration
```

The configuration is saved to `build/config.build`. This file is a buildfile
with variable assignments and can be edited directly.

To reset a single configuration variable to its default:

```
b configure config.config.disfigure=config.cxx
```

### Out of source builds

Syntax: `src/@out/` specifies source and output directories:

```
b hello/@hello-out/                         # Out of source build
b hello/@hello-gcc/    config.cxx=g++
b hello/@hello-clang/  config.cxx=clang++
```

Configure out of source:

```
b configure: hello/@hello-gcc/   config.cxx=g++
b configure: hello/@hello-clang/ config.cxx=clang++

b hello-gcc/      # Build using saved configuration
b hello-clang/
```

#### Forwarded configurations

A source directory can forward to an out-of-source build. When the build
system is invoked from the source directory it builds in the forwarded output
directory and backlinks interesting targets (`exe{}`, `doc{}`) back to the
source directory via symlinks.

```
b configure: hello/@hello-gcc/,forward

cd hello/
b                # Builds in ../hello-gcc/ and symlinks the executable here
```

### Build configurations (shared, amalgamated)

Build configurations are projects that house other projects as subprojects,
giving them a shared compiler/linker configuration and automatic import
resolution.

```
b create: build-gcc/,cc   config.cxx=g++
b create: build-clang/,cc config.cxx=clang++

b configure: libhello/@build-gcc/libhello/
b configure: hello/@build-gcc/hello/

b configure: libhello/@build-clang/libhello/
b configure: hello/@build-clang/hello/

b build-gcc/hello/         # Build hello in GCC configuration
b build-clang/             # Build everything in Clang configuration
```

Subprojects inherit the configuration of their amalgamation.

### Verbosity

```
b -v          # Show actual compiler/linker command lines (verbosity 2)
b -V          # Show all actual commands (verbosity 3)
b --verbose 4 # Trace rule matching and out-of-date determination
b -s          # Serial, stop at first error (useful for debugging)
```

---

## Buildfile language reference

### Name patterns

```
{hxx cxx}{*}     # All .hxx and .cxx files in current directory
{hxx cxx}{**}    # Recursive
{hxx cxx}{** -version}   # Exclude version.*
-**.test...      # Exclude files with .test second-level extension
```

### Dependency declaration chains

```
./: exe{hello}: cxx{hello}     # Chain: default target -> exe -> source
```

### Directives

```
using cxx                       # Load module
include hello/buildfile         # Include buildfile
include hello/                  # Same (buildfile implied)
import libs = libhello%lib{hello}  # Import from another project
info $src_root                  # Print value (to stderr with location)
text 'message'                  # Print without info: prefix
warn 'warning message'
fail 'error and exit'
assert ($x != [null]) 'msg'
print "$cxx.id $cxx.target"    # Print to stdout
dump                            # Dump current scope state to stderr
dump exe{hello}                 # Dump specific target
```

### Conditions

```
if ($cxx.target.class == 'linux')
  ...
elif ($cxx.target.class == 'windows')
{
  ...
}
else
  ...

if! $version.pre_release
  ...

ifn $foo    # if $null($foo)
ife $bar    # if $empty($bar)
```

### Pattern matching

```
switch $cxx.target.class, $cxx.target.system
{
  case 'linux'
    info 'linux'

  case 'windows', 'mingw32'
    info 'windows-mingw'

  case 'windows'
    info 'windows-other'

  default
    info 'other'
}

switch $cxx.id
{
  case 'clang' | 'clang-apple'
    ...
}

switch $cxx.target.cpu: regex.match
{
  case 'i[3-6]86'
    ...
  case 'x86_64'
    ...
}
```

### Loops

```
for n: foo bar baz
{
  exe{$n}: cxx{$n}
}

i = [uint64] 0
while ($i != 10)
{
  ...
  i += 1
}

for n: foo bar baz
{
  if (...)
    continue
  if (...)
    break
  ...
}
```

### Eval contexts and function calls

```
info ($src_root != $out_root)
info ($src_root == $out_root ? 'in' : 'out')

macos = ($cxx.target.class == 'macos')
if ($macos || $linux)
  ...

info $empty($x)
info $regex.match($y, '[A-Z]')
info $path.leaf($src_base)
```

### Quoting and escaping

```
x = \$                         # Literal dollar sign
y = 'C:\Program Files'         # Single quote: no expansion
z = "C:\\Program Files"        # Double quote: expansion performed

cxx.poptions =+ "-I$out_root" "-I$src_root"   # Untyped concat (required for -I)
```

## See Also

- [`build2-intro-concepts.md`](build2-intro-concepts.md) -- targets, scopes, modules, variables, operations
- [`build2-projects-advanced.md`](build2-projects-advanced.md) -- target importation, library projects, subprojects
- [`build2-targets-variables.md`](build2-targets-variables.md) -- complete target type and variable reference
- [`b/README.md`](../b/README.md) -- b driver overview
- [`b/b.md`](../b/b.md) -- full b option reference
- [`HOWTO/buildfile-compile-options.md`](../HOWTO/buildfile-compile-options.md) -- which compile options belong in a buildfile
- [`HOWTO/config-independent-build-graph.md`](../HOWTO/config-independent-build-graph.md) -- keeping the build graph configuration-independent
