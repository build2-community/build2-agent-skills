# Ad Hoc Pattern Rules: What Actually Gets Auto-Added

An ad hoc pattern rule (`type{~'/regex/'}: ...` or, for several related
targets, `<type1{~'/regex/'} type2{^'/subst/'}>: ...`) lets one recipe body
serve every real target declaration whose name matches the pattern. The
feature is documented only in `build2/NEWS`, under "Support for ad hoc
regex pattern rules" -- there is no manual section, and its one worked
example uses the more complex group form. This entry covers two things
that example does not make obvious.

## Delimiter and flags

The delimiter for a `~`/`^` pattern is whichever character immediately
follows it (`char d (val[1])` in `parser.cxx`, found via `val.rfind(d)`),
not a fixed `/`. If the replacement text needs to contain a literal `/`
(for example a directory prefix), escaping it does not work, since
`rfind` just finds the *last* literal occurrence of the delimiter
character. Pick a different delimiter instead:

```
file{^'%man/\1.in%'}
```

An optional `i` (case-insensitive) or `e` (match the extension as part of
the name, instead of the default of comparing without it) flag letter can
follow the closing delimiter.

## Single-target form: don't mix a fixed prerequisite with a substitution

```
man{~'/(.*)/'}: file{^'%\1.in%'} file{postlude}
{{
  echo $path($<[0])
  echo $path($<[1])
}}

man{a.7}: file{a.7.in}
```

Here `file{^'%\1.in%'}` is a substitution (computed from the match) and
`file{postlude}` is a plain, fixed prerequisite -- no `~`/`^` marker at
all. Reproducibly (fresh project, current toolchain), `$<[1]` does **not**
resolve to `file{postlude}`. It silently duplicates `$<[0]`: both print
the same path, the substituted `a.7.in`. This is not a missing-prerequisite
error you'd notice -- the recipe runs and produces output, just from the
wrong input, with no diagnostic.

**Safe pattern:** write every real prerequisite -- substituted and fixed
alike -- explicitly in each per-target declaration, and don't lean on the
rule to contribute anything beyond the substitution it's already
computing from the match:

```
man{~'/(.*)/'}: file{^'%\1.in%'} file{postlude}
{{
  cat $path($<[0]) $path($<[1]) >$path($>)
}}

man{a.7}: file{a.7.in} file{postlude}
man{b.3}: file{b.3.in} file{postlude}
```

With the fixed prerequisite restated on the real declaration, `$<[1]`
resolves correctly and the shared recipe runs as expected for every
matching target.

## Group form: the auto-add claim needs an explicit group on the real declaration too

NEWS's worked example is the ad hoc *group* form, where the left side
names more than one target:

```
<exe{~'/(.*)/'} file{^'/\1.map/'}>: cxx{~'/\1/'} hxx{^'/\1/'} hxx{common}
{{
  $cxx.path -o $path($>[0]) "-Wl,-Map=$path($>[1])" $path($<[0])
}}
```

and claims that a plain, real declaration `exe{hello}: cxx{hello}` is
enough: the rule fills in the group member `file{hello.map}` and the
prerequisites `hxx{hello}`/`hxx{common}` on its own.

This does not happen. `adhoc_rule_regex_pattern::match()` requires every
additional group member (here, `file{hello.map}`) to already exist as an
ad hoc member of the target *before* the rule can match at all -- it looks
it up (`find_adhoc_member`), it does not create it. A bare
`exe{hello}: cxx{hello}` with no group written anywhere fails outright:

```
error: no rule to update exe{hello}
```

not a partial or best-effort build. The rule simply never matches.

**What does work:** write the ad hoc group explicitly on the real
per-target declaration too:

```
<exe{hello} file{hello.map}>: cxx{hello}
```

With the group spelled out, `find_adhoc_member` succeeds, the rule
matches, and -- unlike the single-target case above -- both the
substituted prerequisite and a fixed, non-pattern one (`hxx{common}`-style)
resolve correctly in `apply_prerequisites()`. The group form's auto-add is
real, but only for filling in prerequisites and the *already-declared*
group members' substitutions; it does not spare you from writing the
group itself on every matching real target.

## Practical takeaway

Regardless of form, never rely on a pattern rule to conjure a target or a
fixed prerequisite that isn't already spelled out somewhere concrete:

- Single-target pattern: restate every prerequisite (substituted and
  fixed) on each real declaration.
- Group pattern: restate the full `<...>` group on each real declaration;
  only then are prerequisite substitutions and fixed prerequisites
  reliable.

## See Also

- [ad-hoc-recipe.md](./ad-hoc-recipe.md): the `{{ }}` recipe body itself,
  attachment grammar, unrelated to pattern *matching*
- [man-pages-install.md](./man-pages-install.md): a real use case for a
  shared per-section recipe body (one pattern rule, several `man{}`
  declarations)
