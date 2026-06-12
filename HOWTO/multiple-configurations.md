# Managing Multiple Build Configurations

bdep lets you associate a project with several bpkg build configurations at
once and build/test in all of them with a single command.

## Creating named configurations

```
$ bdep init --empty                          # project has no configs yet
$ bdep config create -d ../build-gcc @gcc   \
    cc config.cxx=g++ config.cxx.coptions=-O2
$ bdep config create -d ../build-clang @clang \
    cc config.cxx=clang++
$ bdep config create -d ../build-san @san   \
    cc config.cxx=g++                        \
    config.cxx.coptions="-g -fsanitize=address,undefined"
$ bdep init @gcc @clang @san
```

The `@name` suffix assigns a short alias to each configuration.

## Operating across all configurations

```
$ bdep update        # update in all configurations
$ bdep test          # test in all configurations
$ bdep clean         # clean in all configurations
```

## Operating on a specific configuration

```
$ bdep update @gcc            # only the gcc config
$ bdep test @san              # only the sanitizer config
$ bdep build @clang           # alias for bdep update @clang
```

## Adding a release configuration

```
$ bdep config create -d ../build-release @release \
    cc config.cxx=g++ config.cxx.coptions=-O3 config.cxx.coptions+=-DNDEBUG
$ bdep init @release
```

## Listing configurations

```
$ bdep config list
```

## Removing a configuration

```
$ bdep deinit @san
$ bdep config remove @san
```

## Checking status across configurations

```
$ bdep status
```

## See Also

- [`bdep-config`](../bdep/bdep-config.md) -- full bdep config command reference
- [`bdep-init`](../bdep/bdep-init.md) -- initializing a project in configurations
- [`build2-buildfile-language`](../guides/build2-buildfile-language.md#build-configurations-shared-amalgamated) -- build configuration amalgamations
