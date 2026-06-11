# bpkg-pkg-disfigure -- disfigure package

## Synopsis

```
bpkg pkg-disfigure [<options>] <pkg>
```

## Description

The `pkg-disfigure` command disfigures the previously configured (via [bpkg-pkg-build](bpkg-pkg-build.md) or [bpkg-pkg-configure](bpkg-pkg-configure.md)) package. A source code package is returned to the `unpacked` state. A system package is removed from the configuration.

By default `pkg-disfigure` will remove the package's build system configuration (`config.build`) and also clean its output directory. This behavior can be suppressed with the `--keep-config` and `--keep-out` options, respectively, for example, if the package is to be reconfigured.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--keep-out` | | Don't clean the package's output directory. |
| `--keep-config` | | Don't remove the package's build system configuration (`config.build`). |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an overview of the default options files. For the `pkg-disfigure` command the search start directory is the configuration directory. The following options files are searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-pkg-disfigure.options
```

The following `pkg-disfigure` command options cannot be specified in the default options files:

```
--directory|-d
```

## See Also

- [bpkg README](README.md)
