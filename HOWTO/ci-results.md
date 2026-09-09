# Reading cppget.org CI Results

`bdep ci` submits the project and prints a results URL. How that page
presents the `test-installed` phase is cppget.org UI, not a `bdep`
contract. The notes below are what the compact summary and the
per-configuration logs actually show.

## `test-installed` runs per configuration

Each build-configuration log is a sequence of phases (`configure`,
`update`, `test`, `install`, `test-installed`, `uninstall`, ...). The
installed-consumer step is
`bpkg.test-separate-installed.create` / `.configure.*` / `.test` in that
log: a second bpkg configuration that consumes the package from the
install prefix, with `config.cc.loptions+=-L<prefix>/lib` (see
[local-installed-import.md](./local-installed-import.md)).

It is not a single matrix-wide job. A failure on one configuration and
passes on the others means it ran everywhere and failed on that one.

## Compact summary vs full log

On the compact results page, a *passing* `test-installed` step is folded
into that configuration's `log` link. There is no separate badge.

A warning or error on that step gets its own `test-installed` link (the
URL ends in `/test-installed`). Open the full per-configuration log to
see `test-installed: success` (or `warning` / `error`) for the configs
that look unmarked.

Without that distinction, a page that shows one `test-installed` failure
and otherwise only `log` links looks like the phase ran once. It ran on
every configuration. Only the failures are called out.

## See Also

- [bdep-ci.md](../bdep/bdep-ci.md): submitting the request
- [packaging-guide-testing.md](../guides/packaging-guide-testing.md#step-9-test-the-package):
  local installed test, and why a green `bdep ci` is not sufficient
- [local-installed-import.md](./local-installed-import.md): reproduce
  the installed consumer without CI
- [builds-ci-filtering.md](./builds-ci-filtering.md): which
  configurations are in the matrix
