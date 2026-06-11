# Library That Provides main()

Available in build2 0.16.0 and later.

Testing frameworks often supply an optional `main()` implementation. In build2
this is done with a static library linked in "whole archive" mode. Shared
libraries providing `main()` are not recommended due to platform-specific
complications.

See [`lib{}`, `liba{}`, `libs{}`](../guides/build2-modules-bin.md#lib-liba-libs)
and [`libul{}`, `libue{}`, `libua{}`, `libus{}`](../guides/build2-modules-bin.md#libul-libue-libua-libus)
for the relevant target types.

## Simple approach (always links static lib{mytest})

Add `main.cxx`, exclude it from the main library, and introduce
`liba{mytest-main}` with `bin.whole = true`:

```
./: lib{mytest}: {hxx ixx txx cxx}{* -main}
./: liba{mytest-main}: cxx{main} lib{mytest}

liba{mytest-main}:
{
  bin.whole = true
  cxx.export.libs = lib{mytest}
}
```

Consumer imports `liba{mytest-main}` instead of `lib{mytest}` and omits its
own `main()`. Drawback: always links the static variant of `lib{mytest}`.

## Elaborate approach (respects bin.exe.lib preference)

Use binless `lib{mytest-main}` as a selector so consumers always get the
correct `lib{mytest}` variant (static or shared) based on their linking
preferences, while `main()` itself always comes from a static library:

```
src = cxx{* -main}

./: lib{mytest}: $src {hxx ixx txx}{*}
./: lib{mytest-main}

liba{mytest-main}: liba{mytest-main-static}
libs{mytest-main}: liba{mytest-main-shared}

liba{mytest-main-static}: obja{main-static} liba{mytest}
liba{mytest-main-shared}: obja{main-shared} libs{mytest}

obja{main-static}: cxx{main} liba{mytest}
obja{main-shared}: cxx{main} libs{mytest}

liba{mytest-main-static mytest-main-shared}: bin.whole = true

# Compile LIBMYTEST_*_BUILD macros only on non-main sources.
hbmia{*}: cxx.poptions += -DLIBMYTEST_STATIC_BUILD
hbmis{*}: cxx.poptions += -DLIBMYTEST_SHARED_BUILD

obja{$name($src)}: cxx.poptions += -DLIBMYTEST_STATIC_BUILD
objs{$name($src)}: cxx.poptions += -DLIBMYTEST_SHARED_BUILD

lib{mytest}: cxx.export.poptions = "-I$out_root" "-I$src_root"
liba{mytest}: cxx.export.poptions += -DLIBMYTEST_STATIC
libs{mytest}: cxx.export.poptions += -DLIBMYTEST_SHARED

liba{mytest-main}: cxx.export.libs = lib{mytest}
libs{mytest-main}: cxx.export.libs = liba{mytest-main-shared} lib{mytest}
```

The two static libraries (`liba{mytest-main-static}` and
`liba{mytest-main-shared}`) compile the same `main.cxx` but against
`liba{mytest}` and `libs{mytest}` respectively, so `main.cxx` sees DLL-export
macros correctly in each case.

Consumer imports the binless `lib{mytest-main}`:

```
import libs = libmytest%lib{mytest-main}
```

## Verifying the correct variants are linked

```
b -v tests/basics/exe{driver}
b -v tests/basics/exe{driver} config.bin.exe.lib=static
```
