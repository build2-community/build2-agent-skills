# Converting Source Files to UTF-8

Non-UTF-8 source files cause errors like:

```
hello.cxx:4:6: error: source file is not valid UTF-8
hello.cxx:4:6: error: stray '\344' in program
```

Use `iconv(1)` (available on POSIX systems) to convert the encoding.

If you know or can guess the original encoding (e.g., ISO-8859-2 for Czech
comments):

```
iconv -f ISO-8859-2 -t UTF-8 hello.cxx >hello-utf8.cxx
```

If the encoding is unknown or the file contains invalid UTF-8 sequences, strip
unconvertible characters with `-c` and verify only harmless content (comments)
was discarded:

```
iconv -c -f UTF-8 -t UTF-8 hello.cxx >hello-utf8.cxx
diff -u hello.cxx hello-utf8.cxx
```

Report such issues upstream so they can fix the source files.

## Note for third-party packaging

When packaging using the
[git submodule + symlink pattern](../guides/packaging-guide-summary.md#concepts),
the source files are symlinks into `upstream/` and cannot be overwritten
directly. The
[common patterns and pitfalls](../guides/packaging-guide-summary.md#common-patterns-and-pitfalls)
section of the packaging guide covers the available approaches: manual copy
with `.orig`/`.patch` files, a `sed`-based ad hoc recipe, or the C
preprocessor trick.
