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

<!-- Update this section with the results of each porting round: the dplyr commit vendored, what was skipped and why, what remains. -->

As of 2026-10-22, the vendored files were copied from `.sync/dplyr-main` at a dplyr commit this page does not record,
and porting the vendored tests to the current dplyr is in progress in a separate branch.
This section is to be replaced with that work's results: the dplyr commit vendored,
the files added or dropped, the tests newly skipped with their reasons, and what remains open.

*To deepen: record the dplyr commit the vendored tests were last copied from,
and fill in the known state from the porting round in progress.*
