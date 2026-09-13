# bpkg-repository-types -- repository types, structure, and URLs

## Overview

This reference topic describes the repository types recognized by `bpkg`, their structure, and the format of their URLs. Currently three types of repositories are supported: archive-based `pkg`, directory-based `dir`, and version control-based `git`.

The repository location may specify the repository type as part of the URL scheme component in the _type_**+**_protocol_ form. For example:

```
git+https://example.com/foo
dir+file:///tmp/repo
```

Note that the explicit specification is only needed when the correct type cannot be guessed from the URL. See [bpkg-rep-add](bpkg-rep-add.md) for details.

## Repository Types

### pkg Repositories

A `pkg` repository is _archive_-based. That is, it contains a collection of various packages/versions as archive files. For more information on the structure of `pkg` repositories refer to the `build2` Package Manager Manual. The `pkg` repository location can be a local directory path or an `http(s)://` URL.

Each section directory has its own `repositories.manifest`. Resolution follows that file's complements and prerequisites, not a nested `repositories.manifest` inside a package archive. See [Which repositories.manifest is consulted](../guides/packaging-guide-summary.md#which-repositoriesmanifest-is-consulted).

### dir Repositories

A `dir` repository is _directory_-based. That is, it contains a collection of various packages as directories but only a single version per package can be present in such a repository. The `dir` repository location can be a local directory path or a `file://` URL.

