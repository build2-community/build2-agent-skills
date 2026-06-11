# bdep-publish -- publish project to archive repository

## Synopsis

```
bdep publish [<options>] [<cfg-spec>] [<pkg-spec>]

<pkg-spec> = (<pkg> | (--directory|-d <pkg-dir>))... | <prj-spec>
<prj-spec> = --directory|-d <prj-dir>
<cfg-spec> = (@<cfg-name> | --config|-c <cfg-dir>)... | --all|-a | --forward
```

## Description

The `publish` command publishes the project packages to an archive-based
repository.

Normally, `publish` operates on all the packages in a project. If no project
directory nor package directory/name is specified, then the current working
directory is assumed and all the packages are published, even if the current
directory is a package directory. If, however, one or more packages are
specified explicitly with `--directory|-d` or as _pkg_ names, then `publish`
assumes you know what you are doing and only publishes these packages. If no
configuration is specified, then the default configurations are used to prepare
the package distributions. See
[bdep-projects-configs(1)](bdep-projects-configs.md) for details on specifying
projects and configurations.

For each specified package the `publish` command prepares a package archive and
sends it as part of the package submission request to an archive-based
repository. If the repository is not explicitly specified with the
`--repository` option, packages are published to `cppget.org` by default.

Along with the package archive, the submission request specifies the repository
section to publish the package under, the control repository URL to use for
authorization, and the publisher's name and email address for the record. While
the exact usage and interpretation of this information depends on the specific
repository, the following semantics apply when submitting to `cppget.org`.

The section specifies the desired repository section to publish the project
under. If not explicitly specified with the `--section` option, one of the
`alpha`, `beta`, or `stable` values are automatically derived from the package
version.

The control repository URL is a publicly accessible, read-only URL to a
version control repository (normally the same as the project's) that is used
to authenticate the publisher as someone authorized to publish under this
package name (currently only `git(1)` is supported).

Prior to sending the submission request, the `publish` command adds the package
archive checksum to the `build2-control` branch of the project's version
control repository. Upon receiving the submission request, the archive
repository either (1) associates the control repository with the package name
if this is the first time this package name is published or (2) compares the
submitted control repository to the previously associated and, if matching,
queries the `build2-control` branch to verify that the submitter is authorized
to publish this archive under this package name.

Unless the control repository URL is specified with the `--control` option, it
will be automatically derived from the version control's "remote" URL. In case
of `git(1)`, it will be based on the `remote.origin.url` configuration value
unless overridden with `remote.origin.build2ControlUrl` or
`remote.origin.build2Url`. The special `none` value to the `--control` option
can be used to disable this functionality.

If the `--forward` option is specified then the forwarded configurations are
used to prepare the package distributions. In particular, this means that in
this mode the project doesn't need to be initialized and all that's required is
for package's source directories to be configured to forward to an out of
source build configuration (see [b(1)](../b/b.md) for details on forwarded
configurations). This, for example, can be used to publish packages that don't
use the standard version.

## Options

Note: also see [common options](bdep-common-options.md).

| Option | Arg | Description |
|--------|-----|-------------|
| `--yes`, `-y` | | Don't prompt for confirmation before publishing. |
| `--control` | `<url>` | Control repository URL for the packages being published. |
| `--repository` | `<url>` | Repository to publish the packages to. |
| `--section` | `<name>` | Repository section to publish the packages under. |
| `--author-name` | `<name>` | Publisher's name. If unspecified, it will be obtained from the environment and/or version control system. See the ENVIRONMENT section for details. |
| `--author-email` | `<email>` | Publisher's email address. If unspecified, it will be obtained from the environment and/or version control system. See the ENVIRONMENT section for details. |
| `--force` | `<check>` | Force publishing, disabling the specified check. Repeat this option to disable multiple checks. |
| `--simulate` | `<outcome>` | Simulate the specified outcome of the submission process without actually performing any externally visible actions (such as publishing the package). The commonly used outcome value is `success`. For other recognized outcomes refer to the submission service documentation. |
| `--forward` | | Use the forwarded configuration for each package instead of the default configuration. |
| `--all`, `-a` | | Use all build configurations. |
| `--config`, `-c` | `<dir>` | Specify the build configuration as a directory. |
| `--directory`, `-d` | `<dir>` | Assume project/package is in the specified directory rather than in the current working directory. |

## Default Options Files

See [bdep-default-options-files(1)](bdep-default-options-files.md) for an
overview of the default options files. For the `publish` command the search
start directory is the project directory. The following options files are
searched for in each directory and, if found, loaded in the order listed:

```
bdep.options
bdep-publish.options
```

The following `publish` command options cannot be specified in the default
options files:

```
--directory|-d
```

## Environment

The `BDEP_AUTHOR_NAME` and `BDEP_AUTHOR_EMAIL` environment variables can be
used to specify the publisher's name and email address, respectively. If not
set, the `publish` command will first try to obtain the name and email from the
version control system (if used) and then from the `USER` and `EMAIL`
environment variables, respectively. See also the `--author-name` and
`--author-email` options.

## See Also

- [bdep README](README.md)
- [`package-naming`](../HOWTO/package-naming.md) -- naming packages for third-party projects
- [`package-version-non-semver`](../HOWTO/package-version-non-semver.md) -- projects that don't use semantic versioning
- [`package-version-none`](../HOWTO/package-version-none.md) -- projects with no version at all
- [`packaging-guide-summary`](../guides/packaging-guide-summary.md) -- end-to-end packaging guide
