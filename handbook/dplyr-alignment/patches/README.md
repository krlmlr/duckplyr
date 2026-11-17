---
status: draft
---

# Patches that keep manual edits

How a manual edit to a generated verb method or a vendored dplyr test survives regeneration:
the committed file is the truth, and a patch file records how it differs from what the generator writes.
When to run the generators, and the two-pass run that takes dplyr's changes in, is [`sync/`](/handbook/dplyr-alignment/sync/README.md)'s.

**Two generators keep patches, each in its own directory.**

* `tools/02-duckplyr_df-methods.R` keeps `patch/<verb>.patch` for `R/<verb>.R`.
* `tools/04-dplyr-tests.R` keeps `patch-tests/test-dplyr-<name>.patch` for `tests/testthat/test-dplyr-<name>.R`.

The two run the same three steps.

1. **Generate and apply.**
   The script writes every output file from scratch, then applies every patch file in its directory with `patch -p1`.
2. **Stop here, optionally.**
   A comment starting `# Stop here to overwrite files` marks the point
   where the working tree holds the fresh output with the edits replayed.
3. **Collect.**
   For every output file git reports as changed, the script reverses that file's patch, which leaves the bare generated output,
   writes `git diff -R` of the file as its new patch, which is the change from the generated output to the version in git's index,
   and checks the index version back out.

**The committed file is what a maintainer edits.**
A manual change is made in `R/<verb>.R` or in the vendored test itself, and staged or committed;
the next run of the generator turns it into the patch file, and both are committed together.
A patch file is never edited by hand, since the next run rewrites it from the committed file.
A file that differs from its generated output carries a patch, and a file that does not carries none.

**What the patches typically hold.**
In `patch/`, the relational implementation inside `rel_try()`, its fallback conditions, and the roxygen tags around it
([`verbs/`](/handbook/verbs/README.md)).
In `patch-tests/`, adjustments that the skip lists cannot express,
such as a snapshot transform like `transform = scrub_hash` that scrubs a volatile value from an expected error.
A vendored test that should not run is skipped through the skip lists instead
([`vendored-tests/`](/handbook/dplyr-alignment/vendored-tests/README.md)).

**A patch file also decides how the generated tests run.**
For a verb tested with a single argument set, `tools/03-tests.R` keeps `DUCKPLYR_FORCE` on in its generated test,
and `tools/05-duckdb-tests.R` generates a `rel_api` test for it at all, only where `patch/<verb>.patch` exists,
since an unpatched method has no relational implementation;
`test_force_override` in [`tools/00-funs.R`](/tools/00-funs.R) overrides that per verb.

*To deepen: say how a patch that no longer applies after a dplyr change is best resolved, from the next sync that needs it.*
