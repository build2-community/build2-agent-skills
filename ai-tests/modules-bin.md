# Tests: modules-bin -- binary target types

Source documentation: `guides/build2-modules-bin.md`, `guides/build2-projects-advanced.md`


## T001 -- Object file target types

**Query:** What are the distinct object file target types in build2 and what is each used for?

**Key facts** (all must appear in a correct answer):
- `obje{}` -- object file for linking into an executable.
- `obja{}` -- object file for linking into a static library.
- `objs{}` -- object file for linking into a shared library.
- `obj{}` -- group that selects the appropriate member automatically.

**Source:** `guides/build2-modules-bin.md`


## T002 -- Utility library target types

**Query:** What are the utility library target types in build2 and what is each used for?

**Key facts** (all must appear in a correct answer):
- `libue{}` -- object files suitable for linking into an executable.
- `libua{}` -- object files suitable for linking into a static library.
- `libus{}` -- object files suitable for linking into a shared library.
- `libul{}` -- group with `libua{}` and/or `libus{}` members; the correct member is selected automatically when encountered as a prerequisite.

**Source:** `guides/build2-modules-bin.md`


## T003 -- C++20 BMI target types

**Query:** What are the BMI target types for C++20 named modules and for header units?

**Key facts** (all must appear in a correct answer):
- `bmie{}` -- BMI for linking into an executable.
- `bmia{}` -- BMI for linking into a static library.
- `bmis{}` -- BMI for linking into a shared library.
- `bmi{}` -- group that selects the appropriate member automatically.
- `hbmie{}`, `hbmia{}`, `hbmis{}`, `hbmi{}` -- corresponding types for C++20 header units, following the same pattern as `bmi*{}`.

**Source:** `guides/build2-modules-bin.md`


## T004 -- bin.lib configuration

**Query:** What are the valid values for `config.bin.lib` and which is the default?

**Key facts** (all must appear in a correct answer):
- `shared` -- build only shared libraries.
- `static` -- build only static libraries.
- `both` -- build both shared and static libraries.
- `both` is the default.

**Source:** `guides/build2-projects-advanced.md`


## T005 -- Shared library versioning

**Query:** What variable controls shared library versioning and what is its value format?

**Key facts** (all must appear in a correct answer):
- The variable is `bin.lib.version`, set on the `lib{}` target.
- The value is a version suffix string, for example `"-$version.major.$version.minor"`.
- Platform-specific versions can be appended, for example `linux@3`.

**Source:** `guides/build2-projects-advanced.md`
