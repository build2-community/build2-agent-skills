# brep-migrate -- create/drop/migrate brep databases

## Synopsis

```
brep-migrate --help
brep-migrate --version
brep-migrate [<options>] (package | build)
```

## Description

`brep-migrate` manages the database schema for the `brep` web module. It
operates on one of two named schemas: `package` (the `brep_package` database)
or `build` (the `brep_build` database).

In its default mode, `brep-migrate` creates the database schema if it does not
yet exist. If the schema already exists but is at an older version, it migrates
the schema and data to the current version.

Run `brep-migrate package` and `brep-migrate build` before first use, and
again after upgrading the `brep` installation to pick up any schema changes.

**Destructive options.** `--recreate` drops all tables and recreates them from
scratch (all data is lost). `--drop` drops all tables without recreating them.
Both options fail if the existing schema requires migration; in that case,
either migrate first (default mode) or use `psql` to drop the database
entirely.

`--recreate` and `--drop` are mutually exclusive.

## Options

### Schema control

| Option | Description |
|--------|-------------|
| `--recreate` | Drop all tables and recreate from scratch; all data is lost |
| `--drop` | Drop all tables without recreating; all data is lost |

### Database connection

| Option | Description |
|--------|-------------|
| `--db-name`, `-n` | Database name (default: `brep_package` or `brep_build` derived from the schema name) |
| `--db-host`, `-h` | Database host name, address, or socket (default: localhost) |
| `--db-port`, `-p` | Database port number (default: DBMS default) |
| `--db-user`, `-u` | Database user name (default: OS login name) |
| `--db-password` | Database password |

## Exit Status

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Fatal error |
| 2 | An instance of `brep-migrate` or another `brep` utility is already running; try again |
| 3 | Recoverable database error; try again |

## See Also

- [brep README](README.md)
- [brep-load](brep-load.md) -- populate the package database after schema creation
- [brep-clean](brep-clean.md) -- expire build records and tenants
