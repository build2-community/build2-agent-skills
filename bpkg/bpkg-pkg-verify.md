# bpkg-pkg-verify -- verify package archive

## Synopsis

```
bpkg pkg-verify [<options>] <file>
```

## Description

The `pkg-verify` command verifies that the specified archive file is a valid
`bpkg` package. Specifically, it checks that the file's name and the top-level
directory inside the archive match the canonical _name_**-**_version_ form and
that there is a valid manifest file in that top-level directory. Additionally,
if the `--deep` option is specified, it also checks that the required `*-build`
values/files are present in the manifest/archive and the files referenced by the
`*-file` manifest values are present in the archive and are not empty.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--silent` | | Suppress the error messages about the reason why the package is invalid. Just return the error status. |
| `--deep` | | Verify the presence of the required `*-build` values/files and the validity of files referenced by the `*-file` manifest values. |
| `--ignore-unknown` | | Ignore unknown manifest entries. By default, `bpkg` will refuse to declare such a package valid since it cannot be sure the unknown entries are valid. Note that this option also ignores the version constraints in the special toolchain build-time dependencies. |
| `--manifest` | | Instead of printing the successful verification result in the human-readable form, dump the package manifest to `stdout`. If the `--deep` option is specified, then in the resulting manifest the `*-file` values are replaced with the contents of the referenced files, the `*-build` values are automatically added (unless the corresponding files are absent), and the package dependency constraints are completed. |

## Default Options Files

See `bpkg-default-options-files` for an overview of the default options files.
For the `pkg-verify` command the following options files are searched for in the
predefined directories (system, etc) and, if found, loaded in the order listed:

```
bpkg.options
bpkg-pkg-verify.options
```

## See Also

- [bpkg SUMMARY](SUMMARY.md)
