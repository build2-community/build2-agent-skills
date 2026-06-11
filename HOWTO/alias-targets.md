# Alias Targets (PHONY equivalent)

The equivalent of a `PHONY` target in build2 is a target with the `alias{}`
[target type](../guides/build2-targets-variables.md#built-in-target-types).

```
exe{image}: {hxx cxx}{*}

alias{upload}: exe{image}
{{
  diag upload $<
  echo "uploading $path($<)"
}}
```

Invoke it by specifying the target type explicitly (without the type the name
is treated as an operation name):

```
$ b alias{upload}
```

To use a shorter name, define a type alias with `define`:

```
define do: alias

do{upload}: exe{image}
{{
  diag upload $<
  echo "uploading $path($<)"
}}

$ b do{upload}
```

## Operations vs alias targets

Built-in actions like `update`, `test`, and `install` are
[operations](../guides/build2-intro-concepts.md#operations-and-meta-operations),
not targets, which is why they work as `b test: exe{image}`. Adding a new
operation requires a build system module written in C++ and is only warranted
for SDK vendors or similar cases. For project-level scripting,
[bx](../bx/README.md) is the simpler alternative.

## See Also

- [build2 intro concepts](../guides/build2-intro-concepts.md) -- targets, operations, and meta-operations
- [build2 targets and variables](../guides/build2-targets-variables.md) -- target type reference
- [bx README](../bx/README.md) -- task runner for project-level scripting
