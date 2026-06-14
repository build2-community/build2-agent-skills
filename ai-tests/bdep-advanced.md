# Tests: bdep (advanced) -- config, release, publish

Source documentation: `bdep/bdep-config.md`, `bdep/bdep-release.md`, `bdep/bdep-publish.md`


## T001 -- bdep config add @ shortcut

**Query:** What is the `@` shortcut notation for config names in
`bdep config add`, and how is the configuration directory derived from it?

**Key facts** (all must appear in a correct answer):
- If no config name is given and the config directory argument starts with `@`,
  it is treated as the config name.
- The configuration directory is derived as _prj-dir_**-**_cfg-name_ (the
  project directory with a `-` and the name appended).
- Example: in a project directory `hello`, `bdep config add @clang` resolves
  the config directory to `../hello-clang`.

**Source:** `bdep/bdep-config.md`


## T002 -- Default and forwarded config designation

**Query:** Which configuration is designated as default and forwarded when
added or created with `bdep config`, and what flags suppress each designation?

**Key facts** (all must appear in a correct answer):
- The first added or created build configuration of each type is designated as
  the default unless `--no-default` is specified.
- The default build configuration of each type is also designated as forwarded
  unless `--no-forward` is specified or another configuration of this type is
  already designated as forwarded.

**Source:** `bdep/bdep-config.md`


## T003 -- bdep publish --control

**Query:** What is the control repository URL used for during `bdep publish`,
and what version control system is currently supported?

**Key facts** (all must appear in a correct answer):
- The control repository URL is a publicly accessible, read-only URL to a
  version control repository used to authenticate the publisher as someone
  authorized to publish under the package name.
- Currently only `git` is supported.
- Unless specified with `--control`, the URL is automatically derived from the
  version control's remote URL (based on `remote.origin.url` for git, unless
  overridden with `remote.origin.build2ControlUrl` or `remote.origin.build2Url`).

**Source:** `bdep/bdep-publish.md`


## T004 -- Publisher identity environment variables

**Query:** What are the two environment variable names used to supply the
publisher's name and email address to `bdep publish`?

**Key facts** (all must appear in a correct answer):
- `BDEP_AUTHOR_NAME` -- the publisher's name.
- `BDEP_AUTHOR_EMAIL` -- the publisher's email address.

**Source:** `bdep/bdep-publish.md`


## T005 -- bdep release version type flags

**Query:** What are the four flags that select which type of version to release
with `bdep release`, and what does each do?

**Key facts** (all must appear in a correct answer):
- `--alpha` -- release an alpha version instead of the final version.
- `--beta` -- release a beta version instead of the final version.
- `--minor` -- release the next minor version instead of the current patch.
- `--major` -- release the next major version instead of the current minor or
  patch.

**Source:** `bdep/bdep-release.md`
