# Disabling the Shared Library Variant per Platform

The preferred approach is to let the user control which library variant to
build via [`config.bin.lib`](../guides/build2-projects-advanced.md#static-vs-shared-library-control).
Only fall back to overriding it when upstream genuinely cannot produce a
shared library on a given platform.

## Forcing static-only on Windows

Override `bin.lib` in `build/root.build` after the compiler module is loaded:

```
if ($cxx.target.class == 'windows')
{
  assert ($bin.lib != 'shared') 'only static variant can be built on Windows'
  bin.lib = static
}
```

To warn instead of failing when `bin.lib` is `both`:

```
if ($cxx.target.class == 'windows')
{
  switch $bin.lib
  {
    case 'shared'
      fail 'only static variant can be built on Windows'
    case 'both'
    {
      warn 'only static variant will be built on Windows'
      bin.lib = static
    }
  }
}
```

## Disabling import of the shared variant

Also update `build/export.build` so importers cannot request `libs{hello}` on
Windows:

```
$out_root/
{
  include libhello/
}

if ($($out_root/libhello/ cxx.target.class) == 'windows')
  assert ($import.target != libs{hello}) "only static variant can be imported on Windows"

export $out_root/libhello/$import.target
```
