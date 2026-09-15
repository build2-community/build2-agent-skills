# TODO

Open documentation gaps discovered while using this reference during real
packaging work, not yet resolved into a proper guide/HOWTO entry.

- `HOWTO/sys-build-config.md` and `HOWTO/builds-ci-filtering.md` both point
  at `https://ci.cppget.org/?build-configs` as "the current list" of bot
  configurations, but neither says that URL with no query value defaults to
  the `default` class only, silently hiding every clang, macOS, Windows,
  FreeBSD, Fedora, RHEL, and Ubuntu bot. Even `?build-configs=all` is itself
  paginated (`&p=1`, `&p=2`, ...), currently 4 pages for ~77 configs. Checking
  only the unpaginated default view during a real investigation produced a
  false "zero Fedora/macOS/Windows bots exist on this deployment" conclusion.
  Add a callout: always use `?build-configs=all` and page through every
  `&p=N` link before concluding a bot class does not exist.

- Whether a bot tagged with the `bindist` class can also satisfy an ordinary
  `sys:`-dependency build under a `*-build-config` package config is not
  stated anywhere. `sys-build-config.md` describes `bbot.sys-install`
  (installing the package's own generated bindist artifact) as unrelated to
  `sys:` resolution, which reads as "bindist bots run a different recipe,"
  but real bots (confirmed via `?build-configs=all`, e.g.
  `linux_fedora_43-gcc_15-bindist`) carry both `sys` and `bindist` classes at
  once, and subtracting `-bindist` from a `*-builds:` class expression (the
  existing `debian-builds: sys -static -bindist` pattern) is in fact the
  correct, working, self-updating way to exclude only the bindist variant of
  a distro while staying ready for a future non-bindist bot of the same
  distro. Document this plainly, the ambiguity produced two contradictory
  designs for the same manifest fragment in one session.

- Unresolved from a live investigation, not just a missing-doc gap: a real
  `bdep ci` request showed a package config (`fedora`) running against a
  target configuration its own `*-build-include`/`*-build-exclude` pair
  should have excluded on every documented and coded code path traced
  (`build-target-config.cxx`'s `exclude()`, first-match-wins, catch-all
  `build-exclude: **`). Two independent source-level traces could not explain
  the discrepancy. Left unresolved per user direction (fix the manifest's own
  correctness instead of chasing this further), but if this turns out to be
  a real, reproducible cppget.org/`bdep ci` behavior (for example, the
  initial ad hoc CI request testing every declared package config against a
  broad bot sample regardless of that config's own filtering, with filtering
  only taking effect for later, attached/automatic re-scheduling), it belongs
  in `HOWTO/sys-build-config.md` or `HOWTO/builds-ci-filtering.md` as a
  documented caveat.
