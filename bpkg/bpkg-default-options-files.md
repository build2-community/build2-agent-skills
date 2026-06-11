# bpkg-default-options-files -- specifying default options

> Help topic. Describes the default options file mechanism used by all bpkg
> commands, not a command itself.

## Synopsis

```
bpkg <command> [<mode-options>] ...
```

## Description

Instead of a separate config file format, the build2 toolchain uses _default
options files_ containing the same options as the command line. They behave
like files passed with `--options-file` but are loaded automatically.

### Search path

The search begins at the _start directory_ (determined per command -- see each
command's DEFAULT OPTIONS FILES section) and walks outward, directory by
directory, until it reaches the home directory or the filesystem root
(both excluded). In each directory along the way both `.build2/` and
`.build2/local/` subdirectories are checked. After the outer walk the search
continues in the `.build2/` subdirectory of the home directory and finally in
the system directory (e.g., `/etc/build2/`) if configured.

### Load order

Files are loaded from outermost to innermost -- system directory first, then
home directory, then the start directory -- with command line options applied
last. This means more specific settings override more generic ones.

Within each directory, which files are loaded and in what order is
command-specific. See each command's DEFAULT OPTIONS FILES section for details.

### --default-options placement

An additional directory specified with `--default-options` is inserted at the
appropriate point in the hierarchy: if it falls between the start directory
and the end of the outer walk it is loaded there, otherwise it is loaded after
the home directory.

### --no-default-options

If `--no-default-options` appears inside a default options file, the search
stops at that directory and no outer files are loaded. If specified on the
command line, no default options files are searched for or loaded at all.

### Remote files and security

The presence of a `.git` entry in a directory causes default options files in
that directory and any of its subdirectories to be treated as _remote_. Some
security-sensitive options may be disallowed or trigger a confirmation prompt
when specified in remote files. Files added via `--default-options` are never
considered remote.

### Tracing

The load order is traced at verbosity level 3 (`-V`).

## See Also

- [bpkg README](README.md)
- [bpkg-common-options](bpkg-common-options.md)
