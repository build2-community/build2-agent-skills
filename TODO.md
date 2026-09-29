# TODO

Open documentation gaps discovered while using this reference during real
packaging work, not yet resolved into a proper guide/HOWTO entry.

Nothing open right now. The man-pages install gap and the ad hoc pattern
rule gap that used to be tracked here were resolved into
[HOWTO/man-pages-install.md](HOWTO/man-pages-install.md),
[HOWTO/ad-hoc-pattern-rule.md](HOWTO/ad-hoc-pattern-rule.md), and a
correction to the install-module table in
[guides/build2-modules-core.md](guides/build2-modules-core.md).

## Suggested upstream build2 patches

Not documentation gaps — concrete bugs found in build2 itself while using
this reference, staged here (rather than in the skill docs) because this
repo carries the vendored build2 source (`.submodules/build2`) needed to
verify against. Intended to become patches proposed to a fork of
https://github.com/build2/build2.

### bin::def_rule misclassifies COFF symbols with no compiler-supplied type tag as DATA

**File:** `libbuild2/bin/def-rule.cxx`, `read_dumpbin()` (~lines 35-199).

**Motivation:** `def_rule` decides function-vs-data purely from whether
`dumpbin -symbols` shows `notype ()` vs plain `notype` — the `()` comes
from a COFF complex-type field only the *compiler* sets (see the comment
at def-rule.cxx:56-59). This field is only set by compilers that bother to
tag it. NASM's Win32/Win64 COFF backend never sets it, for any symbol,
under any syntax (confirmed against NASM 2.16.3's `coff_deflabel` in
`output/outcoff.c`: any attempt to pass a type qualifier via
`global sym:function` hard-errors with "COFF format does not support any
special symbol types" — no NASM-side workaround exists).

Consequently, any NASM-defined function that is a legitimate part of a
Windows DLL's public export surface gets misclassified as `DATA` in the
`def{}`-generated `.def` (`... DATA` in the EXPORTS section). A
`DATA`-marked MSVC import isn't reachable through the ordinary function
call-thunk the import library would otherwise generate, so a consumer
calling it as a plain function fails to link with a confusing "unresolved
external symbol" (LNK2019), not a data/function mismatch. Reproduced
concretely with FFmpeg's `avpriv_emms_asm` (NASM-defined, exported from
`avutil.dll`, called as an ordinary function by consumers).

**Suggested fix:** `read_dumpbin()` already builds a `secs` map from
section name to a type char ('R' for `.rdata`/`.xdata`, 'B' for `.bss`,
recognized via the section-defining symbol at offset 0 —
def-rule.cxx:151-169) and uses it to bucket `dat == true` symbols by
section (def-rule.cxx:176-187). Extend this the same way for code
sections: recognize `.text` (and its `$`-suffixed COMDAT variants — the
existing `cmp` helper already handles the `$` case) the same way
`.rdata`/`.bss` are recognized, mapping to a new type char (e.g. 'T').
Then in the bucketing switch, a symbol whose section resolves to 'T'
should go into `syms.t` (function) unconditionally, regardless of the
`dat` flag from the SYMTYPE/`()` column. This derives function-ness from
where the symbol is actually defined (an executable section) as a
fallback when the compiler-supplied type tag is absent, instead of relying
solely on a signal some valid toolchains (NASM, possibly others) never
provide. `read_nm()` likely needs the equivalent treatment for parity on
MinGW/lld-link, though nm's output conventions differ — needs separate
verification.
