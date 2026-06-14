# Tests: Package version format

Source documentation: `guides/bpkg-package-name-version.md`


## T001 -- Full version format

**Query:** What is the full grammar of a bpkg package version?

**Key facts** (all must appear in a correct answer):
- The format is: `[+<epoch>-]<upstream>[-<prerel>][+<revision>][#<iteration>]`
- All parts except `<upstream>` are optional.

**Source:** `guides/bpkg-package-name-version.md`


## T002 -- Epoch purpose and default

**Query:** What is the purpose of the epoch in a bpkg version, and what is the
default epoch value when it is not specified?

**Key facts** (all must appear in a correct answer):
- The epoch allows switching to a new versioning scheme that would sort
  incompatibly with the old one.
- The default epoch value is `1` when not explicitly specified (for stub versions it defaults to `0`).

**Source:** `guides/bpkg-package-name-version.md`


## T003 -- Pre-release format

**Query:** Give two valid examples of a bpkg pre-release version.

**Key facts** (all must appear in a correct answer):
- `1.2.3-alpha.1` is a valid pre-release version.
- `1.2.3-beta.1` is a valid pre-release version.
- The pre-release part follows the upstream version after a `-` separator.

**Source:** `guides/bpkg-package-name-version.md`


## T004 -- Version ordering rule

**Query:** In what order does bpkg sort versions when comparing them?

**Key facts** (all must appear in a correct answer):
- Versions are sorted first by epoch, then upstream, then prerel (pre-release),
  then revision, then iteration.

**Source:** `guides/bpkg-package-name-version.md`


## T005 -- Pre-release sorts below release

**Query:** Does a pre-release version of `1.2.3` sort above or below the final
`1.2.3` release?

**Key facts** (all must appear in a correct answer):
- A pre-release version sorts below the final release of the same upstream
  version.

**Source:** `guides/bpkg-package-name-version.md`
