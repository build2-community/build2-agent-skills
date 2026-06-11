# bpkg-pkg-drop -- drop package

## Synopsis

```
bpkg pkg-drop|drop [<options>] <pkg>...
bpkg pkg-drop|drop [<options>] --all|-a
bpkg pkg-drop|drop [<options>] (--all-pattern <pattern>)...
```

## Description

The `pkg-drop` command drops from the configuration the specified packages (the first form), all the held packages (the second form, see [bpkg-pkg-status](bpkg-pkg-status.md)), or all the held packages that match any of the specified wildcard patterns (the third form). If the packages being dropped still have dependent packages, then those will have to be dropped as well and you will be prompted to confirm. And if the packages being dropped have dependency packages that would otherwise no longer be used, then they will be dropped as well unless the `--keep-unused|-K` option is specified.

The `pkg-drop` command also supports several options (described below) that allow you to control the amount of work that will be done.

## Options

Note: also see [common options](bpkg-common-options.md).

| Option | Arg | Description |
|---|---|---|
| `--all`, `-a` | | Drop all held packages. |
| `--all-pattern` | `<pattern>` | Drop held packages that match the specified wildcard pattern. Repeat this option to match multiple patterns. Note that you may need to quote the pattern to prevent expansion by your shell. |
| `--yes`, `-y` | | Assume the answer to all prompts is `yes`. Note that this option does not apply to the dropping of dependents; use `--drop-dependent` for that. |
| `--no`, `-n` | | Assume the answer to all prompts is `no`. Only makes sense together with `--print-only|-p`. |
| `--keep-unused`, `-K` | | Don't drop dependency packages that were automatically built but will no longer be used. |
| `--drop-dependent`, `-D` | | Don't warn about or ask for confirmation if dropping dependent packages. |
| `--keep-dependent` | | Issue an error if attempting to drop dependent packages. |
| `--dependent-exit` | `<code>` | Silently exit with the specified error code if attempting to drop dependent packages. |
| `--disfigure-only` | | Disfigure all the packages but don't purge. |
| `--print-only`, `-p` | | Print to `stdout` what would be done without actually doing anything. |
| `--plan` | `<header>` | Print the plan (even if `--yes` is specified) and start it with the _header_ line (unless it is empty). |

## Default Options Files

See [bpkg-default-options-files](bpkg-default-options-files.md) for an overview of the default options files. For the `pkg-drop` command the search start directory is the configuration directory. The following options files are searched for in each directory and, if found, loaded in the order listed:

```
bpkg.options
bpkg-pkg-drop.options
```

The following `pkg-drop` command options cannot be specified in the default options files:

```
--directory|-d
```

## See Also

- [bpkg README](README.md)
