# build2 Functions Reference

Functions in build2 are organized into families such as `$string.*()` for string
manipulation or `$regex.*()` for regular expressions. This document covers the
fourteen builtin function families extracted from the libbuild2 source, plus
the C/C++ module functions (`$c.lib_*()`, `$cxx.lib_*()`) used from ad hoc
recipes.

## General rules

**Qualification.** Every function can always be called with its full
`$family.name()` form. Most families also allow unqualified calls when the
argument type makes the family unambiguous. The `$regex.*()` family is the
exception: all its functions must always be qualified.

**Impure functions.** Functions marked "not pure" read the environment, the
filesystem, or run external processes. They must be declared with
`config.environment` if their result can affect the build. In an ad hoc
recipe the restriction is different: impure calls are only allowed in the
depdb preamble (see [ad-hoc-recipe.md](../HOWTO/ad-hoc-recipe.md)).

**Optional arguments** are shown in square brackets: `[, <arg>]`.

**Flags** are passed as an additional untyped list argument and control
behavior -- for example, `$string.sort($x, icase dedup)`.

## Family overview

| Family | Purpose | Unqualified calls |
|---|---|---|
| `$builtin.*()` | Fundamental build2 operations | optional |
| `$string.*()` | String manipulation | optional |
| `$integer.*()` | Integer arithmetic | optional |
| `$bool.*()` | Boolean conversion | optional |
| `$path.*()` | Filesystem path operations | optional |
| `$name.*()` | Target and prerequisite names | optional |
| `$target.*()` | Operations on actual targets | optional |
| `$regex.*()` | ECMAScript regex match and substitution | **required** |
| `$json.*()` | JSON, JSON5, and JSON5E values | optional |
| `$process.*()` | Process execution | optional |
| `$filesystem.*()` | Filesystem queries | optional |
| `$project_name.*()` | `project_name` type | optional |
| `$process_path.*()` | `process_path` and `process_path_ex` types | optional |
| `$target_triplet.*()` | `cpu-vendor-os` target triplet | optional |
| `$c.lib_*()` / `$cxx.lib_*()` | Interface options, libs, and rpaths for ad hoc recipes | required |


## $builtin.*() -- fundamental functions

| Function | Description |
|---|---|
| `$defined(<var>)` | Return `true` if the variable is defined in this scope or any outer scope. Not pure. |
| `$visibility(<var>)` | Return the variable visibility string (`global`, `project`, `scope`, `target`, `prereq`) or `null`. Not pure. |
| `$type(<val>)` | Return the type name of a value as a string, or empty string if untyped. |
| `$null(<val>)` | Return `true` if the value is `null`. |
| `$empty(<val>)` | Return `true` if the value is `null` or an empty list. |
| `$first(<val> [, <not_pair>])` | Return the first half of a pair. Return `null` if not a pair unless `<not_pair>` is `true`. |
| `$second(<val> [, <not_pair>])` | Return the second half of a pair. Return `null` if not a pair unless `<not_pair>` is `true`. |
| `$quote(<val> [, <escape>])` | Return the string representation of a value. If `<escape>` is `true`, also escape the added quote characters. |
| `$getenv(<name>)` | Return the value of an environment variable, or `null`. Not pure. |
| `$generate_uuid()` | Generate a UUID and return its string representation. Not pure. |
| `$sha256sum(<str>)` | Return the SHA256 checksum of a string. |
| `$xxh64sum(<str>)` | Return the XXH64 checksum of a string (faster but non-cryptographic). |


## $string.*() -- string manipulation

Unless noted, these accept a typed `string` argument or untyped names.

