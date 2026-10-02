# Linking System Libraries

System libraries (`-lm`, `-ldl`, `advapi32.lib`, `ws2_32.lib`, etc.) are not
importable targets. List them in the appropriate
[`*.libs` variable](../guides/build2-modules-cxx.md#system-library-dependencies-and-pkg-config-integration)
instead:

```
if ($c.target.class != 'windows')
  c.libs += -lm
```

```
if ($cxx.target.class == 'windows')
{
  if ($cxx.target.system == 'mingw32')
    cxx.libs += -ladvapi32
  else
    cxx.libs += advapi32.lib
}
```

If the system library is an interface dependency of your library (i.e.,
consumers also need to link it), list it in
[`*.export.libs`](../guides/build2-modules-cxx.md#export-options-propagated-to-consumers-of-a-library)
as well. See [library projects](../guides/build2-projects-advanced.md#library-projects)
for background on interface vs implementation dependencies:

```
if ($c.target.class != 'windows')
{
  c.libs += -lm
  lib{hello}: c.export.libs = -lm
}
```

For a [binless (header-only) library](./header-only-library.md) you still need
`*.libs` in addition to `*.export.libs` because `*.libs` is used when linking
the static variant of the binless library.

## See Also

- [`troubleshooting`](./troubleshooting.md#error-static-variant-of-target-is-not-available) -- `error: static variant of <target> is not available` when the same system library is instead reached through an installed `.pc` file
- [`link-prerequisite-order`](./link-prerequisite-order.md) -- sources before `$libs` on `exe{}` and `libs{}`
- [`link-pthread`](./link-pthread.md) -- special case: linking pthread portably
- [`header-only-library`](./header-only-library.md) -- binless library dependency considerations for *.libs
- [`build2-modules-cxx`](../guides/build2-modules-cxx.md) -- cxx.libs, cxx.export.libs, and pkg-config integration
- [`build2-projects-advanced`](../guides/build2-projects-advanced.md) -- library interface vs implementation dependencies
