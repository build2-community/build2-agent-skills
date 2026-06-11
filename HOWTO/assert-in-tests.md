# Using assert() in Tests

`assert()` from `<cassert>` is adequate for simple tests and requires no
[extra dependencies](./tests-extra-dependencies.md). To ensure `NDEBUG` does
not disable assertions, undefine it immediately before the include and include
`<cassert>` last:

```cpp
#include <string>

#undef NDEBUG
#include <cassert>

int main ()
{
  assert (std::string ("test") == "test");
}
```

The "include last" rule matters: other headers you include before `<cassert>`
should still see `NDEBUG` with its normal effect.

## See Also

- [sanitize-tests.md](./sanitize-tests.md) -- sanitizing misbehaving test execution
- [testscript-summary.md](../guides/testscript-summary.md) -- Testscript language reference
- [build2 core modules: test](../guides/build2-modules-core.md)