| Function | Description |
|---|---|
| `$icasecmp(<str>, <str>)` | Return `true` if the two ASCII strings are equal ignoring case. |
| `$contains(<str>, <substr> [, <flags>])` | Return `true` if `<str>` contains `<substr>`. Flags: `icase`, `once`. |
| `$starts_with(<str>, <prefix> [, <flags>])` | Return `true` if `<str>` begins with `<prefix>`. Flags: `icase`. |
| `$ends_with(<str>, <suffix> [, <flags>])` | Return `true` if `<str>` ends with `<suffix>`. Flags: `icase`. |
| `$compare(<str>, <str> [, <flags>])` | Compare strings; return `-1`, `0`, or `1`. Flags: `icase`, `contains`, `contains_once`, `starts_with`, `ends_with`. |
| `$replace(<str>, <from>, <to> [, <flags>])` | Replace occurrences of `<from>` with `<to>`. Flags: `icase`, `first_only`, `last_only`. |
| `$trim(<str>)` | Return string with leading and trailing whitespace removed. |
| `$lcase(<str>)` | Return string converted to lower case (ASCII). |
| `$ucase(<str>)` | Return string converted to upper case (ASCII). |
| `$size(<strings>)` | Return the number of elements in a string sequence or the number of characters in a single string. |
| `$front(<strings>)` | Return the first string in the sequence. |
| `$back(<strings>)` | Return the last string in the sequence. |
| `$sort(<strings> [, <flags>])` | Sort strings in ascending order. Flags: `icase`, `dedup`. |
| `$find(<strings>, <str> [, <flags>])` | Return `true` if any element satisfies `$compare`. Flags: same as `$compare`. |
| `$find_index(<strings>, <str> [, <flags>])` | Return the index of the first match or `$size(<strings>)`. |
| `$filter(<strings>, <str> [, <flags>])` | Return elements for which `$compare` returns `0`. |
| `$filter_out(<strings>, <str> [, <flags>])` | Return elements for which `$compare` returns non-`0`. |
| `$keys(<string-map>)` | Return the sorted list of keys in a `string_map`. |


## $integer.*() -- integer operations

| Function | Description |
|---|---|
| `$string(<int> [, <base> [, <width>]])` | Convert an integer to a string. `<base>` is `10`, `16`, etc. `<width>` zero-pads. |
| `$integer_sequence(<begin>, <end> [, <step>])` | Return a list of `uint64` integers from `<begin>` (inclusive) to `<end>` (exclusive). Default step is `1`. |
| `$size(<ints>)` | Return the number of elements in an integer sequence. |
| `$front(<ints>)` | Return the first integer in the sequence. |
| `$back(<ints>)` | Return the last integer in the sequence. |
| `$sort(<ints> [, <flags>])` | Sort integers in ascending order. Flags: `dedup`. |
| `$find(<ints>, <int>)` | Return `true` if the sequence contains the integer. |
| `$find_index(<ints>, <int>)` | Return the index of the first match or `$size(<ints>)`. |


## $bool.*() -- boolean conversion

| Function | Description |
|---|---|
| `$string(<bool>)` | Convert `true` or `false` to its string literal. |


## $path.*() -- filesystem path manipulation

These functions accept typed `path`/`dir_path`/`paths`/`dir_paths` arguments
or untyped names. The untyped form is called with the `$path.` prefix.

| Function | Description |
|---|---|
| `$string(<paths>)` | Return the traditional string representation (no trailing slash for directories). |
| `$posix_string(<paths>)` | Return the string representation using POSIX forward-slash separators. |
| `$representation(<paths>)` | Return the precise string representation (includes trailing slash for directories). |
| `$posix_representation(<paths>)` | Return the precise POSIX representation. |
| `$absolute(<path>)` | Return `true` if the path is absolute. |
| `$simple(<path>)` | Return `true` if the path has no directory component. |
| `$sub_path(<path>, <path>)` | Return `true` if the first path is a sub-path of the second (second is a prefix). |
| `$super_path(<path>, <path>)` | Return `true` if the first path is a super-path of the second (second is a suffix). |
| `$directory(<paths>)` | Return the directory component of each path. |
| `$root_directory(<paths>)` | Return the root directory of each path, or empty if not absolute. |
| `$leaf(<paths> [, <dir>])` | Return the last component. With `<dir>`, return the path relative to that directory. |
| `$relative(<paths>, <dir>)` | Return paths made relative to `<dir>`. |
| `$base(<paths>)` | Return paths without their extension. |
| `$extension(<path>)` | Return the extension without the leading dot, or empty string. Returns `null` if no extension is specified. |
| `$complete(<paths>)` | Prepend the current working directory if the path is relative. |
| `$canonicalize(<paths>)` | Convert directory separators to the canonical form for the host platform. |
| `$normalize(<paths>)` | Collapse `.` and `..` components and multiple separators. Fails if the result is invalid. |
| `$try_normalize(<path>)` | Like `$normalize()` but returns `null` on error (single path only). |
| `$actualize(<paths>)` | Normalize and then obtain the actual filesystem spelling on case-insensitive filesystems. Not pure. |
| `$try_actualize(<path>)` | Like `$actualize()` but returns `null` on error (single path only). Not pure. |
| `$size(<paths>)` | Return the number of elements in a path sequence, or the character count of a single path. |
| `$front(<paths>)` | Return the first path in the sequence. |
| `$back(<paths>)` | Return the last path in the sequence. |
| `$sort(<paths> [, <flags>])` | Sort paths. Case-insensitive on case-insensitive filesystems. Flags: `dedup`. |
| `$find(<paths>, <path>)` | Return `true` if the sequence contains the path. |
| `$find_index(<paths>, <path>)` | Return the index of the first match or `$size(<paths>)`. |
| `$path.match(<entry>, <pattern> [, <start-dir>])` | Match an entry name or path against a shell-like wildcard pattern. For relative patterns an absolute `<start-dir>` is required unless both arguments are relative and non-self-matching. |


