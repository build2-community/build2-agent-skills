# bpkg-rep-create -- create repository

## Synopsis

```
bpkg rep-create [<options>] [<dir>]
```

## Description

The `rep-create` command regenerates the `packages.manifest` and `signature.manifest` files based on the files present in the repository directory. If the `repositories.manifest` file contains a certificate, then the `--key` option must be used to specify the certificate's private key. If _dir_ is not specified, then the current working directory is used as the repository root.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|--------|-----|-------------|
| `--ignore-unknown` | | Ignore unknown manifest entries. Note that this option also ignores the version constraints in the special toolchain build-time dependencies. |
| `--min-bpkg-version` | `<ver>` | Apply backward compatibility workarounds to the generated `packages.manifest` file so that it can be consumed by `bpkg` versions greater or equal to the specified version. If unspecified, then the `min-bpkg-version` value from the `repositories.manifest` file is used, if present. If the manifest value is not specified either, then no backward compatibility workarounds are applied. |
| `--key` | `<name>` | Private key to use to sign the repository. In most cases _name_ will be a path to the key file but it can also be a key id when a custom `openssl` cryptographic engine is used. |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an overview of the default options files. For the `rep-create` command the search start directory is the repository directory. The following options files are searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-rep-create.options
```

The following `rep-create` command options cannot be specified in the remote default options files:

```
--key
```

## See Also

- [bpkg SUMMARY](SUMMARY.md)
