# Config-Independent Build Graph

The [build graph](../guides/build2-intro-concepts.md#the-build-graph)
(all target-prerequisite relationships) must be configuration-independent:
it must not vary by compiler, platform, or project configuration. The `dist`
module relies on this to produce identical source distributions regardless of
the active configuration.

The warning that signals a violation:

```
buildfile:32:3: warning: conditional dependency declaration may result in incomplete distribution
  info: instead use 'include' prerequisite-specific variable to conditionally include prerequisites
```

## The fix: use include = (condition)

Instead of guarding dependency declarations with `if`, use the
[`include` prerequisite-specific variable](../guides/build2-targets-variables.md#prerequisite-specific-variable-attributes).
All targets remain in the graph; `include` controls whether they participate
in the build for a given configuration. Note that this keeps the prerequisite
in the dist archive -- `include = (condition)` fixes *incomplete*
distribution, it is not a way to *exclude* something from distribution. To
actually drop a file from the archive, see
[exclude-test-data-from-dist.md](./exclude-test-data-from-dist.md):

```
# Wrong: produces different graphs on different platforms.
if ($cxx.target.class != 'windows')
  exe{hello}: cxx{utility-posix}
else
  exe{hello}: cxx{utility-win32}

# Correct: single graph, conditional participation.
exe{hello}: cxx{utility-posix}: include = ($cxx.target.class != 'windows')
exe{hello}: cxx{utility-win32}: include = ($cxx.target.class == 'windows')
```

## Platform-specific test

```
./: exe{test-file}: cxx{test-file} $libs

./: exe{test-pipe}: include = ($cxx.target.class != 'windows')
exe{test-pipe}: cxx{test-pipe} $libs
```

## Conditional ad hoc recipes

When a recipe should only run in certain configurations, keep the
target-prerequisite declaration unconditional but wrap the recipe body in an
`if`. An explicit `%` recipe header is required for a conditional recipe block:

```
exe{reflex}: c{scan}:     include = ( $config.reflex.develop)
exe{reflex}: c{initscan}: include = (!$config.reflex.develop)

exe{reflex-boot}: $src c{initscan}
{
  install = false
}

c{scan}: l{scan} exe{reflex-boot}
%
if $config.reflex.develop
{{
  diag lex ($<[0])
  ($<[1]) -L -o $path($>) $path($<[0])
}}
```

Omitting the recipe body in non-applicable configurations matters when the
recipe references variables (like an imported executable) that only exist in
those configurations. The same applies to ad hoc rules.

If a prerequisite (e.g., an imported tool) is only declared under an `if`,
the recipe that uses it must also be conditional:

```
if $config.hello.develop
  import lex = reflex%exe{reflex}

exe{hello}: c{scan}:     include = ( $config.hello.develop)
exe{hello}: c{initscan}: include = (!$config.hello.develop)

c{scan}: l{scan} $lex
%
if $config.hello.develop
{{
  $lex -o $path($>) $path($<[0])
}}
```

## See Also

- [build2 buildfile language](../guides/build2-buildfile-language.md) -- conditional and loop directives
- [build2 directives, name patterns, attributes](../guides/build2-directives-patterns.md)
- [build2 core modules: config](../guides/build2-modules-core.md)
- [exclude-test-data-from-dist.md](./exclude-test-data-from-dist.md): actually excluding a file from the `b dist` archive
