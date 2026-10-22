# Vendored dplyr tests against dplyr 1.2.1

*Measures: how many vendored dplyr tests fail after re-vendoring from dplyr 1.2.1, by configuration.*

*Held on: 2026-10-22, duckdb 1.5.6, dplyr tests from the tag `v1.2.1` (`95740975c`) of `tidyverse/dplyr`, replacing copies of dplyr 1.2.0.*

*Supports: [`vendored-tests/`](/handbook/dplyr-alignment/vendored-tests/README.md), whose known state quotes the findings.*

## Method

The tests were regenerated with `tools/04-dplyr-tests.R` from `.sync/dplyr-main` checked out at the tag, detached.
The order of the run, and the stub that `gert::git_pull()` needs on a detached checkout, are
[`sync/`](/handbook/dplyr-alignment/sync/README.md).
The three commits are `8c37380` (the regenerated tests and the `tools/00-funs.R` entries), `6aa65bb` (`test-as_duckplyr_df.R`),
and `17a0faf` (the `recode_values()` patch).

Each configuration ran the test suite with the filter and variables below.

* Default: `filter = "dplyr"`, no variables set.
* Forced: `filter = "dplyr"`, `DUCKPLYR_FORCE=TRUE`.
* Whole suite: no filter, default.

## Findings

**Default configuration, files matching `dplyr`:** 0 failures of 1260, with 312 skipped.
Before the re-vendoring: 0 failures of 1231.

**With `DUCKPLYR_FORCE=TRUE`:** 344 failures both before and after.
The largest groups are rows (44), group-by (40), pick (31), reframe (29), and mutate (23).
Most of the messages are "Fallback not available with DUCKPLYR_FORCE".
CI never sets `DUCKPLYR_FORCE`, and `non_force_only_tests` does not list every test that fails under it.

**Whole suite, default configuration:** 2 failures, both in `test-fallback.R`, the `wday()` and the `strftime()` snapshots.
The difference is how cli formats backticks, and both tests are `skip_on_ci()`.

## Replicating

Install `constructive` from <https://cynkra.r-universe.dev>, since it is not on CRAN, then `pak::local_install_dev_deps(upgrade = FALSE)`.
Check out the tag in `.sync/dplyr-main`, regenerate as `sync/` describes, and run the three configurations above.
