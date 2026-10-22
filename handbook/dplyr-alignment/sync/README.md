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
later scripts load dplyr from `.sync/dplyr-main` and pull that clone first, except `tools/03-tests.R`, which reads the installed dplyr.
A generated `test-as_duckplyr_df.R` is stale until `tools/03-tests.R` runs against the dplyr being synced.
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
4. Do the same for `tools/04-dplyr-tests.R`, whose comment is `# Stop here to overwrite files if the test generation is updated`:
   run it up to the comment, commit the regenerated tests, and hand-edit a generated test where one needs it, committing that too.
   Then run the whole script, which collects the edits into `patch-tests/`, and amend the commit to include the patch.
5. Run the rest of the pipeline.

A new dplyr test file is vendored only once it has an entry in `duckplyr_tests`
([`vendored-tests/`](/handbook/dplyr-alignment/vendored-tests/README.md)), so add the entry before the first pass.
Running `tools/04-dplyr-tests.R` in full right after dplyr changes records a patch that reverts the upstream change.

**A detached checkout of a tag stops the pull.**
`gert::git_pull()` fails with "Repository is currently in a detached head state" on a tag.
Stubbing it in the session before sourcing the script avoids editing the scripts:
`utils::assignInNamespace("git_pull", function(...) invisible(NULL), "gert")`.

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

**The output of `tools/06-patch-duckdb.R` is meant to be committed to duckdb-r, ideally before each duckplyr release.**
The generated `test-rel_api.R` is not yet synced automatically, which [krlmlr/duckplyr#34](https://github.com/krlmlr/duckplyr/issues/34) tracks.
The two-pass procedure above is the maintainer's confirmed way of taking dplyr's changes in.