A `dir` repository is expected to contain either the `manifest` or `packages.manifest` file in the root directory of the repository. If it only contains `manifest`, then it is assumed to be a simple, single-package repository with the `manifest` file being its package manifest. Otherwise, the `packages.manifest` file should list the locations of available packages as described in [Package List Manifest for `dir` Repositories](bpkg-repository-manifest-reference.md#package-list-manifest-for-dir-repositories).

A `dir` repository may also contain the `repositories.manifest` file in the root directory of the repository. This file can be used to describe the repository itself as well as specify its prerequisite and complement repositories. See [Repository List Manifest](bpkg-repository-manifest-reference.md#repository-list-manifest) for details on the format and semantics of this file.

Complements and prerequisites are the graph the *consumer's* repository follows. Resolution does not consult a nested `repositories.manifest` inside a `pkg` package archive. For the `pkg` vs `git`/`dir` split, see [Which repositories.manifest is consulted](../guides/packaging-guide-summary.md#which-repositoriesmanifest-is-consulted).

### git Repositories

A `git` repository is _version control_-based. That is, it normally contains multiple versions of the same package (but can also contain several, usually related, packages in the same repository).

A `git` repository has the same structure and manifest files as the `dir` repository. See [Package List Manifest for `dir` Repositories](bpkg-repository-manifest-reference.md#package-list-manifest-for-dir-repositories) and [Repository List Manifest](bpkg-repository-manifest-reference.md#repository-list-manifest) for details on their format and semantics.

Theoretically, a `git` repository may contain as many package versions as there are commits. Practically, however, only a small subset of them is normally of interest while fetching and processing the necessary information for all of them could be prohibitively expensive. As a result, by default, only advertised tags in the `refs/tags/v*` form where the part after `v` is also a valid standard version are considered to be sources of useful package versions. These commits normally correspond to released versions and are called the _default set_. Note that only the latest revision of each such version is considered.

Instead of the default set, it is possible to provide a custom set of available versions by specifying one or more commit ids and/or references and/or reference patterns in the repository URL fragment (see `git-ls-remote(1)` for details on advertised references). For example:

```
https://example.com/foo.git#v1.2.3
https://example.com/foo.git#master
https://example.com/foo.git#af234f56
https://example.com/foo.git#tags/releases/*
https://example.com/foo.git#HEAD,tags/v1.*.*,heads/feature-*
```

Furthermore, it is possible to expand (or narrow down) the default set using the special `##` fragment notation. For example:

```
https://example.com/foo.git##HEAD     - default set plus HEAD
https://example.com/foo.git##heads/*  - default set plus branches
https://example.com/foo.git##-v1.*    - default set minus v1.*
```

#### URL Fragment Reference Filter Syntax

A `git` repository URL fragment is a comma-separated list of reference filters in the following form:

`[`_refname_`][@`_commit_`]`

Either _refname_, _commit_, or both must be specified. If both are specified then _refname_ is only used to minimize the amount of data fetched and _commit_ is expected to belong to its history. For example:

```
.../foo.git#master@48fba3625d65941bb85a39061bcf795d4949c778
```

The _refname_ part can be an abbreviated commit id or an advertised reference or reference pattern under `refs/`. The _commit_ must be the complete, 40-character SHA1 that need not be advertised. For convenience, a 40-character filter that consists of only hexadecimal digits is assumed to be _commit_ even if not prefixed with `@`. In the unlikely event this produces an incorrect result, the `@`-form with omitted _commit_ can be used. For example:

```
.../foo.git#48fba3625d65941bb85a39061bcf795d4949c778   (commit id)
.../foo.git#deadbeefdeadbeefdeadbeefdeadbeefdeadbeef@  (reference)
```

The _refname_ part can use the `*` and `?` wildcard pattern characters with the standard semantics as well as the `**` character sequence which matches in subdirectories, recursively. For example:

```
.../foo.git#tags/v*    - tags/v1.2.3 but not tags/old/v0.1.0
.../foo.git#tags/v**   - tags/v1.2.3 and tags/old/v0.1.0
```

A relative _refname_ is searched for in `refs/`, `refs/tags/`, and `refs/heads/` as well as among symbolic references like `HEAD`. To anchor it to `refs/` make it absolute. For example:

```
.../foo.git#tags/v*   - refs/tags/v1.2.3 but also refs/heads/tags/voo
.../foo.git#/tags/v*  - refs/tags/v1.2.3 only
```

While a _refname_ pattern is allowed not to match any references, a non-pattern that does not resolve to a reference is invalid.

If a _refname_ starts with minus (`-`) then it is treated as an exclusion filter -- any references that it matches are excluded from the set included by the preceding filters (or the default set). For example:

```
.../foo.git#v*,-v1.*  - exclude v1.* from v*
.../foo.git##-v1.*    - exclude v1.* from default set
```

To support specifying literal leading minus, a _refname_ that starts with plus (`+`) is treated as an inclusion filter. For example:

```
.../foo.git#+x   - include  x
.../foo.git#+-x  - include -x
.../foo.git#++x  - include +x
```

#### Protocol Support and Fetch Minimization

Currently supported `git` protocols are `git://`, `ssh://` (but not `scp` pseudo-URL syntax), `http://`, and `https://` for remote repositories and `file://` for local repositories. While `bpkg` tries to minimize the amount of information (history) fetched, it is not always possible for some protocols and/or server configurations.

A `git` repository accessible via `http(s)://` can use either _dumb_ or _smart_ protocol (refer to the `git` documentation for details). The dumb protocol provides only limited support for fetch minimization and if this protocol is used, then `bpkg` has no choice but to download a substantial amount of history.

The smart protocol allows fetching of minimal history for tags and branches. Whether this is also possible for (all) commit ids depends on whether the server is configured to allow fetching unadvertised commits. For details, refer to the `uploadpack.allowReachableSHA1InWant` and `uploadpack.allowAnySHA1InWant` `git` configuration values.

The `git://` and `ssh://` protocols are similar to smart `http://` in that they support fetching minimal history for tags and branches and may or may not support this for commit ids depending on the server configuration. Note, however, that unlike for `http(s)://`, for these protocols `bpkg` does not try to sense if fetching unadvertised commits is allowed and always assumes that it is not. The sensed or assumed protocol capabilities can be overridden for a `git` repository URL prefix using the `--git-capabilities` option (see [bpkg-common-options](bpkg-common-options.md)).

Based on this information, to achieve optimal results the recommended protocol for remote repositories is smart `https://`. Additionally, if you are planning to refer to unadvertised commit ids, then also consider configuring the server to allow fetching unadvertised commits.

The `file://` protocol has the same fetch minimization support as `git://` and is therefore treated the same.

## See Also

- [bpkg README](README.md)
- [bpkg-rep-add](bpkg-rep-add.md)
- [bpkg-repository-manifest-reference](bpkg-repository-manifest-reference.md)
- [Which repositories.manifest is consulted](../guides/packaging-guide-summary.md#which-repositoriesmanifest-is-consulted)
- [bpkg-common-options](bpkg-common-options.md)
