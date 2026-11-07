# Embed a Windows Resource File

A Windows DLL often carries a `.rc` resource script, typically a
`VERSIONINFO` block that Explorer shows under file properties. build2 has
no rule that turns a `.rc` file into something the MSVC link rule will
link. The link rule only puts object and library targets on the linker
command line (`libbuild2/cc/link-rule.cxx`), so a `.res` file listed as a
prerequisite is updated but never linked.

The working approach is an ad hoc recipe that runs `rc.exe` to produce a
`.res`, then `cvtres.exe` to convert it to a COFF object, declared as an
`objs{}` target that the link rule links like any other object. This
HOWTO covers `win32-msvc` targets linked with `link.exe` (cl, clang-cl,
or clang++ targeting the MSVC ABI).

## What build2 provides

- **No resource compiler on MSVC by default.** The `cc` core module
  (`libbuild2/cc/init.cxx`) loads `bin.ld` for `win32-msvc` and loads
  `bin.rc` only for `mingw32`, where `windres` embeds manifests. On MSVC,
  manifests go straight to `link.exe` (`/MANIFESTINPUT`), so
  `$bin.rc.path` is unset unless the project loads `bin.rc` itself.
- **`using bin.rc` must come after `using cxx`.** `bin.rc` loads
  `bin.config`, which needs a target hint from `c` or `cxx` and otherwise
  fails with `unable to determine binutils target`. It reads
  `config.bin.rc`, whose default is `rc` on `win32-msvc` and `windres`
  otherwise (`libbuild2/bin/init.cxx`). It sets `bin.rc.path`,
  `bin.rc.id` (`msvc`, `msvc-llvm`, or `gnu`), `bin.rc.signature`, and
  `bin.rc.checksum`. When build2 detects MSVC itself (no developer
  prompt), the tool search path includes the Windows SDK `bin` directory,
  so plain `rc` is found.
- **No `rc{}` target type.** Define one with `define rc: file` and give it
  the extension.
- **`objs{}` has no default extension** (`libbuild2/bin/target.cxx`). The
  compile rule supplies one for the objects it builds (`foo.dll.obj`). An
  ad hoc recipe on an extensionless `objs{name}` fails with
  `no default extension for target`. Declare the target as
  `objs{name.obj}`. A later `objs{name}` without the extension finds the
  same target, because an unspecified extension matches a specified one.
  Do not set `objs{*}: extension = obj` instead. That also renames every
  object the compile rule builds.
- **The linker path.** `bin.ld` sets `bin.ld.path` and `bin.ld.id`
  (`msvc` for `link.exe`, `msvc-lld` for `lld-link`). `cvtres.exe` ships
  next to `link.exe` in the MSVC tools directory.

## Recipe

