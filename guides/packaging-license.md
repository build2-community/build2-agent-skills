# Package Manifest: `license` Field

The `license` manifest field declares the license(s) under which a package is
distributed. It is a required field and, together with `name`, `version`, and
`summary`, constitutes the manifest header -- the minimal valid manifest.

For authoritative upstream detail see the
[bpkg package manager manual](https://build2.org/bpkg/doc/build2-package-manager-manual.xhtml#manifest-package-license).


## Field Synopsis

```
license: <licenses> [; <comment>]

<licenses> = <license> [, <license>]*
<license>  = [<scheme>:] <name>
<scheme>   = other
```

The value may carry an optional inline comment after `;`. That comment is part
of the value, not a manifest `#`-comment, so it is preserved in the binary
manifest and displayed to users. It must be one or more full sentences
(capital letter, ends with a period).

A non-comment semicolon appearing in a field that supports the comment syntax
must be escaped with `\`.


## SPDX License Expressions (Default Scheme)

The default license name scheme is the
[SPDX License Expression](https://spdx.org/licenses/). In its simplest form it
is just the SPDX identifier for the license:

```
license: MIT
```

Adding a comment with the full license name is common and improves readability
for less-familiar identifiers:

```
license: MPL-2.0 ; Mozilla Public License 2.0.
```

The following table lists the most commonly used free/open source licenses and
their SPDX identifiers:

```
MIT                ; MIT License.

BSD-2-Clause       ; BSD 2-Clause "Simplified" License.
BSD-3-Clause       ; BSD 3-Clause "New" or "Revised" License.
BSD-4-Clause       ; BSD 4-Clause "Original" or "Old" License.

GPL-2.0-only       ; GNU General Public License v2.0 only.
GPL-2.0-or-later   ; GNU General Public License v2.0 or later.
GPL-3.0-only       ; GNU General Public License v3.0 only.
GPL-3.0-or-later   ; GNU General Public License v3.0 or later.

LGPL-2.0-only      ; GNU Library General Public License v2 only.
LGPL-2.0-or-later  ; GNU Library General Public License v2 or later.
LGPL-2.1-only      ; GNU Lesser General Public License v2.1 only.
LGPL-2.1-or-later  ; GNU Lesser General Public License v2.1 or later.
LGPL-3.0-only      ; GNU Lesser General Public License v3.0 only.
LGPL-3.0-or-later  ; GNU Lesser General Public License v3.0 or later.

AGPL-3.0-only      ; GNU Affero General Public License v3.0 only.
AGPL-3.0-or-later  ; GNU Affero General Public License v3.0 or later.

Apache-1.0         ; Apache License 1.0.
Apache-1.1         ; Apache License 1.1.
Apache-2.0         ; Apache License 2.0.

MPL-1.0            ; Mozilla Public License 1.0.
MPL-1.1            ; Mozilla Public License 1.1.
MPL-2.0            ; Mozilla Public License 2.0.

BSL-1.0            ; Boost Software License 1.0.

Unlicense          ; The Unlicense (public domain).
```

For the complete SPDX registry see https://spdx.org/licenses/.


## The `other:` Scheme

The `other:` scheme covers licenses that are not defined by SPDX. Names in
this scheme are free-form with case-insensitive comparison. The following
names have predefined meaning:

```
other: public domain    ; Released into the public domain.
other: available source ; Not free/open source with public source code.
other: proprietary      ; Not free/open source.
other: TODO             ; License is not yet decided.
```

For new public-domain projects, the SPDX `Unlicense` identifier is preferred
over `other: public domain` because it maps to a specific well-understood
license text.

Free-form names are also accepted for anything outside the predefined list:

```
license: other: MIT with extra attribution requirements
```


## Multiple Licenses: AND and OR Semantics

### AND -- all licenses apply simultaneously

A single `license:` value may contain a comma-separated list of license names.
The list has AND semantics: the user must comply with every license listed.

```
license: MIT, BSD-2-Clause
```

The comma form is the only way to combine names from different schemes (SPDX
and `other:`) in a single value:

```
license: GPL-2.0-only, other: available source
```

For names that belong to the same scheme, the SPDX `AND` operator inside the
value is an equivalent alternative:

```
license: MIT AND BSD-2-Clause
```

### OR -- alternative licensing options

Multiple `license:` values in the manifest have OR semantics: the user may
choose to comply with any one of them.

```
license: Apache-2.0
license: MIT
```

The SPDX `OR` operator inside a single value is an equivalent alternative when
all alternatives are SPDX names:

```
license: Apache-2.0 OR MIT
```

### Complex example with per-scenario comments

When the applicable license depends on how the package is used, explanatory
comments are strongly recommended:

```
license: LGPL-2.1-only AND MIT ; If linking with GNU TLS.
license: BSD-3-Clause          ; If linking with OpenSSL.
```

This expresses two alternative scenarios (OR between the two `license:` lines),
where the first scenario requires compliance with both LGPL-2.1-only and MIT
(AND within the first line).

**Note on `bdep new` auto-detection.** When `bdep new` creates a package
inside a directory that already contains a `LICENSE` file (or `LICENSE.txt`,
`LICENSE.md`, `COPYING`, `UNLICENSE`), it attempts to detect and set the
`license` field automatically. It will detect at most one license. When the
upstream project is dual- or multi-licensed, the additional license names must
be added manually after generation.


## Custom and Reference Licenses

The SPDX LicenseRef mechanism covers non-standard licenses while remaining
within SPDX syntax:

```
license: LicenseRef-My-MIT-Like ; Custom MIT-alike license.
```

The `other:` free-form name is the fallback for anything that cannot be
expressed in SPDX at all:

```
license: other: MIT with extra attribution requirements
```


## Deprecated Legacy Names

For backwards compatibility the following scheme-less names are recognised as
aliases for their SPDX equivalents. New manifests must use the SPDX form.

```
BSD2      ->  BSD-2-Clause
BSD3      ->  BSD-3-Clause
BSD4      ->  BSD-4-Clause
GPLv2     ->  GPL-2.0-only
GPLv3     ->  GPL-3.0-only
LGPLv2    ->  LGPL-2.0-only
LGPLv2.1  ->  LGPL-2.1-only
LGPLv3    ->  LGPL-3.0-only
AGPLv3    ->  AGPL-3.0-only
ASLv1     ->  Apache-1.0
ASLv1.1   ->  Apache-1.1
ASLv2     ->  Apache-2.0
MPLv2     ->  MPL-2.0

public domain      ->  other: public domain
available source   ->  other: available source
proprietary        ->  other: proprietary
TODO               ->  other: TODO
```


## See Also

- [bpkg manifest reference](../bpkg/bpkg-manifest-reference.md) -- full field table for all manifest fields
- [packaging guide: setup through installation](packaging-guide-summary.md) -- step-by-step packaging workflow
- [packaging guide: review checklist](packaging-guide-review.md) -- review criteria for the `license` field
- [bdep-new](../bdep/bdep-new.md) -- `license=<name>` sub-option and auto-detection from `LICENSE` file
