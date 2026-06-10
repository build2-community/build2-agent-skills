# bpkg common options

These options are available in all bpkg commands. Per-command reference files
note "inherits common options" and link here rather than repeating them.

## Verbosity and Output

| Option | Arg | Default | Description |
|--------|-----|---------|-------------|
| `-v` | | | Print essential underlying commands being executed. Equivalent to `--verbose 2`. |
| `-V` | | | Print all underlying commands being executed. Equivalent to `--verbose 3`. |
| `--quiet`, `-q` | | | Run quietly, only printing error messages. Equivalent to `--verbose 0`. |
| `--verbose` | `<level>` | `1` | Set the diagnostics verbosity to `<level>` between 0 and 6. Level 0 disables any non-error messages. Level 6 produces the most information. The types of diagnostics added at each level: 1 = high-level information messages, 2 = essential underlying commands, 3 = all underlying commands, 4 = information helpful to the user, 5 = information helpful to the developer, 6 = even more detailed information. |
| `--stdout-format` | `<format>` | `lines` | Representation format for printing to `stdout`. Valid values are `lines` (default) and `json`. See the JSON OUTPUT section in the bpkg manual for details on the `json` format. |
| `--no-result` | | | Don't print informational messages about the outcome of performing a command or some of its parts. If this option is specified, then for certain long-running command parts progress is displayed instead, unless suppressed with `--no-progress`. |
| `--structured-result` | `<fmt>` | | Write the result of performing a command in a structured form. Instead of printing informational messages to `stderr`, `bpkg` writes a machine-readable result description to `stdout` in the specified format. Not all commands support structured result output. Valid `<fmt>` values are command-specific; consult the command documentation for details. |
| `--progress` | | | Display progress indicators for long-lasting operations such as network transfers and building. If printing to a terminal, progress is displayed by default for low verbosity levels. Use `--no-progress` to suppress. |
| `--no-progress` | | | Suppress progress indicators for long-lasting operations such as network transfers and building. |
| `--diag-color` | | | Use color in diagnostics. If printing to a terminal, color is used by default provided the terminal is not dumb. Use `--no-diag-color` to suppress. |
| `--no-diag-color` | | | Don't use color in diagnostics. |

## Parallelism

| Option | Arg | Default | Description |
|--------|-----|---------|-------------|
| `--jobs`, `-j` | `<num>` | | Number of jobs to perform in parallel. If not specified, or specified with value `0`, the number of available hardware threads is used. If the value is negative, the number of available hardware threads reduced by that value is used. This option is also propagated to build system operations such as `update`, `test`, etc. |

## Build System

| Option | Arg | Default | Description |
|--------|-----|---------|-------------|
| `--build` | `<path>` | | The build program to use to build packages. This should be the path to the build2 `b` executable. Additional options can be passed with `--build-option`. If not specified, `bpkg` defaults to `b` plus any executable suffix used when building `bpkg` (for example, if `bpkg` was named `bpkg-1.0`, it will look for `b-1.0`). |
| `--build-option` | `<opt>` | | Additional option to pass to the build program. Repeat to specify multiple build options. |

## Network and Fetch

