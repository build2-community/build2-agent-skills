# bpkg-rep-info -- print repository information

## Synopsis

```
bpkg rep-info [<options>] <rep-loc>
```

## Description

The `rep-info` command prints various information about the specified repository. By default it prints the repository's name and location as the first line. If the repository is signed, the certificate information (name/organization/email) is printed as the next line followed by the certificate fingerprint. Then comes the list of complement and prerequisite repositories followed by the list of available packages.

This default format can be altered in various ways using the options listed below. Note also that the information is written to `stdout`, not `stderr`.

If the current working directory contains a `bpkg` configuration, then `rep-info` will use its certificate database for the repository authentication. That is, it will trust the repository's certificate if it is already trusted by the configuration. Otherwise it will add the certificate to the configuration if you confirm it is trusted. You can specify an alternative configuration directory with the `--directory|-d` option. To disable using the configuration in the current working directory pass this option with an empty path.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|--------|-----|-------------|
| `--name`, `-n` | | Print the repository's name and location. |
| `--cert-fingerprint` | | Print the repository's certificate fingerprint or empty line if the repository is unsigned. |
| `--cert-name` | | Print the repository's certificate common name (CN) or empty line if the repository is unsigned. |
| `--cert-organization` | | Print the repository's certificate organization name (O) or empty line if the repository is unsigned. |
| `--cert-email` | | Print the repository's certificate email or empty line if the repository is unsigned. |
| `--repositories`, `-r` | | Print the list of complement and prerequisite repositories. |
| `--packages`, `-p` | | Print the list of available packages. |
| `--manifest` | | Instead of printing the information in human-readable form, dump it (to `stdout`) as manifest(s). Normally you would use this option in combination with `--packages|-p` or `--repositories|-r` to only dump one of the manifests. If `--deep` is specified, then in the resulting packages manifest the `*-file` values are replaced with the contents of the referenced files and the `*-build` values are automatically added (unless the corresponding files are absent). See also `--ignore-unknown`, `--repositories-file`, and `--packages-file`. |
| `--ignore-unknown` | | Ignore unknown manifest entries. Note that this option also ignores the version constraints in the special toolchain build-time dependencies. This option is implied if `--manifest` is not specified. |
| `--deep` | | Verify the presence of the required `*-build` values/files and the validity of files referenced by the `*-file` manifest values. |
| `--repositories-file` | `<path>` | If `--manifest` is specified, then save the repositories manifest to the specified file instead of dumping it to `stdout`. |
| `--packages-file` | `<path>` | If `--manifest` is specified, then save the packages manifest to the specified file instead of dumping it to `stdout`. |
| `--type` | `<type>` | Specify the repository type with valid values being `pkg`, `dir`, and `git`. Refer to [bpkg-rep-add](bpkg-rep-add.md) for details. |
| `--directory`, `-d` | `<dir>` | Use configuration in _dir_ for the trusted certificate database. |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an overview of the default options files. If the `rep-info` command uses an existing `bpkg` configuration, then the start directory is the configuration directory. Otherwise, only the predefined directories (home, system, etc) are searched. The following options files are searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-rep-info.options
```

The following `rep-info` command options cannot be specified in the default options files:

```
--directory|-d
```

## See Also

- [bpkg SUMMARY](SUMMARY.md)
