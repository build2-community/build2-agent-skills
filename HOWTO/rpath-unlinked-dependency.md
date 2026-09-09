# Rpath for a Dependency You Never Link

A shared library that the consumer only `dlopen`s at runtime (to avoid a
symbol collision, or because it is a plugin) must still be built and must
still be findable via rpath. Marking it `include = adhoc` does the first
and silently skips the second.

## The rule

An `include = adhoc` prerequisite is updated so the file exists, but it
never becomes a live link prerequisite. The link rule's rpath walk
(`rpath_libraries()`) only sees `liba{}` / `libux{}` / `libs{}` entries in
`prerequisite_targets` from the normal (non-adhoc) pass. An adhoc-only
dependency therefore contributes no rpath entry, regardless of how it was
imported.

Neither of these changes that:

```
import foo = libfoo%lib{foo}
import! [metadata, rule_hint=cxx.link] foo = libfoo%lib{foo}
```

`rule_hint=cxx.link` nominates the link rule while *that* target is
resolved at import time. It does not change how the consumer's already
matched `cxx.link` rule treats one of its own prerequisites. Putting
`rule_hint=cxx.link` on the adhoc prerequisite of `exe{driver}` parses
and has no effect on the binary's rpath.

Windows does not support `bin.rpath`. The link rule fails if that variable
is non-empty on a Windows target.

## The fix: `bin.rpath` from an always-absolute metadata path

Export a dedicated `dir_path` that is absolute in both the development
build and the installed `.pc` file. Query the *plain* variable in the
consumer (the `.for_install` value is what gets written to `.pc`, so an
installed consumer already sees the resolved path through the plain name).

Library:

```
lib{foo}:
{
  export.metadata = 1 libfoo

  libfoo.rpath = [dir_path] $out_base/
  libfoo.rpath.for_install = ($install.root != [null] \
    ? $install.resolve([dir_path] lib/) \
    : )
}
```

`$install.resolve(...)` produces an absolute directory. Do not export a
path that is relative to `install.root` (or to the current working
directory) as the rpath value.

Consumer:

```
import! [metadata, rule_hint=cxx.link] foo = libfoo%lib{foo}

exe{driver}: cxx{driver}
exe{driver}: $foo: include = adhoc
exe{driver}: bin.rpath += $($foo: libfoo.rpath)
```

Append with `+=`, the same as `cxx.poptions` and other config-backed lists.
The bin module merges `config.bin.rpath` into the root-scope `bin.rpath`
value. A target-specific `=` replaces that list, so a user or CI
`config.bin.rpath` (and any earlier `bin.rpath +=` in the project) would
disappear from this target. Automatic rpath for *linked* libraries is a
separate walk (`bin.rpath.auto`). It is not stored in this variable, so
`=` does not turn that off, but it still drops everything that *is* in
the variable.

`bin.rpath` is a list of directories. The link rule embeds them as
`-Wl,-rpath,...`. Only absolute entries are rewritten to `$ORIGIN` /
`@loader_path` for a relocatable install. A relative entry is copied into
the binary as-is and becomes cwd-relative at runtime: the build succeeds,
`otool -l` / `readelf -d` shows an rpath, and loading still fails unless
you happen to run from the right directory.

Do not query `$($foo: libfoo.rpath.for_install)` in the consumer. That
name is the in-tree *source* of the `.pc` value, and if it is empty or
relative you get the silent cwd-relative failure above. Query
`libfoo.rpath`.

## What not to use

`$cxx.lib_rpaths()` (and `$c.lib_rpaths()`) exist to hand-roll a *link*
recipe. They are not a way to add rpath to a target that still uses the
stock link rule. See [ad-hoc-recipe.md](./ad-hoc-recipe.md). For a
dlopen-only dependency, `bin.rpath` is the mechanism.

Automatic rpath (`bin.rpath.auto`, on by default) only walks linked
libraries. Turning it on or off does not make adhoc prerequisites
visible.

## See Also

- [target-metadata.md](./target-metadata.md): metadata protocol and
  `.for_install` values written to `.pc`
- [import-immediate-vs-ordinary.md](./import-immediate-vs-ordinary.md):
  rpath of *linked* libraries is a consumer link-rule effect
- [ad-hoc-recipe.md](./ad-hoc-recipe.md): recipe attachment grammar, and
  why `$cxx.lib_rpaths()` is the wrong tool here
- [local-installed-import.md](./local-installed-import.md): verify the
  installed consumer actually sees the metadata path