| Option | Arg | Default | Description |
|--------|-----|---------|-------------|
| `--fetch` | `<path>` | | The fetch program to use to download resources (packages, repository metadata, etc.). `bpkg` recognizes `curl`, `wget`, and `fetch`. The last component of `<path>` must contain one of these names as a substring. Additional options can be passed with `--fetch-option`. If not specified, `bpkg` discovers an available program in this preference order: `curl`, `wget`, `fetch`. |
| `--fetch-option` | `<opt>` | | Additional option to pass to the fetch program. Repeat to specify multiple fetch options. |
| `--fetch-timeout` | `<sec>` | | The fetch and fetch-like (for example, `git`) program timeout in seconds. Specifies the maximum time that can be spent without any network activity. Translated to `--max-time` for `curl` and `--timeout` for `wget` and `fetch`. For `git` over HTTP/HTTPS, achieved via `http.lowSpeedLimit=1` and `http.lowSpeedTime=<sec>` configuration values (the `git://` and `ssh://` protocols do not currently support timeouts). |
| `--offline` | | | Do not attempt to download resources, instead taking them from the local fetch cache if available and failing otherwise. No up-to-date checks of cached repository metadata are performed when offline. Can also be enabled by setting the `BPKG_FETCH_CACHE` environment variable. |
| `--no-fetch-cache` | | | Disable local caching of downloaded resources (packages, repository metadata, etc.). Can also be disabled by setting `BPKG_FETCH_CACHE` to `0` or `false`. If specified during configuration creation (`cfg-create`), the value is saved in the configuration and used as the default in subsequent commands. |
| `--fetch-cache` | `<mode>` | | Comma-separated list of local fetch cache modes. Recognized modes: `src`/`no-src` (enable/disable sharing of cached source directories for dependencies), `trust`/`no-trust` (enable/disable caching of repository authentication answers), and `offline` (equivalent to `--offline`). The default is no source sharing and trust caching enabled. Can also be specified via the `BPKG_FETCH_CACHE` environment variable. If specified during configuration creation, effective `src` and `trust` modes are saved and used as defaults in subsequent commands. |
| `--fetch-cache-path` | `<dir>` | | The directory of the local fetch cache. Ideally should be on the same filesystem (UNIX) or volume (Windows) as the build configuration directories to allow hard links. If not specified, non-precious data (packages, metadata) is placed in `$XDG_CACHE_HOME/build2/` or `$HOME/.cache/build2/` on UNIX and `%LOCALAPPDATA%\build2\cache\` on Windows. Semi-precious data (shared source directories) is placed in `.build2/cache/` under the user home directory on all platforms. Can also be specified with `BPKG_FETCH_CACHE_PATH`. |
| `--fetch-cache-session` | `<id>` | | The local fetch cache session. Specifying the same session id across multiple `bpkg` invocations eliminates repeated up-to-date checks of repository metadata. Any value guaranteed not to clash with previous sessions (such as a UUID) can be used. Can also be specified with `BPKG_FETCH_CACHE_SESSION`. Cannot be specified in default options files. |
| `--pkg-proxy` | `<url>` | | HTTP proxy server to use when fetching package manifests and archives from remote `pkg` repositories. The proxy `<url>` must be in the `http://host[:port]` form. If port is omitted, 80 is used. To allow caching, proxied `https://` URLs are converted to `http://` to prevent fetch program tunneling. This should only be used with signed repositories or when the proxy is inside a trusted network. |
| `--git` | `<path>` | `git` | The git program to use to fetch git repositories. Additional options can be passed with `--git-option`. Defaults to `git`. |
| `--git-option` | `<opt>` | | Additional common option to pass to the git program. Common options are those that precede the `git` command. Repeat to specify multiple git options. |
| `--git-capabilities` | `<up>=<pc>` | | Protocol capabilities (`<pc>`) for a `git` repository URL prefix (`<up>`). Valid capability values: `dumb` (no shallow clone support), `smart` (shallow clone but no unadvertised commit fetch), `unadv` (shallow clone and unadvertised commit fetch). For example: `--git-capabilities https://example.org=smart`. |

## External Tools

