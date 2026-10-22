---
status: draft
---

# dplyr and duckdb versions

Which versions of dplyr and duckdb duckplyr supports, where each bound is set, and what moving to a new version of either involves.
Taking a new dplyr's code and tests in is [`dplyr-alignment/`](/handbook/dplyr-alignment/README.md)'s, through its sync.

**The lower bounds are in [`DESCRIPTION`](/DESCRIPTION).**
dplyr is under `Depends`, so that attaching duckplyr attaches dplyr, and duckdb is under `Imports`, each with a minimum version.
The bounds are raised by hand when duckplyr starts relying on something newer, and nothing checks them against the code.

**duckdb also has an upper bound, set at load time in [`R/zzz.R`](/R/zzz.R).**
duckplyr refuses to load with a duckdb whose version reaches the major version the guard names, with an error asking for a newer duckplyr.
The comment above the guard is the procedure: raise the guard to the next major version a release ahead of that duckdb release,
once duckplyr has been checked against it, so that the duckplyr on CRAN accepts the new duckdb on the day it lands.
A duckplyr already installed is the reason the guard exists: it cannot be fixed after the fact, only refused.

**Moving to a new dplyr.**

1. Update `.sync/dplyr-main` to the dplyr to support ([`dplyr-alignment/setup/`](/handbook/dplyr-alignment/setup/README.md)).
2. Run the sync, taking the changes in ([`dplyr-alignment/sync/`](/handbook/dplyr-alignment/sync/README.md)).
3. Revisit the skip-list entries that wait for a newer dplyr
   ([`dplyr-alignment/vendored-tests/`](/handbook/dplyr-alignment/vendored-tests/README.md)).
4. Raise dplyr's bound in `DESCRIPTION` where the regenerated code or the vendored tests need the new version.
5. Rebuild the rigged dplyr ([`dplyr-alignment/rigged-dplyr/`](/handbook/dplyr-alignment/rigged-dplyr/README.md)).

The fallback always calls the installed dplyr's method, so the code generated from one dplyr runs against another;
the vendored tests are what show whether the two still agree.

**Moving to a new duckdb.**
duckplyr calls duckdb's relational API, much of it through internal functions of the duckdb package,
so a new duckdb is checked by running the whole test suite against it ([`testing/`](/handbook/testing/README.md)),
and the `rcc dev` workflow runs the checks against development versions of the dependencies ([`ci/`](/handbook/ci/README.md)).
The generated `rel_api` tests are also copied into duckdb-r by `tools/06-patch-duckdb.R`,
so that duckdb-r's own checks cover what duckplyr uses.

*To deepen: confirm with the maintainer when each bound is raised, and whether `R-CMD-check-dev.yaml` covers dplyr and duckdb.*
