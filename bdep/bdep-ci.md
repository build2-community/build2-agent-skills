# bdep-ci -- submit project test request to CI server

## Synopsis

```
bdep ci [<options>] [<cfg-spec>] [<pkg-spec>]

<cfg-spec> = (@<cfg-name> | --config|-c <cfg-dir>)... | --all|-a | --forward
<pkg-spec> = (<pkg> | (--directory|-d <pkg-dir>))... | <prj-spec>
<prj-spec> = --directory|-d <prj-dir>
```

## Description

The `ci` command submits the project packages test request to a CI server.

If no project or package directory is specified, then the current working
directory is assumed. If no configuration is specified, then the default
configurations are used. If the specified directory is a project directory,
then all the packages initialized in the configurations are submitted, unless
the `--forward` option is specified (see below). See
[bdep-projects-configs(1)](bdep-projects-configs.md) for details on specifying
projects and configurations.

A CI request consists of the specified packages and their versions as well as
the project's remote version control repository URL corresponding to the
current (local) state of the project. The CI server should be able to fetch
these package versions from this repository as well as any dependencies from
this repository or its prerequisite/complement repositories, according to each
package's `repositories.manifest`.

CI consumes the git repository. The project's `repositories.manifest` is
therefore the repository manifest (not a nested file inside a package
archive). See
[Which repositories.manifest is consulted](../guides/packaging-guide-summary.md#which-repositoriesmanifest-is-consulted)
for the `pkg` vs `git`/`dir` split and why this differs from `bdep publish`.

If the CI server is not explicitly specified with the `--server` option, the
request is submitted to `ci.cppget.org` by default.

Unless the remote repository URL is specified with the `--repository` option,
it will be automatically derived from the version control's "remote" URL. In
case of `git(1)`, it will be based on the `remote.origin.url` configuration
value unless overridden with `remote.origin.build2Url`. The repository URL is
then adjusted to correspond to the current (local) state of the project. In
case of `git(1)`, the current branch and commit id are added as the repository
URL fragment (see [bpkg-repository-types(1)](../bpkg/bpkg-repository-types.md)
for details).

Some package manifest values can be overridden as part of the CI request
submission using the `--override` and `--overrides-file` options as well as
their `--builds`, `--build-config`, `--target-config`, `--package-config`, and
`--build-email` shortcuts. This is primarily useful for specifying alternative
build configurations and/or build notification emails. For example:

```
$ bdep ci --builds gcc
$ bdep ci --builds network/gcc
$ bdep ci --target-config 'linux*-gcc*'
$ bdep ci --package-config network
$ bdep ci --build-config 'network/linux*-gcc*'

$ bdep ci --override \
  'default-build-config: config.foo.cache=true config.foo.buffer=16'

$ bdep ci --override 'mytest-build-config: config.foo.cache=true' \
  --package-config mytest

$ bdep ci --override 'build-auxiliary: *-postgresql_16'
```

Manifest overrides other than `[*-]build-auxiliary[-*]` override the entire
value group that they belong to. The `[*-]build-auxiliary[-*]` values only
override the matching values, which are expected to already be present in the
package manifest. Currently, the following value groups/values can be
overridden. The `build-*email` group is overridden by default as if by
specifying an empty build email.

```
build-email build-{warning,error}-email
builds build-{include,exclude}
build-bot
*-builds *-build-{include,exclude}
*-build-bot
*-build-config
*-build-email *-build-{warning,error}-email

[*-]build-auxiliary[-*]
```

For the package configuration-specific build constraint, email, auxiliary, and
custom bot public key overrides, the corresponding configuration must exist in
the package manifest. In contrast, the package configuration override
(`*-build-config`) adds a new configuration if it doesn't exist and updates
the arguments of the existing configuration otherwise. In the former case, all
the potential build constraint, email, auxiliary, and custom bot public key
overrides for such a newly added configuration must follow the corresponding
`*-build-config` override.

Note that the build constraints group values (both common and build package
configuration-specific) are overridden hierarchically so that the
`[*-]build-{include,exclude}` overrides don't affect the respective
`[*-]builds` values.

Note also that the common and build package configuration-specific build
constraints group value overrides are mutually exclusive. If the common build
constraints are overridden, then all the configuration-specific constraints are
removed. Otherwise, if any configuration-specific constraints are overridden,
then for the remaining configurations the build constraints are reset to
`builds: none`.

Similar to the build constraints groups, the common and build package
configuration-specific custom bot public key value overrides are mutually
exclusive. If the common build custom bot public keys are overridden, then all
the configuration-specific custom bot public keys are removed. Otherwise, if
any configuration-specific custom bot public keys are overridden, then for the
remaining configurations the custom bot public keys are left unchanged.

Similar to the above, the common and build package configuration-specific
build emails group value overrides are mutually exclusive. If the common build
emails are overridden, then all the configuration-specific emails are removed.
Otherwise, if any configuration-specific emails are overridden, then for the
remaining configurations the build emails are reset to the empty values and the
build warning and error emails are removed (which effectively disables email
notifications for such configurations).

If supported by the CI service, a package can be tested interactively in a
specific build configuration using the `--interactive|-i` option. In this mode
the CI service provides the login information for the execution environment and
pauses the testing at the specified breakpoint.

While the exact interpretation of the CI request depends on the specific
service, normally, the CI server will respond with a reference that can be used
to query the results. On cppget.org, a passing `test-installed` phase is
folded into each configuration's `log`. Only a warning or error gets a
separate `test-installed` link. See [ci-results.md](../HOWTO/ci-results.md).

If the `--forward` option is specified then the forwarded configurations are
used instead of the default configurations. In particular, this means that in
this mode the project doesn't need to be initialized and all that's required is
for package's source directories to be configured to forward to an out of
source build configuration (see [b(1)](../b/b.md) for details on forwarded
configurations). This, for example, can be used to submit packages that don't
use the standard version.

## Options

Note: also see [common options](bdep-common-options.md).

| Option | Arg | Description |
|--------|-----|-------------|
| `--yes`, `-y` | | Don't prompt for confirmation before submitting. |
| `--interactive`, `-i` | `<cf>[:<bp>]` | Test the package interactively in the specified build configuration, pausing the execution at the specified breakpoint. The build configuration is a target configuration (_tc_), optionally for a specific package configuration (_pc_) and/or for a specific target (_tg_): `<cf> = [pc/]tc | pc/tc/tg`. Refer to `--build-config` for details on the build configuration component semantics. Note that for interactive testing they should identify a single build configuration. Failed that, the test request will be aborted. Valid breakpoint values are `none` (don't stop), `error` (stop after first error), `warning` (stop after first warning), as well as the CI service-specific step ids in which case the execution stops before performing the specified step. If no breakpoint is specified, then `error` is assumed. |
| `--server` | `<url>` | CI server to submit the request to. |
| `--repository` | `<url>` | Remote repository URL for the project. |
| `--override` | `<name>:<value>` | Package manifest value override. Repeat this option to override multiple values. |
| `--overrides-file` | `<file>` | Read manifest value overrides from the specified manifest fragment file. Repeat this option to specify multiple override files. |
| `--builds` | `[<pc>/]<class-expr>` | Shortcut for `--override [pc-]builds:<class-expr>`. Repeat this option to specify multiple build target configuration classes. |
| `--build-config` | `<pc>/<tc>[/<tg>]` | Shortcut for the options sequence `--override pc-builds:all`, `--override pc-build-include:tc[/tg]`, `--override pc-build-exclude:**`. The first override is omitted if the `pc-builds` override is specified on the command line. Repeat this option to specify multiple build configurations. |
| `--target-config` | `<tc>[/<tg>]` | Shortcut for the options sequence `--override builds:all`, `--override build-include:tc[/tg]`, `--override build-exclude:**`. The first override is omitted if the `builds` override is specified on the command line. Repeat this option to specify multiple build target configurations. |
| `--package-config` | `<pc>` | Shortcut for `--override pc-builds:...`, `--override pc-build-include:...`, `--override pc-build-exclude:...`, where the override values are the build constraints for the specified build package configuration from the package manifest. Repeat this option to specify multiple build package configurations. |
| `--build-email` | `<email>` | Shortcut for `--override build-email:<email>`. |
| `--force` | `<check>` | Force submission, disabling the specified check. Repeat this option to disable multiple checks. |
| `--simulate` | `<outcome>` | Simulate the specified outcome of the CI process without actually performing any externally visible actions (such as testing the packages or publishing the result). The commonly used outcome value is `success`. For other recognized outcomes refer to the CI service documentation. |
| `--forward` | | Use the forwarded configuration for each package instead of the default configuration. |
| `--all`, `-a` | | Use all build configurations. |
| `--config`, `-c` | `<dir>` | Specify the build configuration as a directory. |
| `--directory`, `-d` | `<dir>` | Assume project/package is in the specified directory rather than in the current working directory. |

## Default Options Files

See [bdep-default-options-files(1)](bdep-default-options-files.md) for an
overview of the default options files. For the `ci` command the search start
directory is the project directory. The following options files are searched
for in each directory and, if found, loaded in the order listed:

```
bdep.options
bdep-ci.options
```

The following `ci` command options cannot be specified in the default options
files:

```
--directory|-d
```

## See Also

- [bdep README](README.md)