## $name.*() -- target and prerequisite names

| Function | Description |
|---|---|
| `$name(<names>)` | Return the unqualified name component of a target name. |
| `$extension(<name>)` | Return the target extension, or `null` if unspecified, or empty string if explicitly set to no extension. |
| `$directory(<names>)` | Return the directory component of a target name. |
| `$target_type(<names>)` | Return the target type name string. |
| `$project(<name>)` | Return the project part of a project-qualified name, or `null`. |
| `$is_a(<name>, <target-type>)` | Return `true` if the target type is-a `<target-type>`, respecting inheritance. |
| `$filter(<names>, <target-types>)` | Return names whose target type is-a one of `<target-types>`. |
| `$filter_out(<names>, <target-types>)` | Return names whose target type is not is-a any of `<target-types>`. |
| `$size(<names>)` | Return the number of elements in the name sequence. |
| `$front(<names>)` | Return the first element. |
| `$back(<names>)` | Return the last element. |
| `$sort(<names> [, <flags>])` | Sort names. Flags: `dedup`. |
| `$find(<names>, <name>)` | Return `true` if the sequence contains the name. |
| `$find_index(<names>, <name>)` | Return the index of the first match or `$size(<names>)`. |


## $target.*() -- operations on actual targets

These functions operate on resolved targets and are normally called from a
recipe after the target has been matched. They can be called from a buildfile
only if the target was updated during the load phase.

| Function | Description |
|---|---|
| `$path(<names>)` | Return the filesystem path of a target. Returns a list for multiple targets. |
| `$process_path(<name>)` | Return the `process_path` of a single executable target. |


## $regex.*() -- regular expressions

All `$regex.*()` functions must be called with the full `regex.` prefix. The
supported flavor is ECMAScript (ECMA-262-based C++11 regular expressions). The
`match_not_null` flag is in effect for non-empty strings.

In the format string (`<fmt>`) the standard ECMAScript escape sequences
(`$1`, `$2`, `$&`, etc.) are supported along with a Perl-compatible subset:
`\n`, `\u`, `\l`, `\U`, `\L`, `\E`, `\1` ... `\9`, and `\\`.

### Match and search

| Function | Description |
|---|---|
| `$regex.match(<val>, <pat> [, <flags>])` | Match the whole value against the pattern. Returns `bool` or, with `return_subs`, the sub-string list (`null` if no match). Flags: `icase`, `return_subs`. |
| `$regex.find_match(<vals>, <pat> [, <flags>])` | Return `true` if any element in the list matches completely. Flags: `icase`. |
| `$regex.filter_match(<vals>, <pat> [, <flags>])` | Return elements that match completely. Flags: `icase`. |
| `$regex.filter_out_match(<vals>, <pat> [, <flags>])` | Return elements that do not match completely. Flags: `icase`. |
| `$regex.search(<val>, <pat> [, <flags>])` | Return `bool` unless `return_match` or `return_subs` is specified. Flags: `icase`, `return_match`, `return_subs`. |
| `$regex.find_search(<vals>, <pat> [, <flags>])` | Return `true` if any element contains a match. Flags: `icase`. |
| `$regex.filter_search(<vals>, <pat> [, <flags>])` | Return elements that contain a match. Flags: `icase`. |
| `$regex.filter_out_search(<vals>, <pat> [, <flags>])` | Return elements that do not contain a match. Flags: `icase`. |

### Replace and transform