| Option | Arg | Default | Description |
|--------|-----|---------|-------------|
| `--sha256` | `<path>` | | The sha256 program to use to calculate SHA256 sums. `bpkg` recognizes `sha256`, `sha256sum`, and `shasum`. The last component of `<path>` must contain one of these names as a substring. Additional options can be passed with `--sha256-option`. If not specified, `bpkg` discovers an available program in this preference order: `sha256`, `sha256sum`, `shasum`. |
| `--sha256-option` | `<opt>` | | Additional option to pass to the sha256 program. Repeat to specify multiple options. |
| `--tar` | `<path>` | `tar` | The tar program to use to extract package archives (for example, `gtar` or `bsdtar`). Additional options can be passed with `--tar-option`. Defaults to `tar`. |
| `--tar-option` | `<opt>` | | Additional option to pass to the tar program. Repeat to specify multiple options. |
| `--openssl` | `<path>` | `openssl` | The openssl program to use for crypto operations. Additional options can be passed with `--openssl-option`. Values can be optionally qualified with the openssl command in `command:value` form to make the value applicable only to that specific command (for example, `--openssl pkeyutl:/path/to/openssl`). An unqualified value containing a colon can be specified as qualified with an empty command (for example, `--openssl :C:\bin\openssl`). For openssl versions prior to 3.0.0, `bpkg` uses the `rsautl` command instead of `pkeyutl` for signing and recovery operations. |
| `--openssl-option` | `<opt>` | | Additional option to pass to the openssl program. Values can be optionally qualified with the openssl command as described in `--openssl`. Repeat to specify multiple options. |
| `--sqlite-synchronous` | `<mode>` | `normal` | Filesystem synchronization mode for the fetch cache and configuration SQLite databases. Valid values: `off`, `normal` (default), `full`, `extra`. Corresponds to the SQLite `synchronous` pragma. See also the `BUILD2_SQLITE_SYNCHRONOUS` environment variable. The WAL journaling mode is used for the fetch cache database and the rollback journaling mode for configuration databases. |

## Repository Authentication

| Option | Arg | Default | Description |
|--------|-----|---------|-------------|
| `--auth` | `<type>` | `remote` | Types of repositories to authenticate. Valid values: `none`, `remote` (default), `all`. By default only remote repositories are authenticated. Pass `all` to also authenticate local repositories, or `none` to disable authentication completely. |
| `--trust` | `<fingerprint>` | | Trust a repository certificate with the given SHA256 fingerprint automatically, without prompting for confirmation. Repeat to trust multiple certificates. Note that `openssl` prints SHA1 fingerprints by default. To obtain a SHA256 fingerprint, pass the `-sha256` option: `openssl x509 -sha256 -fingerprint -noout -in cert.pem`. |
| `--trust-yes` | | | Assume the answer to all authentication prompts is `yes`. |
| `--trust-no` | | | Assume the answer to all authentication prompts is `no`. |

## Output Pager

| Option | Arg | Default | Description |
|--------|-----|---------|-------------|
| `--pager` | `<path>` | | The pager program to use to show long text. Commonly used programs are `less` and `more`. Additional options can be passed with `--pager-option`. Specify an empty string to disable the pager. If not specified, `bpkg` tries to use `less`, and if that is not available, no pager is used. |
| `--pager-option` | `<opt>` | | Additional option to pass to the pager program. Repeat to specify multiple options. |

## Configuration and Default Options Files

| Option | Arg | Default | Description |
|--------|-----|---------|-------------|
| `--options-file` | `<file>` | | Read additional options from `<file>`. Each option should appear on a separate line, optionally followed by a space or `=` and an option value. Empty lines and lines starting with `#` are ignored. Option values can be enclosed in double (`"`) or single (`'`) quotes to preserve leading/trailing whitespace or to specify empty values. If the value itself contains leading or trailing quotes, enclose it with an extra pair of quotes (for example, `'"x"'`). Non-leading and non-trailing quotes are part of the option value. The semantics is equivalent to providing the same options in the same order on the command line at the point where `--options-file` is specified, except that shell escaping and quoting is not required. Repeat to specify more than one options file. |
| `--default-options` | `<dir>` | | The directory to load additional default options files from. |
| `--no-default-options` | | | Don't load default options files. |

## Troubleshooting

| Option | Arg | Default | Description |
|--------|-----|---------|-------------|
| `--keep-tmp` | | | Don't remove `bpkg`'s temporary directory at the end of command execution and print its path at verbosity level 2 or higher. Primarily useful for troubleshooting. |

## See Also

- [bpkg SUMMARY](SUMMARY.md)
