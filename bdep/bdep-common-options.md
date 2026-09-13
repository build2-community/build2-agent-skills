# bdep common options

These options are available in all bdep commands. Per-command reference files
note "inherits common options" and link here rather than repeating them.

Common options can be specified either before the command or after, together
with the command-specific options.

## Verbosity and Output

| Option | Short | Arg | Default | Description |
|--------|-------|-----|---------|-------------|
| `--verbose` | | `<level>` | `1` | Set the diagnostics verbosity to `<level>` between 0 and 6. Level 0 disables any non-error messages. Level 1 (default) prints high-level information messages. Level 2 prints essential underlying commands being executed. Level 3 prints all underlying commands being executed. Level 4 prints information that could be helpful to the user. Level 5 prints information that could be helpful to the developer. Level 6 prints even more detailed information. |
| `-v` | | | | Print essential underlying commands being executed. Equivalent to `--verbose 2`. |
| `-V` | | | | Print all underlying commands being executed. Equivalent to `--verbose 3`. |
| `--quiet` | `-q` | | | Run quietly, only printing error messages. Equivalent to `--verbose 0`. |
| `--stdout-format` | | `<format>` | `lines` | Representation format for printing to `stdout`. Valid values are `lines` (default) and `json`. See the JSON OUTPUT section for details on the `json` format. |
| `--jobs` | `-j` | `<num>` | | Number of jobs to perform in parallel. If not specified or specified with the value `0`, then the number of available hardware threads is used. If the value is negative, then the number of available hardware threads reduced by this value is used. This option is also propagated when executing package manager commands such as `bpkg-pkg-update`, `bpkg-pkg-test`, etc., which in turn propagate it to the build system. |
| `--progress` | | | | Display progress indicators for long-lasting operations, such as network transfers, building, etc. If printing to a terminal the progress is displayed by default for low verbosity levels. Use `--no-progress` to suppress. |
| `--no-progress` | | | | Suppress progress indicators for long-lasting operations, such as network transfers, building, etc. |
| `--diag-color` | | | | Use color in diagnostics. If printing to a terminal the color is used by default provided the terminal is not dumb. Use `--no-diag-color` to suppress. |
| `--no-diag-color` | | | | Don't use color in diagnostics. |

## Build System Integration

| Option | Arg | Description |
|--------|-----|-------------|
| `--bpkg` | `<path>` | The package manager program to be used for build configuration management. This should be the path to the `bpkg` executable. Additional options can be passed with `--bpkg-option`. If not specified, `bdep` will by default use `bpkg` plus an executable suffix if one was specified when building `bdep`. For example, if `bdep` name was set to `bdep-1.0`, then it will look for `bpkg-1.0`. |
| `--bpkg-option` | `<opt>` | Additional option to be passed to the package manager program. See `--bpkg` for more information. Repeat this option to specify multiple package manager options. |
| `--build` | `<path>` | The build program to be used to build packages. This should be the path to the build2 `b` executable. Additional options can be passed with `--build-option`. If not specified, `bdep` will by default use `b` plus an executable suffix if one was specified when building `bdep`. For example, if `bdep` name was set to `bdep-1.0`, then it will look for `b-1.0`. |
| `--build-option` | `<opt>` | Additional option to be passed to the build program. See `--build` for more information. Repeat this option to specify multiple build options. |
| `--curl` | `<path>` | The curl program to be used for network operations. Additional options can be passed with `--curl-option`. If not specified, `bdep` will use `curl` by default. Note that this program will also be used by the underlying `bpkg` invocations unless overridden. |
| `--curl-option` | `<opt>` | Additional option to be passed to the curl program. See `--curl` for more information. Repeat this option to specify multiple curl options. Note that these options will also be used by the underlying `bpkg` invocations provided that curl is used. |
| `--offline` | | Do not attempt to download resources (packages, repository metadata, etc), instead taking them from the local fetch cache if available and failing otherwise. See bpkg-common-options for details on the offline mode. |
| `--no-fetch-cache` | | Disable local caching of downloaded resources (packages, repository metadata, etc). By default these are cached in a permanent local cache. See bpkg-common-options for details on the fetch cache. |
| `--fetch-cache` | `<mode>` | Comma-separated list of local fetch cache modes. See bpkg-common-options for details on the available modes. Note that the default for `bdep` is to enable sharing of cached source directories for dependencies during configuration creation. |
| `--fetch-cache-session` | `<id>` | The local fetch cache session. Specifying the same session id across multiple `bdep` invocations allows eliminating repeated up-to-date checks of repository metadata. Any value, such as a UUID, that is guaranteed not to clash with previous sessions can be used as a session id. Cannot be specified in default options files. |
| `--sqlite-synchronous` | `<mode>` | Filesystem synchronization mode for the project SQLite database. Valid values are `off`, `normal` (default), `full`, and `extra`. See the SQLite documentation on the `synchronous` pragma for details. See also the `BUILD2_SQLITE_SYNCHRONOUS` environment variable. Note that WAL (Write-Ahead Logging) journaling mode is used for the project database. Note also that this option is not passed to the underlying `bpkg` commands (use `--bpkg-option` for that). |

## Configuration

| Option | Arg | Description |
|--------|-----|-------------|
| `--options-file` | `<file>` | Read additional options from `<file>`. Each option should appear on a separate line optionally followed by a space or equal sign (`=`) and an option value. Empty lines and lines starting with `#` are ignored. Option values can be enclosed in double (`"`) or single (`'`) quotes to preserve leading and trailing whitespaces as well as to specify empty values. If the value itself contains trailing or leading quotes, enclose it with an extra pair of quotes, for example `'"x"'`. Non-leading and non-trailing quotes are interpreted as being part of the option value. The semantics of providing options in a file is equivalent to providing the same set of options in the same order on the command line at the point where `--options-file` is specified, except that shell escaping and quoting is not required. Repeat this option to specify more than one options file. |
| `--default-options` | `<dir>` | The directory to load additional default options files from. |
| `--no-default-options` | | Don't load default options files. |
| `--pager` | `<path>` | The pager program to be used to show long text. Commonly used pager programs are `less` and `more`. Additional options can be passed with `--pager-option`. If an empty string is specified as the pager program, then no pager will be used. If not specified, `bdep` will try to use `less`. If `less` is not available, no pager will be used. |
| `--pager-option` | `<opt>` | Additional option to be passed to the pager program. See `--pager` for more information. Repeat this option to specify multiple pager options. |

## JSON Output Format

Commands that support the JSON output (`--stdout-format json`) describe their
formats as a serialized representation of a C++ struct or an array thereof.

The order of members in a JSON object is fixed as specified in the
corresponding struct. While new members may be added in the future (and should
be ignored by older consumers), the semantics of existing members (including
whether the top-level entry is an object or array) may not change.

An object member is required unless its type is `optional<>`, `bool`, or
`vector<>` (array). For `bool` members, absent means `false`. For `vector<>`
members, absent means empty. An empty top-level array is always present.

## Default Options Files

See bdep-default-options-files for an overview of default options files.

The following common option cannot be specified in default options files:

- `--fetch-cache-session`

## Environment and Exit Status

The `BDEP_DEF_OPT` environment variable suppresses loading of default
options files in nested `bdep` invocations. `false`/`0` suppresses, `true`/`1`
loads. (`BUILD2_SQLITE_SYNCHRONOUS` is documented above alongside
`--sqlite-synchronous`.)

Exit status is non-zero in case of an error.

## See Also

- [bdep README](README.md)