| Function | Description |
|---|---|
| `$regex.replace(<val>, <pat>, <fmt> [, <flags>])` | Replace matched parts of a value using `<fmt>`. Returns untyped names. Flags: `icase`, `format_first_only`, `format_no_copy`. |
| `$regex.replace_lines(<val>, <pat>, <fmt> [, <flags>])` | Apply replace to each line. `null` format omits matched lines that produce empty output. Returns name list or, with `return_lines`, a single multi-line name. Flags: `icase`, `format_first_only`, `format_no_copy`, `return_lines`. |
| `$regex.split(<val>, <pat>, <fmt> [, <flags>])` | Split a value into unmatched parts and replacements, omitting empty results unless `format_copy_empty`. Flags: `icase`, `format_no_copy`, `format_copy_empty`. |
| `$regex.merge(<vals>, <pat>, <fmt> [, <delim> [, <flags>]])` | Apply `<fmt>` to each element and concatenate results with an optional delimiter. Flags: `icase`, `format_first_only`, `format_no_copy`, `format_copy_empty`. |
| `$regex.apply(<vals>, <pat>, <fmt> [, <flags>])` | Apply replacement to each element, returning the transformed list (empty results omitted unless `format_copy_empty`). Flags: `icase`, `format_first_only`, `format_no_copy`, `format_copy_empty`. |

Note that combining `return_lines` with a format that drops the *last* line
of the input (a `null` format matching it, or `format_no_copy` on an
unmatched last line) leaves a stray trailing blank line in the reconstructed
string instead of ending cleanly. Interior dropped lines are omitted
correctly; only a trailing dropped line is affected.


## $json.*() -- JSON values

These functions operate on the `json`, `json_array`, and `json_object` types.

| Function | Description |
|---|---|
| `$value_type(<json> [, <distinguish_numbers>])` | Return the JSON type string: `null`, `boolean`, `number`, `string`, `array`, or `object`. With `<distinguish_numbers>` `true`, return `signed number`, `unsigned number`, etc. |
| `$value_size(<json>)` | Return the number of array elements or object members for container types, `1` for simple types, `0` for `null`. |
| `$member_name(<json-member>)` | Return the name of a JSON object member obtained by iterating an object. |
| `$member_value(<json-member>)` | Return the value of a JSON object member. Simple JSON values are returned as corresponding fundamental types. |
| `$object_names(<json-object>)` | Return the list of member names. Returns empty list for `null`. |
| `$array_size(<json-array>)` | Return the number of elements. Returns `0` for `null`. |
| `$array_front(<json-array>)` | Return the first element. Fails on empty or `null`. |
| `$array_back(<json-array>)` | Return the last element. Fails on empty or `null`. |
| `$array_find(<json-array>, <json>)` | Return `true` if the array contains the value. Returns `false` for `null`. |
| `$array_find_index(<json-array>, <json>)` | Return the index of the first matching value or `$array_size()`. Returns `0` for `null`. |
| `$json.load(<path> [, <flags>])` | Parse a JSON file and return the value. Not pure. Flags: `json` (default), `json5`, `json5e`. |
| `$json.parse(<text> [, <flags>])` | Parse a JSON string and return the value. Flags: `json` (default), `json5`, `json5e`. |
| `$json.serialize(<json> [, <indentation>])` | Serialize to a JSON string. `<indentation>` controls pretty-printing spaces (default `2`; `0` disables). |
| `$size(<json-set>)` | Return the number of elements in a `json_set`. |
| `$size(<json-map>)` | Return the number of entries in a `json_map`. |
| `$keys(<json-map>)` | Return the sorted keys as a JSON array. |


## $process.*() -- process execution

These functions can only be called during the load phase. Not pure.

| Function | Description |
|---|---|
| `$process.run(<prog> [<args>...])` | Run a builtin or external program and return trimmed `stdout` as a single value. |
| `$process.run_regex(<prog> [<args>...], <pat> [, <fmt>])` | Run a program and return `stdout` lines that match `<pat>`. With `<fmt>`, apply regex replacement to each matched line. |
| `$process.search(<prog>)` | Return the effective path of an executable (absolute, with any omitted extension added), or `null` if not found. |


## $filesystem.*() -- filesystem queries

All filesystem functions are not pure. For relative patterns in `$path_search`,
a `<start-dir>` must be specified when called from a buildfile.

| Function | Description |
|---|---|
| `$file_exists(<path>)` | Return `true` if the path exists and is a regular file (follows symlinks). |
| `$directory_exists(<path>)` | Return `true` if the path exists and is a directory (follows symlinks). |
| `$path_search(<pattern> [, <start-dir>])` | Return filesystem paths matching the shell-like wildcard pattern. Absolute patterns ignore `<start-dir>`. Relative patterns require an absolute `<start-dir>`. |


