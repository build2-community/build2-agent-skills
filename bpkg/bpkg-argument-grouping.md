# bpkg-argument-grouping -- argument grouping facility

> Help topic. Documents a facility used across multiple bpkg commands, not a
> command itself.

## Synopsis

```
bpkg { <options> }+ <argument> +{ <options> }
```

## Description

For certain commands, options and command line variables can be grouped to
apply only to specific arguments. This topic describes that facility.

Groups can be specified before (leading) and/or after (trailing) the argument
they apply to. A leading group starts with `{` and ends with `}+`. A trailing
group starts with `+{` and ends with `}`. For example:

```
{ --foo --bar }+ arg   # 'arg' with '--foo' '--bar'
arg +{ fox=1 baz=2 }   # 'arg' with 'fox=1' 'baz=2'
```

Multiple leading and/or trailing groups can be specified for the same
argument:

```
{ -f }+ { -b }+ arg +{ f=1 } +{ b=2 }   # 'arg' with '-f' '-b' 'f=1' 'b=2'
```

A group applies to a single argument only, unless multiple arguments are
themselves grouped with `{` and `}`:

```
{ --foo }+ arg1  arg2 +{ --bar }      # 'arg1' with '--foo'
                                      # 'arg2' with '--bar'

{ --foo }+ { arg1  arg2 } +{ --bar }  # 'arg1' with '--foo' '--bar'
                                      # 'arg2' with '--foo' '--bar'
```

The group separators (`{`, `}+`, `+{`, `}`) must be separate command line
arguments. They must not be adjacent to the arguments inside the group or to
the argument they apply to -- such cases are treated as ordinary arguments:

```
{--foo}+ arg   # '{--foo}+' is treated as a plain argument
arg+{ --foo }  # 'arg+{' is treated as a plain argument
```

To pass a group separator verbatim as an argument, escape it with `\`:

```
}             # error: unexpected group separator
}x            # '}x' (ordinary argument, no separator)
\}            # literal '}'
{ \}+ }+ arg  # 'arg' with '}+'
```

## See Also

- [bpkg README](README.md)
- [bpkg-pkg-build](bpkg-pkg-build.md)
