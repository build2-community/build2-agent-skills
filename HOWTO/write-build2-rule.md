# Writing a Custom build2 Rule

A build2 rule encapsulates the logic for how to build one or more target types
for a given action. You need a custom rule when:

- You need to drive a code generator, preprocessor, or other external tool.
- You want to intercept an existing operation (e.g., `update` or `install`) on
  a custom target type.
- None of the built-in rules (`in`, `cc`, `bin`, etc.) cover your tool.

You do **not** need a custom rule when ad hoc recipes in a buildfile are
sufficient for a one-off transformation, or when the existing `in` module (for
`.in` file substitution) already covers your needs.

---

## 1. Declare the rule class

Derive from `simple_rule` (in `libbuild2/rule.hxx`) unless you need the hint
or `match_extra` arguments:

```cpp
// In init.hxx (or a dedicated rule.hxx)
#include <libbuild2/rule.hxx>
#include <libbuild2/recipe.hxx>
#include <libbuild2/target.hxx>

namespace hello
{
  class rule: public build2::simple_rule
  {
  public:
    bool   match (build2::action, build2::target&) const override;
    build2::recipe apply (build2::action, build2::target&) const override;
  };
}
```

Rules are registered by const reference and must be stateless (or MT-safe),
because `match()` may be called concurrently.

---

## 2. Implement `match()`

`match()` is called during the match phase. Return `true` if and only if this
rule should handle the target. Keep it cheap: inspecting the target type,
checking for a prerequisite of a specific type, or reading a target-specific
variable are all fine. Do not perform I/O or execute external tools here.

```cpp
bool
hello::rule::match (build2::action a, build2::target& t) const
{
  using namespace build2;

  // Only match file-based targets that have at least one .hello prerequisite.
  if (!t.is_a<file> ())
    return false;

  for (const prerequisite& p: group_prerequisites (t))
  {
    if (p.is_a (hello_target_type))
      return true;
  }

  return false;
}
```

When `match()` returns `false`, the build system tries the next registered rule.

---

## 3. Implement `apply()`

`apply()` is called once for each target that `match()` accepted. Its
responsibilities are:

1. Declare and match prerequisites so they are built before this target.
2. Return a recipe -- a callable that performs the actual build step.

```cpp
build2::recipe
hello::rule::apply (build2::action a, build2::target& t) const
{
  using namespace build2;

  // Ensure the output directory exists.
  inject_fsdir (a, t);

  // Search and match all declared prerequisites so they can be executed.
  match_prerequisites (a, t);

  // Return the recipe function that runs during the execute phase.
  return [this] (action a, const target& t) -> target_state
  {
    return perform_update (a, t);
  };
}
```

The recipe captures `this` only when it needs to call a member function like
`perform_update()`. Capturing `this` is safe because rules are required to
outlive the scope they are registered in.

---

## 4. Write the recipe function

The recipe function runs during the execute phase. Its signature must match:

```cpp
build2::target_state (build2::action, const build2::target&)
```

A typical recipe:

1. Executes prerequisites so they are up to date.
2. Checks whether the output is already up to date (using a depdb or mtime
   comparison).
3. Runs the external tool.
4. Returns `target_state::changed` or `target_state::unchanged`.

```cpp
build2::target_state
hello::rule::perform_update (build2::action a, const build2::target& t) const
{
  using namespace build2;

  // Execute all prerequisites first (build inputs before outputs).
  target_state ts (execute_prerequisites (a, t));

  const file& ft (t.as<file> ());

  // Collect input prerequisites of the expected type.
  // (For brevity this example skips the depdb / mtime check.)

  // Run the tool. process_path, process_run, etc., are in libbuild2/process.hxx.
  // ...

  // If we generated new output, return changed; otherwise return the
  // aggregate prerequisite state so the target inherits "unchanged" correctly.
  return ts | target_state::changed;
}
```

On error, throw `failed` (defined in `libbuild2/diagnostics.hxx`) rather than
returning. Do not return on error.

---

## 5. Register the rule in `init()`

```cpp
// A single static instance suffices because rules must be stateless.
static const hello::rule hello_rule_;

bool
init (build2::scope& rs,
      build2::scope& bs,
      const build2::location& l,
      bool first,
      bool optional,
      build2::module_init_extra& extra)
{
  using namespace build2;

  if (first)
  {
    // Register for file targets, perform(update()) action.
    rs.insert_rule<file> (perform_update_id, "hello.update", hello_rule_);

    // Also register for clean and configure so the target is handled
    // uniformly across meta-operations.
    rs.insert_rule<file> (perform_clean_id,    "hello.update", hello_rule_);
    rs.insert_rule<file> (configure_update_id, "hello.update", hello_rule_);
  }

  return true;
}
```

`insert_rule<T>()` takes:
- `T`: the target type the rule handles.
- `action_id`: the combined meta-operation/operation identifier (e.g.,
  `perform_update_id`, `perform_clean_id`). Defined in `libbuild2/action.hxx`.
- Rule name: used in diagnostics and to resolve rule hints in buildfiles.
- Rule reference: must outlive the scope.

---

## 6. Minimal end-to-end skeleton

### Buildfile side

The project that uses the module loads it and declares targets:

```
# build/root.build
using hello

# In the library/executable buildfile:
lib{mylib}: cxx{**} hello{data}
```

`hello{}` is a custom target type registered by the module in `init()`:

```cpp
// In init(), before registering rules:
const target_type& hello_tt =
  rs.derive_target_type<file> ("hello", nullptr);
```

### C++ side (module `init.cxx`)

```cpp
#include <libbuild2/rule.hxx>
#include <libbuild2/action.hxx>
#include <libbuild2/algorithm.hxx>  // inject_fsdir, match_prerequisites, execute_prerequisites

namespace hello
{
  class rule: public build2::simple_rule
  {
  public:
    bool match (build2::action a, build2::target& t) const override
    {
      return t.is_a<build2::file> ();
    }

    build2::recipe apply (build2::action a, build2::target& t) const override
    {
      build2::inject_fsdir (a, t);
      build2::match_prerequisites (a, t);

      return [] (build2::action a, const build2::target& t) -> build2::target_state
      {
        build2::execute_prerequisites (a, t);
        // ... run tool ...
        return build2::target_state::changed;
      };
    }
  };

  static const rule rule_;

  bool init (build2::scope& rs,
             build2::scope& bs,
             const build2::location& l,
             bool first,
             bool optional,
             build2::module_init_extra&)
  {
    if (first)
      rs.insert_rule<build2::file> (build2::perform_update_id, "hello.update", rule_);
    return true;
  }
}
```

---

## See Also

- [build2-module-hello.md](../guides/build2-module-hello.md) -- full module API: entry point, init/boot, module_functions, stateful modules, variable declaration
- [build2-module-dev-setup.md](../guides/build2-module-dev-setup.md) -- development environment setup for building and testing a module
- [HOWTO/toolchain-dev-setup.md](./toolchain-dev-setup.md) -- setting up the full build2 toolchain for development
