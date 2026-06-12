# brep-clean -- clean brep databases

## Synopsis

```
brep-clean --help
brep-clean --version
brep-clean [<options>] builds <buildtab> [<timeout>...]
brep-clean [<options>] tenants <timeout>
```

## Description

`brep-clean` deletes expired records from the brep databases. It operates in
two modes selected by the first positional argument.

Both the `build` and `package` database schemas must already exist before
running `brep-clean`. Use `brep-migrate` to create or migrate them.

### builds mode

```
brep-clean [<options>] builds <buildtab> [<timeout>...]
```

Deletes expired build records from the `build` database. A build record is
considered expired if any of the following is true:

- The corresponding package version is no longer in the `package` database.
- The build configuration is not listed in `<buildtab>`.
- The build age exceeds the timeout specified for its toolchain.

**Timeout format:** `[<name>=]<hours>`

Omit `<name>=` to specify a default timeout that applies to all toolchains
without an explicit override. Specify `0` for `<hours>` to make builds for a
toolchain never expire. Multiple timeout arguments can be provided to set
per-toolchain values.

Example -- 48-hour default, "latest" toolchain never expires:

```
brep-clean builds /etc/brep/buildtab 48 latest=0
```

### tenants mode

```
brep-clean [<options>] tenants <timeout>
```

Deletes or archives tenants from the `package` database whose age exceeds
`<timeout>` hours. With `--archive`, tenants are archived rather than deleted.
Archived tenants remain visible in the web interface but are not rebuilt by
build bots.

Example -- archive tenants older than 7 days:

```
brep-clean --archive tenants 168
```

## Options

| Option | Description |
|--------|-------------|
| `--archive` | Archive expired tenants instead of deleting them (tenants mode only) |
| `--db-name` | Database name; default is `brep_build` for builds mode and `brep_package` for tenants mode |
| `--db-host` | Database host name, address, or socket (default: localhost) |
| `--db-port` | Database port number (default: DBMS default) |
| `--db-user` | Database user name (default: OS login name) |
| `--db-password` | Database password |

## Exit Status

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Fatal error |
| 2 | An instance of `brep-clean` or another `brep` utility is already running; try again |
| 3 | Recoverable database error; try again |

## See Also

- [brep README](README.md)
- [brep-migrate](brep-migrate.md) -- create the database schemas before first use
- [brep-load](brep-load.md) -- populate the package database
