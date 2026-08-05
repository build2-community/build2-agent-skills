# brep-load -- load repositories into brep package database

## Synopsis

```
brep-load --help
brep-load --version
brep-load [<options>] <loadtab>
```

## Description

`brep-load` reads the list of repositories from the specified `<loadtab>`
configuration file, fetches their manifest files using `bpkg`, and loads the
repository and package information into the `package` database for consumption
by the `brep` web module.

The `package` database schema must already exist before running `brep-load`.
Use `brep-migrate package` to create or migrate it.

By default, only repositories whose manifest file timestamps have changed since
the last load are reloaded. Use `--force` to reload unconditionally.

Internally, `brep-load` uses `bpkg rep-info` to fetch repository metadata from
each entry in the loadtab. For `cache:` paths it reads the pre-existing
`packages.manifest` directly; it does not regenerate it. If `packages.manifest`
is absent or stale, `brep-load` will fail or return stale data. When using
`brep-submit-git`, the cron job must run `bpkg rep-create` on each section
directory before `brep-load`.

## Loadtab Format

Each non-empty, non-comment line has the form:

```
<remote-url> <display-name> cache:<local-path>
```

- **`<remote-url>`**: The publicly accessible URL of the repository section.
  Used by `brep-load` to derive the section's `interface_url` — the base URL
  prepended to package names when constructing dependency links in the web UI.
  This URL **must include the brep-root path prefix**. If brep is served at
  `/pkg`, write `http://server/pkg/1/stable`, not `http://server/1/stable`.
  Getting this wrong causes `interface_url` to resolve to the server root, so
  all dependency links in the web UI point to the wrong place.

- **`<display-name>`**: Short name shown in the brep web UI (e.g. `stable`).

- **`cache:<local-path>`**: Absolute path to a local directory containing a
  pre-generated `packages.manifest`. `brep-load` reads this file directly and
  does not fetch from `<remote-url>`. The cache must be kept current — run
  `bpkg rep-create` in each section directory before each `brep-load` call.

**Example:**

```
http://example.com/pkg/1/stable   stable   cache:/home/brep/pkg-repo/1/stable
http://example.com/pkg/1/testing  testing  cache:/home/brep/pkg-repo/1/testing
```

### `url:` in repositories.manifest and interface_url

Each section directory's `repositories.manifest` has a `url:` field. `brep-load`
resolves it relative to `<remote-url>` to produce the section's `interface_url`.
The standard value `url: .././..` resolves two levels up from
`<scheme>://<host>/<brep-root>/<version>/<section>` to
`<scheme>://<host>/<brep-root>/`, which is the brep web UI root — the correct
base for dependency links.

Do not set `url:` to an absolute path such as `/pkg/1/stable`. That would make
`interface_url` point inside the section, and dependency links would resolve to
URLs like `http://server/pkg/1/stable/libfoo` instead of
`http://server/pkg/libfoo`.

## Options

### Load behavior

| Option | Description |
|--------|-------------|
| `--force` | Reload package information regardless of manifest file timestamps |
| `--shallow` | Skip prerequisite and complement repositories, do not resolve or check dependency cycles |
| `--ignore-unresolv-tests` | Remove unresolvable test, example, and benchmark entries from package manifests rather than failing |
| `--ignore-unresolv-cond <pkg>` | Ignore unresolvable conditional dependencies; `<pkg>` is `all` (all packages) or `tests` (external test packages only) |
| `--overrides-file <file>` | Apply manifest overrides from `<file>` to all packages being loaded |

### Tenant

| Option | Description |
|--------|-------------|
| `--tenant <id>` | Load into the named tenant instead of single-tenant mode |
| `--existing-tenant` | Load into an already-created empty tenant rather than a newly created one; requires `--tenant` |
| `--private` | Display tenant packages only in tenant view mode, not the global listing |
| `--interactive <bkp>` | Build tenant packages interactively, stopping builds at the named breakpoint; implies `--private` |

### Service integration

| Option | Description |
|--------|-------------|
| `--service-id <id>` | Third-party service ID to associate with the created tenant; requires `--tenant` and `--service-type` |
| `--service-type <type>` | Type of the third-party service; requires `--service-id` |
| `--service-data <data>` | Custom state data to associate with the created tenant; requires `--service-id` |

### Metadata

| Option | Description |
|--------|-------------|
| `--metadata <dir>` | Load package review manifests from `<dir>/<project>/<package>/<version>/`; reloaded whenever package information is reloaded, or when `--metadata-changed` is specified |
| `--metadata-changed` | Update package metadata even if package information was not reloaded |

### Database connection

| Option | Description |
|--------|-------------|
| `--db-name`, `-n` | Package database name (default: `brep_package`) |
| `--db-host`, `-h` | Database host name, address, or socket (default: localhost) |
| `--db-port`, `-p` | Database port number (default: DBMS default) |
| `--db-user`, `-u` | Database user name (default: OS login name) |
| `--db-password` | Database password |

### External programs

| Option | Description |
|--------|-------------|
| `--bpkg <path>` | Path to the `bpkg` executable used for repository fetches (default: `bpkg`) |
| `--bpkg-option <opt>` | Additional option passed to `bpkg`; repeat for multiple options |
| `--openssl <path>` | Path to the `openssl` executable used for crypto operations (default: `openssl`) |
| `--openssl-option <opt>` | Additional option passed to `openssl`; repeat for multiple options |

## Exit Status

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Fatal error |
| 2 | An instance of `brep-load` or another `brep` utility is already running; try again |
| 3 | Recoverable database error; try again |

## See Also

- [brep README](README.md)
- [brep-migrate](brep-migrate.md) -- create the package database schema before first use
- [brep-clean](brep-clean.md) -- remove expired builds and tenants
