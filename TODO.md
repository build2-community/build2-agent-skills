# TODO

Open documentation gaps discovered while using this reference during real
packaging work, not yet resolved into a proper guide/HOWTO entry.

## Documentation gaps

### Embed a Windows `.rc` resource (VERSIONINFO and similar)

**File:** new `HOWTO/windows-resource-file.md` (nothing covers this yet), and a line in `INDEX.md`. Found while packaging `libgpuopen-devdriverapi`, whose upstream CMake lists `Windows/DevDriverAPI.rc`.

**Motivation:** build2 does not link `.res` files. `using cxx` only loads the `bin.rc` module for MinGW (to compile manifests with `windres`). On `win32-msvc` it loads `bin.ld` instead, so `$bin.rc.path` is unset unless the package loads the module itself. `objs{}` has no default extension, so a declaration without one does not produce a usable object name.

The `winres` rule in [build2-packaging/FFmpeg](https://github.com/build2-packaging/FFmpeg/blob/f4229e0b1a6aa3dc3b335c471783fc8c1971dfa3/libavutil/build/conditional-src.build#L291-L335) only runs `rc.exe` to a `.res` via `import rc = rc%exe{rc}`, never converts that `.res` to an object, and FFmpeg leaves the consumers commented out because the PATH import cannot find `rc.exe` on CI.

**Suggested fix:** Document this recipe:

1. Symlink the upstream directory that contains the `.rc` (and `resource.h`, if any) and add `symlink=dir` in `.gitattributes`.
2. `define rc: file` with `rc{*}: extension = rc`. List `rc{...}` as an `include = adhoc` prerequisite of `lib{}` so `b dist` from Linux still ships the file.
3. Load the module on Windows: `if ($cxx.target.class == 'windows') using bin.rc`. Then `$bin.rc.path` comes from `config.bin.rc` (default `rc` on `win32-msvc`, `windres` otherwise). Do not `import rc%exe{rc}` (PATH search, fails on CI).
4. Locate `cvtres` next to `$bin.ld.path` and pick the machine from `$cxx.target.cpu` (`X64`, `ARM64`, `X86`). `if $windows` is appropriate for locating these tools.
5. Declare `objs{name.obj}` (the extension must be provided on declaration) from the `rc{}` plus any headers the `.rc` includes. The recipe writes an intermediate `.res` under `$~` (the ad hoc recipe temporary directory), then `cvtres` writes the object.
6. Attach with `libs{...}: objs{name}: include = $windows`. After the `.obj` declaration, the prerequisite name is `objs{name}` without repeating the extension.
7. Do not wrap those prerequisites in `if`. Use `: include = $windows`.

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
