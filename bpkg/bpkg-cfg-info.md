# bpkg-cfg-info -- print configuration information

## Synopsis

```
bpkg cfg-info [<options>]
```

## Description

The `cfg-info` command prints the current configuration's absolute path, id,
type, name, and mode. The mode is only printed if specified. If the `--link`
and/or `--backlink` options are specified, then this information is also
printed for each linked and/or implicitly backlinked configuration, if any.
Note that dangling implicit backlinks are silently skipped unless `--dangling`
is specified, in which case this information is also printed for them. Note
that the information is written to `stdout`, not `stderr`.

If the `--recursive` option is specified together with `--link` and/or
`--backlink`, then this information is printed for linked and/or implicitly
backlinked configurations, recursively.

The output format is regular with each value printed on a separate line and
prefixed with the value name. If the `--link`, `--backlink`, and/or
`--dangling` options are specified, then information blocks corresponding to
linked configurations are separated with blank lines. For example:

```
path: /path/to/cfg/
uuid: 8d439f03-7342-4502-8b1c-74b173869478
type: target
name: foo
mode: fetch-cache=false

path: /path/to/host-cfg/
uuid: 7ee4dab3-07d9-4163-81c0-3779166a7213
type: host
name: tools

path: /path/to/build2-cfg/
uuid: d453aa2a-92c4-4066-87e4-c8672eed06e1
type: build2
name: modules
```

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|--------|-----|-------------|
| `--link` | | Print linked configurations. |
| `--backlink` | | Print implicitly backlinked configurations. |
| `--dangling` | | Print dangling implicit backlinks. |
| `--recursive` | | Print linked configurations recursively. |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an
overview of the default options files. For the `cfg-info` command the search
start directory is the configuration directory. The following options files
are searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-cfg-info.options
```

The following `cfg-info` command options cannot be specified in the default
options files:

```
--directory|-d
```

## See Also

- [bpkg SUMMARY](SUMMARY.md)
- [bpkg-cfg-create](bpkg-cfg-create.md)
- [bpkg-cfg-link](bpkg-cfg-link.md)
- [bpkg-cfg-unlink](bpkg-cfg-unlink.md)
