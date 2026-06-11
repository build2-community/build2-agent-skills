# bpkg-pkg-configure -- configure package

## Synopsis

```
bpkg pkg-configure [<options>] [<cfg-var>...] <pkg>
```

## Description

The `pkg-configure` command configures either the previously unpacked ([bpkg-pkg-unpack](bpkg-pkg-unpack.md), [bpkg-pkg-checkout](bpkg-pkg-checkout.md)) source code package or a package that is present in the system.

A source code package inherits the common `build2` configuration values that were specified when creating the configuration ([bpkg-cfg-create](bpkg-cfg-create.md)). Additional package-specific configuration variables can be passed to `pkg-configure` (_cfg-var_).

A system package is specified using the `sys:<pkg>[/<ver>]` syntax. If the package version (_ver_) is not specified, then it is considered to be unknown but satisfying any dependency constraint. Such a version is displayed as `*`.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|---|---|---|

No command-specific options beyond the common options.

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an overview of the default options files. For the `pkg-configure` command the search start directory is the configuration directory. The following options files are searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-pkg-configure.options
```

The following `pkg-configure` command options cannot be specified in the default options files:

```
--directory|-d
```

## See Also

- [bpkg README](README.md)
