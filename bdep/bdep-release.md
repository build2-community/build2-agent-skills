# bdep-release -- manage project's version during release

## Synopsis

```
bdep release [<options>] [<prj-spec>]

<prj-spec> = --directory|-d <prj-dir> | <pkg-spec>
<pkg-spec> = (<pkg> | (--directory|-d <pkg-dir>))...
```

## Description

The `release` command manages the project's version during the release.
Specifically, it first changes the snapshot version to the corresponding
release version in each project package's `manifest` file, commits these
changes (unless `--no-commit` is specified), tags this commit (unless
`--no-tag` is specified), and, if `--push` is specified, pushes the changes to
the remote. Unless `--no-open` is specified, the `release` command then opens
the next development cycle by changing the version to a snapshot, committing
these changes (unless `--no-commit` is specified), and, if `--push` is
specified, pushing them to the remote. Note that committing, tagging, and
pushing is currently only supported for `git(1)` project repositories.

The `release` command can also be used to release a new package revision by
passing the `--revision` option. In this mode `release` increments the current
version's revision component in each project package's `manifest` file,
commits these changes (unless `--no-commit` is specified), tags this commit
(unless `--no-tag` is specified), and, if `--push` is specified, pushes the
changes to the remote. In this mode `release` can be optionally instructed to
update an existing tag for the current version to point to the latest revision
(`--current-tag=update`) or to remove it (`--current-tag=remove`).

When releasing a revision, the project's repository index is expected to
already contain other changes since for a revision all the associated changes,
including to version, must belong to a single commit. Alternatively, a
revision can be released by amending one or more existing commits using the
`--amend` and `--squash` options. In this case the index may still contain
additional changes but is not required to.

The `release` command also has a number of _continue modes_ that allow the
completion of steps that were previously suppressed with the `--no-*` options
in the above main modes. These are `--tag` which tags the release commit and,
if `--push` is specified, pushes it to the remote, as well as `--open` which
performs the opening of the next development cycle as described above.

In all the modes that perform a commit, if the project's repository index
already contains other changes, then the commit message is automatically
opened for editing unless `--no-edit` is specified. The editing of the commit
message in the absence of other changes can be requested with the `--edit`
option.

Normally, `release` operates on all the packages in a project. If no project
directory is specified, then the current working directory is assumed and all
the packages are released, even if the current directory is a package
directory. If, however, one or more package directories are specified
explicitly with `--directory|-d`, then `release` assumes you know what you are
doing and only releases these packages. All the packages being released must
have the same version but may have different revisions.

## Options

Note: also see [common options](bdep-common-options.md).

| Option | Arg | Description |
|--------|-----|-------------|
| `--revision` | | Release a new package revision instead of a new version. |
| `--no-commit` | | Don't commit the changes. Implies `--no-tag` and, in the version release mode, `--no-open`. |
| `--no-tag` | | Don't tag the release commit. Tagging can be performed later using the `--tag` mode option. |
| `--tag` | | Tag the already released version instead of releasing a new one. |
| `--current-tag` | `<action>` | Specify what to do with an existing tag for the current version when tagging a new revision. Valid values are `keep` (default), `update`, and `remove`. |
| `--push` | | Push the committed changes and tags to the remote. |
| `--show-push` | | Print the push command instead of executing it. This allows examining the committed changes and tags before pushing them to the remote. Note that the command is printed to `stdout`. |
| `--no-open` | | Don't open the next development cycle. Opening can be performed later using the `--open` mode option. |
| `--open` | | Open the next development cycle instead of releasing a new version. |
| `--amend` | | Release a revision by amending the latest commit instead of making a new one. |
| `--squash` | `<num>` | Release a revision by squashing the specified number of previous commits and then amending the result. Requires `--amend` to be specified. |
| `--alpha` | | Release an alpha instead of the final version. |
| `--beta` | | Release a beta version instead of the final version. |
| `--minor` | | Release the next minor version instead of the current patch. |
| `--major` | | Release the next major version instead of the current minor or patch. |
| `--open-beta` | | Open the development cycle with the next beta version. |
| `--open-patch` | | Open the development cycle with the next patch version. This is the default if the current patch version is not `0` (bugfix release series). |
| `--open-minor` | | Open the development cycle with the next minor version. This is the default if the current patch version is `0` (feature release series). |
| `--open-major` | | Open the development cycle with the next major version. |
| `--open-base` | `<version>` | Open the development cycle with the specified version. The base version should be in the _major_**.**_minor_**.**_patch_ form with the opened version becoming _major_**.**_minor_**.**_patch_**-a.0.z**. |
| `--edit` | | Open the commit message for editing. |
| `--no-edit` | | Don't open the commit message for editing. |
| `--force` | `<check>` | Force releasing, disabling the specified check. Repeat this option to disable multiple checks. |
| `--yes`, `-y` | | Don't prompt for confirmation before releasing. |
| `--directory`, `-d` | `<dir>` | Assume project/package is in the specified directory rather than in the current working directory. |

## Default Options Files

See [bdep-default-options-files(1)](bdep-default-options-files.md) for an
overview of the default options files. For the `release` command the search
start directory is the project directory. The following options files are
searched for in each directory and, if found, loaded in the order listed:

```
bdep.options
bdep-release.options
bdep-release-{version|revision|open|tag}.options  # (mode-dependent)
```

The following `release` command options cannot be specified in the default
options files:

```
--directory|-d
--revision
--open
--tag
```

## See Also

- [bdep SUMMARY](SUMMARY.md)
