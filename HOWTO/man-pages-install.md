# Installing Man Pages

Only two man page target types exist: `man{}` (generic, any extension)
and `man1{}` (fixed `.1` extension). Sections 2-9 have no dedicated target
type or install location.

## The gap

The upstream manual (`doc/manual.cli`) says "The `man<N>{}` target types
(where `<N>` is an integer between 1 and 9) ... are installed into the
`man<N>/` installation locations." Only `man` and `man1` are implemented
(`libbuild2/target.hxx`, `libbuild2/install/init.cxx`). Writing `man3{foo}`
in a buildfile fails with "unknown target type man3", and there is no
`config.install.man2` (etc.) variable and no per-section default location.

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
