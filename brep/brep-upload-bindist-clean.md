# brep-upload-bindist-clean -- clean expired binary distribution upload directories

## Synopsis

```
brep-upload-bindist-clean <root> <timeout>
```

## Description

`brep-upload-bindist-clean` removes expired package configuration directories
under `<root>` that were created by the `brep-upload-bindist` upload handler.

`<timeout>` is the expiry threshold in **minutes**. A directory is considered
expired when the `packages.sha256` file it contains has a modification time
older than `<timeout>` minutes ago. Directories without a `packages.sha256`
file are still being prepared and are skipped.

For each expired directory the script:

1. Locks the root directory (via `upload.lock`).
2. Re-checks the expiry criteria under the lock.
3. Removes the symlink pointing to the directory if it exists and still
   points here.
4. Removes the directory itself (`rm -rf`).
5. Removes any parent directories that become empty, up to but not including
   `<root>`.
6. Releases the lock.

`brep-upload-bindist-clean` is a shell script. It exits 0 on success and 1
on any error. It does not emit the lock-contention (2) or database-error (3)
codes used by the C++ brep utilities.

## Arguments

| Argument | Description |
|----------|-------------|
| `<root>` | Root directory containing binary distribution upload directories managed by `brep-upload-bindist`. Must exist and be readable and writable by the invoking user. |
| `<timeout>` | Expiry threshold in **minutes**. Directories whose `packages.sha256` modification time is older than this are removed. |

## Prerequisites

The `<root>` directory must have read, write, and execute permissions for the
`brep` user. When `www-data` owns the directory (the common case when the
upload handler runs as Apache), grant access with ACLs:

```
# mkdir /var/bindist
# chown www-data:www-data /var/bindist
# setfacl -m  u:brep:rwx /var/bindist
# setfacl -dm u:brep:rwx /var/bindist
```

## Typical Usage

Run once a day from the `brep` crontab alongside `brep-clean`. A timeout of
`2880` minutes (48 hours) is a common starting point:

```
3 0 * * * $HOME/install/bin/brep-upload-bindist-clean /var/bindist 2880
```

This tool is only needed when `brep-upload-bindist` is configured as the
upload handler (`upload-handler` in `brep-module.conf`). Omit it if binary
distribution uploads are not in use.

## Exit Status

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error |

## See Also

- [brep README](README.md)
- [brep-clean](brep-clean.md) -- remove expired build records and tenants
- [brep-request-handling](brep-request-handling.md) -- build artifact upload protocol
