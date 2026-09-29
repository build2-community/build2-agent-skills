# Installing Man Pages

Only two man page target types actually exist: `man{}` (generic, any
extension) and `man1{}` (fixed `.1` extension). Sections 2-9 have no
dedicated target type or install wiring, despite what both the build2
manual and the `target.hxx` design comment imply.

## The gap

`target.hxx`'s own design comment (right above the `man`/`man1` class
declarations) describes the intended plan: `man{}` for a custom page
installed anywhere, plus `man1..9{}` target types that "would be
automatically installed into correct locations on other platforms" from
section-numbered extensions. The upstream manual (`doc/manual.cli`) states
the same thing even more directly: "The `man<N>{}` target types (where
`<N>` is an integer between 1 and 9) ... are installed into the `man<N>/`
installation locations."

Neither is true beyond section 1. `grep "class LIBBUILD2_SYMEXPORT man"
libbuild2/target.hxx` finds exactly two classes, `man` and `man1`; nothing
for `man2` through `man9`. `libbuild2/install/init.cxx` confirms it from
the installability side: `DIR`, `set_dir`, and `install_path` are only ever
called for `man` and `man1`. There is no `config.install.man2` (etc.)
variable to override, and no per-section default location. Writing
`man3{foo}` in a buildfile fails outright with "unknown target type man3".

This is a real gap between documented intent and shipped implementation,
not a documentation-only oversight in this reference -- the `target.hxx`
comment itself flags the extension-remapping part as "@@ This is still a
TODO."

## The fix: generic `man{}` with an explicit install override

Use `man{}` and override the install path per page (or per glob), naming
the target section directory explicitly:

```
man{*.3}: install = man/man3/
```

Substitute the real section number for both the extension glob and the
`manN` directory. This is not man-specific magic: `install = man/man3/` is
the general install-path override mechanism, where the first path
component (`man`) names a known install location (`install.man`, which
defaults to `share/man/`) and everything after it is appended as a literal
subdirectory -- no `config.install.man3` variable is consulted or needed.
The result lands pages under `share/man/man3/`, which is where `man(1)`
actually searches when configured with a `MANPATH` rooted at the install
prefix.

For section 1 specifically, `man1{*}` works with no override: it already
has `.1` and `man1/` baked in.

Subsections (`.1p`, `.3p`, etc. for POSIX pages) don't need any of this:
just give the target its exact extension, `man1{foo.1p}`, and it installs
into `man1/` alongside the plain `.1` pages.

## Second gotcha: verify page content, not just presence

Upstream projects commonly ship a rendered `.N` file that is not a real
page at all, just a one-line groff cross-reference stub:

```
.so man3/OTHER.3
```

This is used when several function names are documented together under
one primary name (for example `libtpms`'s `TPMLIB_Terminate.3`, which
contains only `.so man3/TPMLIB_MainInit.3`). `man`/`man-db` resolves `.so`
by searching the same `manN/` directory for the target file. If that
target isn't also installed, `man` fails with "can't resolve ..." or "No
manual entry", not a partial-content warning.

Never conclude a set of man pages is packageable from filenames or
presence alone. Check each file's actual first line, and if any are `.so`
stubs, either install their target too (which may pull in a whole
generation step, such as `pod2man`, that the stub file let you avoid) or
drop the stub. Verify by actually querying a real install tree:

```
$ man -M <install-root>/share/man 3 foo
$ MANPATH=<install-root>/share/man man 3 foo
```

Concretely, for `libtpms`, all 9 pre-rendered `.3` files committed
upstream turned out to be `.so` stubs pointing at the 19 `.pod`-sourced
pages generated via `pod2man` -- installing only the "no extra tool
needed" 9 files ships zero working documentation, not partial
documentation.

## See Also

- [build2-modules-core.md](../guides/build2-modules-core.md#installation-layout):
  the named install location table and the general `install =` override
  syntax
- [packaging-guide-summary.md](../guides/packaging-guide-summary.md):
  where `doc{}`/`man{}` targets are listed in the root buildfile
