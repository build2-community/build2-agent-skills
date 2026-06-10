# bpkg-cfg-link -- link configuration

## Synopsis

```
bpkg cfg-link [<options>] <dir>
```

## Description

The `cfg-link` command links the specified `bpkg` configuration with the
current configuration. It also establishes an implicit backlink from the
specified to the current configuration. See [bpkg-cfg-create](bpkg-cfg-create.md)
for background on linked configurations. To unlink previously linked
configurations use [bpkg-cfg-unlink](bpkg-cfg-unlink.md).

The linked configurations are normally referred to using names when specified
on the `bpkg` command line. Unless overridden with the `--name` option, the
original configuration name is used to name the link. If the link is unnamed,
then it can be referred to using the numeric id that is automatically assigned
when establishing the link or using the configuration UUID.

If the specified configuration path is relative, then it is rebased relative
to the current configuration directory. This way, when the linked
configurations are moved around together, the stored relative paths remain
valid. If the specified directory path is absolute, then it is stored as
absolute unless the `--relative` option is specified, in which case it is also
rebased relative to the current configuration directory.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|--------|-----|-------------|
| `--name` | `<name>` | Alternative link name. If this option is not specified, then the configuration name is used as the link name (see [bpkg-cfg-create](bpkg-cfg-create.md) for details). |
| `--relative` | | Rebase the absolute linked configuration path relative to the current configuration directory. |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an
overview of the default options files. For the `cfg-link` command the search
start directory is the configuration directory. The following options files
are searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-cfg-link.options
```

The following `cfg-link` command options cannot be specified in the default
options files:

```
--directory|-d
```

## See Also

- [bpkg SUMMARY](SUMMARY.md)
- [bpkg-cfg-create](bpkg-cfg-create.md)
- [bpkg-cfg-info](bpkg-cfg-info.md)
- [bpkg-cfg-unlink](bpkg-cfg-unlink.md)