## $project_name.*() -- project name type

| Function | Description |
|---|---|
| `$string(<project-name>)` | Return the project name as a string. |
| `$base(<project-name> [, <extension>])` | Return the project name without its extension. If `<extension>` is specified, only remove that extension (dot-free, case-insensitive). |
| `$extension(<project-name>)` | Return the extension without the dot, or empty string if none. |
| `$variable(<project-name>)` | Return the project name sanitized for use as a variable name (`.`, `-`, `+` replaced with `_`). |


## $process_path.*() -- process path type

The `process_path` type describes an executable path. The `process_path_ex`
variant adds metadata fields used for diagnostics and change tracking.

| Function | Description |
|---|---|
| `$recall(<process-path>)` | Return the recall path: not necessarily absolute, but usable to re-run the executable in the current environment. Useful in diagnostics. |
| `$effect(<process-path>)` | Return the absolute path to the executable, including any omitted extensions. |
| `$name(<process-path-ex>)` | Return the stable process name for diagnostics. |
| `$checksum(<process-path-ex>)` | Return the executable checksum used for change tracking. |
| `$env_checksum(<process-path-ex>)` | Return the environment checksum used for change tracking. |


## $target_triplet.*() -- target triplet type

The `target_triplet` type represents a `cpu-vendor-os` platform triplet (for
example `x86_64-unknown-linux-gnu`).

| Function | Description |
|---|---|
| `$string(<triplet>)` | Return the canonical triplet string, omitting the `unknown` vendor component. |
| `$representation(<triplet>)` | Return the complete triplet string, always including the vendor component. |


## cc and cxx module functions

These live in the `c` / `cxx` modules (`libbuild2/cc/functions.cxx`), not in
the builtin function pool. Qualification with `$c.` or `$cxx.` is required.
They are not pure. They may only be called during execution (or, carefully,
during match) after the specified library targets have been matched.

In an ad hoc recipe they may only appear in the depdb preamble. Pair each
call with `depdb hash <value>` immediately. See
[ad-hoc-recipe.md](../HOWTO/ad-hoc-recipe.md).

Passing several library targets in one call is not just convenience: it
allows more effective duplicate suppression.

| Function | Description |
|---|---|
| `$c.lib_poptions(<lib-targets> [, <otype> [, <original>]])` / `$cxx.lib_poptions(...)` | Preprocessor options (`-I`, and similar) for compiling sources that depend on the specified libraries. `<otype>` is the output target type (`obje`, `objs`, ...). Omit `<otype>` for a utility library (`libul{}` or `libu[eas]{}`) to get only common-interface options, which is what a non-compiler tool such as Qt moc needs. If `<original>` is true, return the original `-I` options without translating them to `-isystem` or `/external:I`. That is the default when `<otype>` is omitted. |
| `$c.lib_libs(<lib-targets>, <otype> [, <flags> [, <self>]])` / `$cxx.lib_libs(...)` | Libraries and associated options for linking targets that depend on the specified libraries. `<otype>` is the output target type (`exe`, `libs`, ...). Flags: `whole` (whole-archive), `absolute` (absolute library paths). If `<self>` is false, omit the specified libraries themselves. |
| `$c.lib_rpaths(<lib-targets>, <otype> [, <link> [, <self>]])` / `$cxx.lib_rpaths(...)` | Rpath options for a hand-rolled link line. `<otype>` is the output target type (`exe`, `libs`, ...). If `<link>` is true, emit rpath-link options rather than rpath (the usual choice when linking for install). If `<self>` is false, omit options for the specified libraries themselves. This is not a way to add rpath to a target that still uses the stock link rule. For a dependency you never link, use `bin.rpath` instead ([rpath-unlinked-dependency.md](../HOWTO/rpath-unlinked-dependency.md)). |


## See also

- [build2 targets and variables](build2-targets-variables.md) -- target type hierarchy, variable types, assignment operators, built-in scope variables
- [Buildfile language reference](build2-buildfile-language.md) -- eval contexts, expansion, `if`/`for`/`while`
- [Buildfile directives, patterns, and attributes](build2-directives-patterns.md) -- `define`, `using`, `import`, wildcard patterns
- [Ad hoc recipes](../HOWTO/ad-hoc-recipe.md) -- attachment grammar, `depdb hash` pairing for these functions
