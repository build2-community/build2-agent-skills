# brep-monitor -- monitor brep infrastructure

## Synopsis

```
brep-monitor --help
brep-monitor --version
brep-monitor [<options>] <brep-config> <toolchain> [<toolchain>...]
```

```
<toolchain> = <name>[/<version>]
```

## Description

`brep-monitor` analyzes the `brep` internal state and reports infrastructure
issues by printing their descriptions to `stderr`. Currently, only delayed
package builds are detected and reported.

The brep module configuration file `<brep-config>` is used to locate the
`build` database and to derive the expected rebuild timeouts. Most of this
information can be overridden via command-line options.

One or more `<toolchain>` arguments specify which toolchains to monitor.
Omitting `/<version>` causes all versions of the named toolchain to be
considered.

`brep-monitor` maintains its own state in the `build` database. It records
timestamps of reported delays and uses `--report-timeout` to suppress repeated
reports for the same delay. If `--report-timeout` is not specified, timestamps
are not updated and all delays are reported on every run. To force reporting
all delays and still update the timestamps, specify `--report-timeout 0`.

By default, a brief summary (delay counts per build configuration) is printed.
Use `--full-report` to print the individual delayed builds.

The `build` database schema must already exist before running `brep-monitor`.
Use `brep-migrate build` to create or migrate it.

## Options

### Timing

| Option | Description |
|--------|-------------|
| `--soft-rebuild-timeout <sec>` | Time in seconds before a soft (re)build is considered delayed. If unspecified, derived from the `build-soft-rebuild-timeout`, `build-alt-soft-rebuild-*`, and `build-result-timeout` brep module configuration options. Set to `0` to disable soft-rebuild monitoring. |
| `--hard-rebuild-timeout <sec>` | Time in seconds before a hard (re)build is considered delayed. If unspecified, derived from the `build-hard-rebuild-timeout` and `build-alt-hard-rebuild-*` configuration options. |
| `--report-timeout <sec>` | Suppress re-reporting a delay for this many seconds after it was first reported. If unspecified, all delays are reported on every run without updating timestamps. Specify `0` to report all delays and still update timestamps. |

### Reporting

| Option | Description |
|--------|-------------|
| `--full-report` | Print individual delayed builds rather than just counts per build configuration |
| `--clean` | Remove stale monitor state for packages, configurations, and toolchains that no longer exist |

### Database connection

| Option | Description |
|--------|-------------|
| `--build-db-name`, `-n` | Build database name (default: value from `<brep-config>`) |
| `--build-db-host`, `-h` | Build database host name, address, or socket |
| `--build-db-port`, `-p` | Build database port number |
| `--build-db-user`, `-u` | Build database user name (default: OS login name) |
| `--build-db-password` | Build database password |

## Notes

A package that was never built before being archived is always considered
delayed. However, to distinguish this from a package archived before a
configuration was added, `brep-monitor` must have observed the package as
buildable before it was archived. If running `brep-monitor` as a cron job,
ensure the running period is shorter than the tenant archive timeout.

If both soft and hard rebuilds are disabled in the brep module configuration,
`brep-monitor` cannot derive a reasonable timeout automatically. In this case,
specify `--soft-rebuild-timeout` or `--hard-rebuild-timeout` explicitly to
monitor initial build delays.

## Exit Status

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Fatal error |
| 2 | An instance of `brep-monitor` or another `brep` utility is already running; try again |
| 3 | Recoverable database error; try again |

## See Also

- [brep README](README.md)
- [brep-migrate](brep-migrate.md) -- create the build database schema before first use
- [brep-clean](brep-clean.md) -- remove expired build records