1. **Ship the `.rc` source.** The `.rc` (and any `resource.h` it
   includes) usually lives in the upstream tree. Symlink the directory
   that contains it into the package and add a `symlink=dir` entry for it
   to the package's `.gitattributes` (see
   [packaging-guide-summary.md](../guides/packaging-guide-summary.md#packaging-workflow-checklist)).

2. **Load `bin.rc` on MSVC**, in `build/root.build` after `using cxx`:
   ```
   using cxx

   ...

   if ($cxx.target.system == 'win32-msvc')
     using bin.rc
   ```
   Condition on `win32-msvc`, not on `$cxx.target.class == 'windows'`.
   The `cvtres` step below is MSVC-only, and on MinGW `cc` already loads
   `bin.rc` with `windres`.

3. **Find `cvtres` and the machine type**, in the library's buildfile:
   ```
   embed_rc = ($cxx.target.system == 'win32-msvc' && $bin.ld.id == 'msvc')

   if $embed_rc
   {
     cvtres = $directory($effect($bin.ld.path))/cvtres

     if ($cxx.target.cpu == 'x86_64')
       cvtres_machine = X64
     elif ($cxx.target.cpu == 'aarch64')
       cvtres_machine = ARM64
     else
       cvtres_machine = X86
   }
   ```
   - `$bin.ld.path` may record only `link` as its recall path. `$effect()`
     returns the absolute path (`libbuild2/functions-process-path.cxx`)
     and `$directory()` strips the file name.
   - `lld-link` (`config.bin.ld=lld-link`, id `msvc-lld`) has no `cvtres`
     next to it. `embed_rc` is false there and the resource is skipped.
   - `$cxx.target.cpu` holds the target triplet CPU (`x86_64`, `aarch64`,
     `i386`, `i686`), not the `cvtres` machine name. The mapping matches
     the one build2 uses for `/MACHINE` (`msvc_machine()`,
     `libbuild2/cc/msvc.cxx`).
   - An `if` around variable assignments is fine. Only dependency
     declarations must avoid it (step 7).

4. **Declare the object with its recipe:**
   ```
   define rc: file
   rc{*}: extension = rc

   objs{hello-res.obj}: rc{windows/hello} file{windows/resource.h}
   {{
     diag rc ($<[0])

     $bin.rc.path /nologo /fo $~/hello.res $path($<[0]) &$~/hello.res
     $cvtres /nologo /machine:$cvtres_machine "/out:$path($>)" $~/hello.res
   }}
   ```
   - `$~` is the recipe's temporary directory. The buildscript runner
     fails with `temporary directory '...' is not empty`
     (`libbuild2/build/script/runner.cxx`) if anything is left in it, and
     files written by an external program are not registered for cleanup
     automatically. `&$~/hello.res` registers the `.res` that `rc.exe`
     writes.
   - List every header the `.rc` includes as a prerequisite. `rc.exe`
     reports no dependencies to build2, so these prerequisites are what
     trigger a rebuild when the headers change.
   - System headers are not on `rc.exe`'s include path. When `INCLUDE` is
     not set in the environment (build2 detected MSVC itself), build2
     passes the MSVC and Windows SDK header directories to `cl.exe` as
     `/I` options (`append_sys_hdr_options()`,
     `libbuild2/cc/compile-rule.cxx`). `rc.exe` started from the recipe
     gets neither. If the `.rc` includes `<winver.h>` or `<windows.h>`,
     pass each `$cxx.sys_hdr_dirs` entry to `rc.exe` with `/I`. The
     ATL/MFC include directory, which holds `winres.h`, is not in that
     list (`msvc_hdr()`, `libbuild2/cc/guess.cxx`).
   - The `{{ }}` block must follow the plain declaration (see
     [ad-hoc-recipe.md](./ad-hoc-recipe.md#attachment-grammar)).

5. **Link it into the DLL** as a prerequisite of `libs{}`:
   ```
   libs{hello}: objs{hello-res}: include = $embed_rc
   ```
   - It must be `libs{}`. The link rule fails with
     `objs{} as prerequisite of <target>` when the static member sees an
     `objs{}` (`libbuild2/cc/link-rule.cxx`), and prerequisites of the
     `lib{}` group are seen by both members.
   - Pick a base name that no `c{}`/`cxx{}` source in the same directory
     uses (here `hello-res`). The object the link rule synthesizes for
     `cxx{hello}` is `objs{hello}`, which would resolve to a resource
     target named `objs{hello.obj}`.

6. **List the `.rc` on `lib{}` for `dist`:**
   ```
   lib{hello}: rc{windows/hello}: include = adhoc
   ```
   `b dist` already reaches `rc{}` through `libs{}` and `objs{}`: bin's
   `lib_rule` matches both members for `dist`, and `dist_include()`
   (`libbuild2/dist/operation.cxx`) keeps the excluded `objs{}`
   prerequisite. Listing it on `lib{}` as well keeps it in an archive made
   on a non-Windows host regardless of how that chain is conditioned.

7. **Keep the graph unconditional.** Do not wrap the `objs{}`
   declaration or the `libs{}` prerequisite in `if`. Use `include =` as
   above. An `if`-wrapped dependency declaration triggers the `dist`
   warning and can leave the `.rc` out of an archive made on another
   platform (see
   [config-independent-build-graph.md](./config-independent-build-graph.md)).

## What not to use

- **`import rc = rc%exe{rc}` with a rule that stops at `.res`.** The
  import searches `PATH`, which fails where `rc.exe` is not on it (for
  example a CI machine where build2 detects MSVC itself), and the link
  rule never passes a `.res` to the linker. The `winres` rule in
  [build2-packaging/FFmpeg](https://github.com/build2-packaging/FFmpeg/blob/f4229e0b1a6aa3dc3b335c471783fc8c1971dfa3/libavutil/build/conditional-src.build#L291-L335)
  has both problems, and its consumers are left commented out.
- **`$windows`.** It is not a build2 builtin. Spell the condition out or
  define the variable yourself.
- **An extensionless `objs{}` declaration, or `objs{*}: extension = obj`.**
  See [What build2 provides](#what-build2-provides).
- **`$cxx.target.cpu` passed straight to `cvtres`.** It holds `x86_64`,
  not `X64`.

## MinGW

On `mingw32`, `cc` already loads `bin.rc` with `windres`, which can write
a COFF object directly. build2 itself runs it that way for manifests
(`--input-format=rc --output-format=coff`, `libbuild2/cc/link-rule.cxx`),
so no `cvtres` step is needed. This HOWTO does not cover that variant.

## See Also

- [ad-hoc-recipe.md](./ad-hoc-recipe.md): attachment grammar, `diag`,
  `$<` and `$>`
- [link-system-library.md](./link-system-library.md): Windows system
  libraries, including names missing from the pkg-config allowlist
- [config-independent-build-graph.md](./config-independent-build-graph.md):
  `include = (condition)` instead of `if` around a declaration
- [build2-modules-bin.md](../guides/build2-modules-bin.md): `objs{}` and
  the `lib{}` member types
- [cross-compilation.md](./cross-compilation.md#cpu-architecture-matching-with-cxxtargetcpu):
  `$cxx.target.cpu` values
- [packaging-guide-summary.md](../guides/packaging-guide-summary.md#packaging-workflow-checklist):
  upstream symlinks and `symlink=dir`
