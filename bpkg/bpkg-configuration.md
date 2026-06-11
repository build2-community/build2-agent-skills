# bpkg-configuration -- configuration directory option

> Shared option reference. `configuration.cli` defines a shared options class
> (`configuration_options`) inherited by most bpkg commands that operate on a
> configuration directory. It is not a man page or a standalone command.

## The --directory option

Most bpkg commands that act on a configuration accept a `--directory|-d`
option:

| Option | Arg | Default | Description |
|--------|-----|---------|-------------|
| `--directory`, `-d` | `<dir>` | `.` (current directory) | Assume the configuration is in `<dir>` rather than in the current working directory. |

Commands that accept this option include `cfg-create`, `cfg-info`, `cfg-link`,
`cfg-unlink`, `rep-add`, `rep-remove`, `rep-list`, `rep-info`, `rep-fetch`,
`pkg-build`, `pkg-drop`, `pkg-status`, and all other package lifecycle
commands.

`--directory` cannot be specified in default options files for most commands.
Each command's DEFAULT OPTIONS FILES section lists any such restrictions.

## See Also

- [bpkg README](README.md)
- [bpkg-cfg-create](bpkg-cfg-create.md)
