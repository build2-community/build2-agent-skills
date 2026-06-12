# brep -- Repository Interface

_Use for: hosting build2 package repositories, loading repository metadata,
cleaning expired builds and tenants, migrating database schemas, monitoring
build infrastructure, and understanding the package submission, CI request, and
build artifact upload protocols._

## Overview

`brep` is the `build2` package repository web interface. It is deployed as an
Apache httpd module that serves repository data over HTTP, displaying packages,
versions, and build results. The module reads from two PostgreSQL databases:
the **package** database (repository and package metadata) and the **build**
database (build results from automated build bots).

Four command-line utilities manage these databases and the surrounding
infrastructure:

- `brep-load` -- fetches repository manifests and loads them into the package
  database.
- `brep-clean` -- removes expired build records from the build database and
  expires or archives tenant records from the package database.
- `brep-migrate` -- creates, migrates, or drops the database schemas.
- `brep-monitor` -- detects delayed package builds and reports them to
  `stderr`.

The web module also handles inbound HTTP requests for package submission, CI
requests, and binary distribution artifact uploads. For each request type a
configurable **handler program** implements the repository's acceptance policy.
See [brep-request-handling](brep-request-handling.md) for the full protocol
specification.

---

## Key Concepts

**Package database.** A PostgreSQL database (default name `brep_package`) that
stores repository manifests, package metadata, and tenant state. Populated by
`brep-load`, managed by `brep-migrate` and `brep-clean`.

**Build database.** A PostgreSQL database (default name `brep_build`) that
stores build bot results, build configurations, and monitor state. Managed by
`brep-migrate` and `brep-clean`.

**Tenant.** An isolated namespace within the package database that groups
repositories and packages together. `brep-load --tenant` selects which tenant
to load into. Without `--tenant`, single-tenant mode is assumed. Tenants can
be archived (`brep-clean --archive`) to stop new builds while keeping packages
visible.

**loadtab.** A configuration file consumed by `brep-load` that lists the
repositories to fetch. `brep-load` uses `bpkg` internally to fetch repository
metadata from each listed repository.

**Handler program.** An executable invoked by the brep web module when a
package submission, CI request, or build artifact upload arrives. The handler
receives the path to a request directory containing uploaded content and a
`request.manifest`, writes a result manifest to `stdout`, and must exit zero.

---

## Command Reference

| Command | Description |
|---------|-------------|
| `brep-load` | Fetch repository manifests and load package metadata into the package database |
| `brep-clean` | Delete expired build records or expire/archive tenants |
| `brep-migrate` | Create, migrate, or drop the `package` or `build` database schema |
| `brep-monitor` | Analyze build delays and report infrastructure issues to `stderr` |

All utilities share the same exit codes: 0 success, 1 fatal error, 2 already
running (retry), 3 recoverable database error (retry).

---

## Typical Workflows

### Initial setup

Create both database schemas before first use:

```
brep-migrate package
brep-migrate build
```

### Load repositories

Create a `loadtab` file listing the repositories to serve, then run:

```
brep-load /etc/brep/loadtab
```

Schedule periodic reloads to keep the package database current:

```
# crontab: reload every 10 minutes
*/10 * * * * brep-load /etc/brep/loadtab
```

### Expire old builds

```
# Delete builds older than 48 hours; toolchain named "latest" never expires
brep-clean builds /etc/brep/buildtab 48 latest=0
```

### Archive old CI tenants

```
# Archive tenants older than 168 hours (7 days)
brep-clean tenants 168
```

### Monitor for build delays

```
# Report delays for build2 0.17.x; suppress repeats for 24 h
brep-monitor --report-timeout 86400 /etc/brep/brep.conf build2/0.17
```

---

## Navigation

### Per-command reference

- [brep-load](brep-load.md) -- load repositories into the package database
- [brep-clean](brep-clean.md) -- expire or archive builds and tenants
- [brep-migrate](brep-migrate.md) -- create, migrate, or drop database schemas
- [brep-monitor](brep-monitor.md) -- report delayed package builds

### Protocol reference

- [brep-request-handling](brep-request-handling.md) -- package submission, CI
  request, build artifact upload, and GitHub CI integration protocols

## See Also

- [bpkg reference](../bpkg/README.md) -- `bpkg` is used internally by `brep-load`
- [bdep-ci](../bdep/bdep-ci.md) -- submit a CI request from a project
- [bdep-publish](../bdep/bdep-publish.md) -- publish a package via the submission protocol
