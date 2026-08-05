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

Several command-line utilities manage these databases and the surrounding
infrastructure:

- `brep-load` -- fetches repository manifests and loads them into the package
  database.
- `brep-clean` -- removes expired build records from the build database and
  expires or archives tenant records from the package database.
- `brep-migrate` -- creates, migrates, or drops the database schemas.
- `brep-monitor` -- detects delayed package builds and reports them to
  `stderr`.
- `brep-upload-bindist-clean` -- removes expired binary distribution upload
  directories; only needed when `brep-upload-bindist` is the configured upload
  handler.

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
repositories to serve. Each line has the form
`<remote-url> <display-name> cache:<local-path>`. The remote URL must include
the brep-root path prefix (e.g. `http://example.com/pkg/1/stable`, not
`http://example.com/1/stable`) — it is used to derive each section's
`interface_url` for dependency links in the web UI. See
[brep-load](brep-load.md) for the full format and `interface_url` mechanics.

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
| `brep-upload-bindist-clean` | Remove expired binary distribution upload directories (only when `brep-upload-bindist` is in use) |

The C++ utilities (`brep-load`, `brep-clean`, `brep-migrate`, `brep-monitor`) share the same exit codes: 0 success, 1 fatal error, 2 already running (retry), 3 recoverable database error (retry). `brep-upload-bindist-clean` is a shell script; it exits 0 on success and 1 on error.

---

## Typical Workflows

### Initial setup

Create both database schemas before first use:

```
brep-migrate package
brep-migrate build
```

### Serve repository files at `/pkg/1/...`

The brep web module rejects URL paths whose first segment after the brep-root is
all digits (e.g. `/pkg/1/stable`). These paths are repository section URLs used
by `bpkg add` and must be served directly from the filesystem by Apache. Without
this, both `bpkg add http://example.com/pkg/1/stable` and browser navigation to
those paths return 404.

Add the following directives **inside** the `<VirtualHost>` block, **after** the
`<Location "/pkg">` section injected by `brep-apache2.conf`. The `<LocationMatch>`
must come after `<Location "/pkg">` — a separate conf file loaded before the
VirtualHost will not override `SetHandler brep`. `DirectorySlash On` overrides
brep's `DirectorySlash Off` so that directory requests without a trailing slash
redirect correctly; without it, Apache generates autoindex links relative to the
wrong parent, producing broken URLs.

```apache
<LocationMatch "^/pkg/[0-9]+(/.*)?$">
  SetHandler None
  DirectorySlash On
</LocationMatch>

AliasMatch ^/pkg/([0-9]+)/(.+)$ /path/to/pkg-repo/$1/$2

<Directory "/path/to/pkg-repo">
  Require all granted
  Options Indexes
</Directory>
```

### Load repositories

Create a `loadtab` file listing the repositories to serve, then run:

```
brep-load /etc/brep/loadtab
```

Schedule periodic reloads to keep the package database current:

```
# crontab: reload every 5 minutes
*/5 * * * * brep-load /etc/brep/loadtab
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

### Scheduling jobs with cron

Stagger the minute offsets so that jobs do not pile up at midnight or on any
`*/5` boundary that coincides with another job:

```
# crontab entries (all times shifted a few minutes apart)
*/5 * * * *  brep-load /etc/brep/loadtab
  1 0 * * *  brep-clean tenants 240
  2 0 * * *  brep-clean builds /etc/brep/buildtab
  3 0 * * *  brep-upload-bindist-clean /var/bindist 2880
  4 * * * *  brep-monitor --report-timeout 86400 --clean /etc/brep/brep-module.conf public
```

The `*/5` loader fires at :00, :05, :10, ...; the daily cleaner jobs run at
00:01 and 00:02; the bindist cleaner at 00:03; and the monitor runs once per
hour at :04.

---

## Navigation

### Per-command reference

- [brep-load](brep-load.md) -- load repositories into the package database
- [brep-clean](brep-clean.md) -- expire or archive builds and tenants
- [brep-migrate](brep-migrate.md) -- create, migrate, or drop database schemas
- [brep-monitor](brep-monitor.md) -- report delayed package builds
- [brep-upload-bindist-clean](brep-upload-bindist-clean.md) -- remove expired binary distribution upload directories

### Protocol reference

- [brep-request-handling](brep-request-handling.md) -- package submission, CI
  request, build artifact upload, and GitHub CI integration protocols

## See Also

- [bpkg reference](../bpkg/README.md) -- `bpkg` is used internally by `brep-load`
- [bdep-ci](../bdep/bdep-ci.md) -- submit a CI request from a project
- [bdep-publish](../bdep/bdep-publish.md) -- publish a package via the submission protocol
