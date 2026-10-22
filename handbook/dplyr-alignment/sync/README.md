---
status: draft
---

# Running the sync pipeline

How the scripts that regenerate everything derived from dplyr are run, what a run leaves in the working tree,
and how its result is reviewed before it is committed.
The checkouts it needs are [`setup/`](/handbook/dplyr-alignment/setup/README.md)'s,
and what each script reads and writes is the per-script reference in [`tools/README.md`](/tools/README.md).

**[`tools/99-sync.R`](/tools/99-sync.R) is the entry point, and the order of its `source()` calls is the pipeline.**
Run it from the package root in a fresh R session, as `source("tools/99-sync.R", echo = TRUE)`.
The first script it runs, `tools/80-unsupported.R`, uses whichever dplyr is installed;
every later one loads dplyr from `.sync/dplyr-main`, and the scripts that read dplyr pull that clone first.
Run it after dplyr changes, and after a change to the code generation itself.

**A full run of the two patched generators changes patch files, not the files they patch.**
`tools/02-duckplyr_df-methods.R` and `tools/04-dplyr-tests.R` write their output, apply the patch files,
and then compare each output file with what git has staged or committed.
Where the two differ, they rewrite the patch file so that it turns the fresh output into the committed file,
and restore the committed file ([`patches/`](/handbook/dplyr-alignment/patches/README.md) owns the mechanism).
So a full run never brings a change from dplyr into `R/<verb>.R` or into a vendored test:
it folds the difference into the patch file, and a dplyr change ends up recorded as a manual edit that undoes it.
`tools/02-duckplyr_df-methods.R` also deletes untracked files under `R/` before that step, which removes the method file of a new verb.

**Taking dplyr's changes in is therefore a two-pass run.**

1. Run the pipeline up to `tools/02-duckplyr_df-methods.R`, and run that script only as far as its comment
   `# Stop here to overwrite files if the code generation is updated`.
   `R/` then holds the fresh output with the existing patches applied, new verbs included.
2. Review the diff of `R/` and `dplyr-methods/`, resolve every hunk that failed to apply, and stage the result.
3. Run the whole script again, which rewrites the patch files against the new output and leaves the staged files as they are.
4. Do the same for `tools/04-dplyr-tests.R`, whose comment is `# Stop here to overwrite files if the test generation is updated`.
5. Run the rest of the pipeline.

**Every other generator overwrites its output outright.**
The method sources under `dplyr-methods/`, the generated tests `test-as_duckplyr_df.R` and `test-rel_api.R`,
`R/overwrite.R`, `R/restore.R`, `R/not-supported.R`, and the TPC-H peel output are rewritten whole,
so their diff is what dplyr or the generator changed, and a manual edit to any of them is lost.

**Reviewing the result.**
A hunk that no longer applies is reported by `patch` on the console, and leaves a `.rej` file beside its target.
`git status` and `git diff` over `R/`, `dplyr-methods/`, `patch/`, `patch-tests/`, and `tests/testthat/` show the rest.
A changed method source under `dplyr-methods/` is the signal to read the matching `R/<verb>.R`,
whose relational code may need the same change ([`verbs/`](/handbook/verbs/README.md)).
A vendored test that fails is either fixed in `R/` or skipped with a reason
([`vendored-tests/`](/handbook/dplyr-alignment/vendored-tests/README.md)).
Then run the tests ([`testing/`](/handbook/testing/README.md)) and commit the regenerated files with the patches.

*To deepen: confirm the two-pass procedure with the maintainer,
and say whether `tools/06-patch-duckdb.R`'s output is committed to duckdb-r by hand.*
