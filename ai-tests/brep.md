# Tests: brep -- package repository web interface

Source documentation: `brep/README.md`, `brep/brep-load.md`,
`brep/brep-migrate.md`, `brep/brep-clean.md`, `brep/brep-monitor.md`


## T001 -- Two PostgreSQL databases

**Query:** How many PostgreSQL databases does brep use, and what are their
purposes?

**Key facts** (all must appear in a correct answer):
- brep uses two PostgreSQL databases.
- The **package** database stores repository and package metadata.
- The **build** database stores build results from automated build bots.
- Default name of the package database is `brep_package`.
- Default name of the build database is `brep_build`.

**Source:** `brep/README.md`


## T002 -- Schema initialization order

**Query:** What commands must be run before brep can be used for the first time?

**Key facts** (all must appear in a correct answer):
- `brep-migrate package` creates the package database schema.
- `brep-migrate build` creates the build database schema.
- Both must be run before the first use.

**Source:** `brep/README.md`


## T003 -- brep-load input file

**Query:** What configuration file does `brep-load` read to know which
repositories to fetch?

**Key facts** (all must appear in a correct answer):
- The file is called `loadtab`.
- `brep-load` is invoked with the path to the loadtab file as its argument.

**Source:** `brep/README.md`


## T004 -- brep-monitor output destination

**Query:** Where does `brep-monitor` write its output when it detects delayed
package builds?

**Key facts** (all must appear in a correct answer):
- `brep-monitor` reports to `stderr`.

**Source:** `brep/README.md`


## T005 -- brep-clean purposes

**Query:** What are the two main things `brep-clean` can remove or expire?

**Key facts** (all must appear in a correct answer):
- It removes expired build records from the build database.
- It expires or archives tenant records from the package database.

**Source:** `brep/README.md`
