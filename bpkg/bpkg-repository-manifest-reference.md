# bpkg Repository Manifest Reference

## Overview

A `bpkg` repository describes itself, its prerequisite/complement
repositories, and its package list using a small family of manifest files
that live in the repository root directory. This reference covers those
repository-level manifests. For the package manifest (the `manifest` file
inside a package), see [bpkg-manifest-reference.md](bpkg-manifest-reference.md).

For repository structure, types (`pkg`/`dir`/`git`), and URLs, see
[bpkg-repository-types.md](bpkg-repository-types.md).

| File | Applies to | Purpose |
|---|---|---|
| `repositories.manifest` | all types | Describes the repository itself plus its prerequisite and complement repositories. |
| `packages.manifest` | all types | Lists the packages available in the repository. Format differs between `pkg` and `dir`/`git` repositories. |
| `signature.manifest` | `pkg` only | Checksum (and, if signed, signature) of `packages.manifest`. |


## Repository Manifest

Used inside a `repositories.manifest` (Repository List Manifest, below) to
describe one repository: the base repository being described, or one of its
prerequisite/complement repositories.

```
[location]: <uri>
[type]: pkg|dir|git
[role]: base|prerequisite|complement
[trust]: <fingerprint>
[url]: <url>
[email]: <email> [; <comment>]
[summary]: <text>
[description]: <text>
[certificate]: <pem>
[fragment]: <string>
```

