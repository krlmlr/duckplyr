---
status: draft
---

# Vendored dplyr tests

How dplyr's own test files are copied into duckplyr's suite and rewritten to exercise duckplyr,
how a vendored test is skipped and with what justification, and the state the vendored suite is in.
Running the copy as part of a sync is [`sync/`](/handbook/dplyr-alignment/sync/README.md)'s,
and edits the skip lists cannot express are [`patches/`](/handbook/dplyr-alignment/patches/README.md)'s.

## What is copied, and how it is rewritten

**`duckplyr_tests` in [`tools/00-funs.R`](/tools/00-funs.R) names every dplyr test file that is copied, and nothing else is.**
`tools/04-dplyr-tests.R` copies each named file from `.sync/dplyr-main/tests/testthat/`,
renaming `test-<name>.R` to `test-dplyr-<name>.R` and `helper-<name>.R` to `helper-dplyr-<name>.R`.
A file that dplyr adds is not vendored until it gets an entry, and an entry whose value is `"*"` keeps its file out,
with a comment saying why: deprecated, dplyr internals, or not relevant to duckplyr.

**Each copy is rewritten to run through duckplyr.**

* Every call to a verb duckplyr implements, `<verb>(`, becomes `duckplyr_<verb>(`.
  That helper is generated beside the method in `R/<verb>.R`:
  it converts its input to a duckplyr data frame, skips the test if the conversion fails,
  and drops the duckplyr class from a data frame result so that dplyr's expectations compare equal.
* The file gets a header saying it is generated, a dummy test, and a `skip_if()` on `DUCKPLYR_SKIP_DPLYR_TESTS`,
  which skips every vendored file at once ([`testing/`](/handbook/testing/README.md)).
* The skips from the skip lists below are inserted, and the result is formatted with `air`.
* The patch files under `patch-tests/` are applied last.

A test that calls a dplyr internal skips itself: [`helper-skip.R`](/tests/testthat/helper-skip.R)
defines each internal the vendored tests use as a function that calls `skip()`.

## Skipping a vendored test

**Three lists in `tools/00-funs.R` skip tests by their `test_that()` description, each with its own effect.**

* `duckplyr_tests`, per file, inserts `skip("TODO duckdb")`: the test does not pass with duckplyr.
  The same list also skips these tests in dplyr's own suite inside the rigged dplyr
  ([`rigged-dplyr/`](/handbook/dplyr-alignment/rigged-dplyr/README.md)).
* `non_force_only_tests` inserts `skip_if(Sys.getenv("DUCKPLYR_FORCE") == "TRUE")`:
  the test passes through the fallback to dplyr, and would fail where falling back is an error.
* `dplyr_only_tests` touches nothing here, and skips tests only in the rigged dplyr's copy of dplyr's suite.

A description matches wherever it appears in quotes in the file, and the skip goes on the line after each match,
which is the first line of the test body when the description sits on the `test_that(` line.
A description may name a verb in dplyr's form or in its `duckplyr_` form, since the entry is rewritten the same way as the file.

**An entry carries its reason in a comment above it.**
Most entries do, and an entry added from here on does.
The reasons in use, each a kind of justification an entry may give:

* the test needs a dplyr newer than the one duckplyr supports, naming the version;
* the test sees an artifact of the `duckplyr_<verb>()` wrapper rather than of duckplyr, such as the extra class;
* duckplyr behaves differently on purpose or for now, linking the issue or pull request that tracks it;
* the test fails only under `R CMD check`, saying so.

A real difference is also a limitation of duckplyr, so the issue link is what lets it be removed later;
an entry whose comment gives no cause is a defect to investigate rather than a precedent.

## Known state

**The vendored files on `main` come from dplyr 1.2.0.**
The re-vendoring to the dplyr tag `v1.2.1` is in a separate pull request, branch `claude/vendor-dplyr-tests`, and this page says where its state differs.
The copies are not stamped with their ref, so `git log` on `tests/testthat/test-dplyr-*.R` is how to tell, and a re-vendoring commit names its tag.
`git -C .sync/dplyr-main describe --tags` names what the next run would copy.

**With the re-vendoring merged, `test-recode-values.R` and `test-when.R` are vendored, and `test-defunct-each.R` and `test-defunct-lazyeval.R` are excluded.**
The first two are new in dplyr 1.2.1, and the last two are deprecated tests, kept out with `"*"`.
The vendored `recode_values()` tests then carry a patch, `patch-tests/test-dplyr-recode-values.patch` on that branch ([`patches/`](/handbook/dplyr-alignment/patches/README.md)):
it scrubs the factor hash from their snapshots and qualifies `vctrs::vec_recode_values()`, which upstream finds through dplyr's imports.

**In the default configuration the vendored tests pass.**
No failures were measured on 2026-10-22 on the re-vendored branch, with the tests that the skip lists name skipped.

**The forced mode is not maintained.**
`DUCKPLYR_FORCE=TRUE` fails 344 vendored tests, mostly because the fallback they need is an error there,
and `non_force_only_tests` does not list them all.
CI never sets it and nowhere else runs the suite with it, so nothing keeps the list complete.
A separate CI matrix entry is planned, tracked in an issue.

**Two tests outside the vendored files fail locally.**
The `wday()` and `strftime()` snapshots in `test-fallback.R` differ in how cli formats backticks, and are `skip_on_ci()`.

The counts, the largest groups of forced failures, and the method are in
[`experiments/2026-10-22-dplyr-tests-revendoring/`](/experiments/2026-10-22-dplyr-tests-revendoring/README.md).

*To deepen: complete `non_force_only_tests` once the forced CI entry exists.*
