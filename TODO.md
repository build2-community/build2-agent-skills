# TODO

Open documentation gaps discovered while using this reference during real
packaging work, not yet resolved into a proper guide/HOWTO entry.

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