| Field | Description |
|-------|-------------|
| `location` | Repository location. Omitted only for the base repository (whose location is already known -- we fetched its manifest from there). A relative location is resolved against the base repository's location; for `git`, a relative location does not inherit the base's URL fragment. |
| `type` | Repository type. Omitted for the base repository. If omitted for a prerequisite/complement, it is guessed from `location` (see `bpkg-rep-add`). |
| `role` | Repository's role in the graph. Omitted only for the base repository. |
| `trust` | SHA256 fingerprint (32 colon-separated hex digit pairs) to trust for this prerequisite/complement. Only meaningful for repository types that support authentication (currently `pkg`); trust applies only to this repository's use of it as a prerequisite/complement, not globally. |
| `url` | The repository's web interface (`brep`) URL. Base repository only. Can be absolute, or relative to `location` in the `./.`/`../..`-style form described below. |
| `email` | Repository contact email, shown in the web interface. Base repository only. |
| `summary` | Short repository description. Base repository only. |
| `description` | Detailed repository description. Base repository only. Rendered as paragraphs (blank-line separated) by the web interface -- other formatting (e.g. lists) is lost. |
| `certificate` | X.509 certificate (PEM) for the repository. Base repository only, and currently only meaningful for `pkg`. If present, `packages.manifest` must be signed with the matching private key and the signature stored in `signature.manifest` (see [Signature Manifest for pkg Repositories](#signature-manifest-for-pkg-repositories)). See [bpkg-repository-signing.md](bpkg-repository-signing.md) for how to generate and use it. |
| `fragment` | Repository fragment id. Only present in a merged manifest for a multi-fragment repository. |

**Relative `url` resolution:** when `url` is given as relative to `location`,
it must start with two path components, each either `.` or `..`. A leading
`..` strips the `www`/`pkg`/`bpkg` domain component from `location`'s host (the
same stripping used when deriving the repository's name from its location); a
second `..` strips a `pkg`/`bpkg` path component. The version component is
always removed from `location`'s path before the rest of `url` is appended and
the result normalized. For example, given a `location` of
`https://pkg.example.org/test/pkg/1/hello/stable`, a `url` of `../.` resolves
to `https://example.org/test/pkg/hello/stable`, and `../..` resolves to
`https://example.org/test/hello/stable`. This lets the same repository be
deployed to slightly different locations (development vs. production) while
keeping one manifest.


## Repository List Manifest

The `repositories.manifest` file, found in a repository's root directory.
Starts with an optional header manifest, followed by a sequence of
[Repository Manifests](#repository-manifest): the base repository (may be
omitted) plus its prerequisite and complement repositories, in any order.

Header synopsis:

```
[min-bpkg-version]: <ver>
[compression]: <compressions>
```

| Field | Description |
|-------|-------------|
| `min-bpkg-version` | Earliest `bpkg` version compatible with this repository. If specified, must be the first value in the header. |
| `compression` | Space-separated list of available compressed variants of `packages.manifest` (e.g. `lz4`). `none` means uncompressed; an absent value is equivalent to `none`. |

Example (`math/testing` repository, with a complement and a prerequisite):

```
# math/testing
#
: 1
min-bpkg-version: 0.14.0
:
email: math-pkg@example.org
summary: Math package repository
:
role: complement
location: ../stable
:
role: prerequisite
location: https://pkg.example.org/1/misc/testing
```

The first manifest here describes the base repository itself, the second a
complement repository (relative `location`), and the third a prerequisite
repository (absolute `location`).


## Signature Manifest for `pkg` Repositories

The `signature.manifest` file, found in a `pkg` repository's root directory.
Contains the checksum of `packages.manifest` and, if the repository is
signed (its `repositories.manifest` has a `certificate` value), the
signature of that checksum. The checksum guards against a downloaded
`signature.manifest`/`packages.manifest` pair belonging to different updates
(a mismatch could otherwise mean either a split update or tampering).

```
sha256sum: <sum>
[signature]: <sig>
```

| Field | Description |
|-------|-------------|
| `sha256sum` | SHA256 checksum of `packages.manifest`: 64 lower-case hex characters, computed in binary mode. |
| `signature` | Present only if `repositories.manifest` has a `certificate` value. The above `sha256sum`, encrypted with the repository certificate's private key and base64-encoded. See [bpkg-repository-signing.md](bpkg-repository-signing.md). |


## Package List Manifest for `pkg` Repositories

The `packages.manifest` file, found in a `pkg` repository's root directory.
Starts with a list manifest, followed by a (possibly empty) sequence of
package manifests (see [bpkg-manifest-reference.md](bpkg-manifest-reference.md)),
each extended with two additional fields and restricted as noted below.

List manifest:

```
sha256sum: <sum>
```

| Field | Description |
|-------|-------------|
| `sha256sum` | SHA256 checksum of the corresponding `repositories.manifest` (same format as above). Ties the two files together: changing `repositories.manifest` requires regenerating `packages.manifest`. |

Each package manifest in the sequence:

- Must not contain any `*-file` value or an incomplete `depends`/`constrains`
  value (convert to inline form or complete it, respectively).
- Must contain the `*-build` values, unless the corresponding files are
  absent.
- Additionally contains:

| Field | Description |
|-------|-------------|
| `location` | Path to the package archive file, relative to the repository root, in POSIX form. May include subdirectories (useful when a repository keeps multiple versions of a package in its root). |
| `sha256sum` | SHA256 checksum of the package archive file (same format as above). |


## Package List Manifest for `dir` Repositories

The `packages.manifest` file, found in a `dir` (or `git`, which shares this
format) repository's root directory. A (possibly empty) sequence of small
manifests:

```
location: <path>
[fragment]: <string>
```

| Field | Description |
|-------|-------------|
| `location` | Path to the package directory, relative to the repository root, in POSIX form. |
| `fragment` | Repository fragment id this package belongs to. Only present in a merged manifest for a multi-fragment repository. |

Example: a repository with a `src/` subdirectory containing the `libfoo` and
`foo` packages:

```
: 1
location: src/libfoo/
:
location: src/foo/
```


## See Also

- [bpkg-manifest-reference.md](bpkg-manifest-reference.md) -- package manifest fields
- [bpkg-repository-types.md](bpkg-repository-types.md) -- repository types, structure, and URLs
- [bpkg-repository-signing.md](bpkg-repository-signing.md) -- signing a repository
- [bpkg README](README.md)
