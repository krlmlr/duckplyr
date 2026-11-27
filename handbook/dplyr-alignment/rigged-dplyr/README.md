---
status: draft
---

# The rigged dplyr

How a dplyr whose `data.frame` methods are duckplyr's own is built, rebased onto a new dplyr release, verified, and checked
against dplyr's reverse dependencies, which measures how compatible duckplyr's verbs are across the packages that use dplyr.
The clone it is built in is [`setup/`](/handbook/dplyr-alignment/setup/README.md)'s,
and the reverse-dependency checks of duckplyr itself are [`ci/`](/handbook/ci/README.md)'s.
The rig lives on the branch `f-revdep-duckplyr` of the fork [`krlmlr/dplyr`](https://github.com/krlmlr/dplyr).
What this page says about that branch, as opposed to this repository, was reported by the session that last ran the process,
and is not checked by anything here.

## Building it

**[`tools/90-patch-dplyr.R`](/tools/90-patch-dplyr.R) builds it in `.sync/dplyr-revdep` and pushes it.**
Run it with `source("tools/90-patch-dplyr.R", echo = TRUE)` from the package root of an up-to-date duckplyr checkout.
It refuses to start unless that clone is on `f-revdep-duckplyr` with a clean working tree, then pulls it, and:

* renames each of dplyr's `<verb>.data.frame` methods that duckplyr implements to `<verb>_data_frame`;
* copies every file under `R/` into the fork as one file, `R/zzz-duckplyr.R`,
  renaming each `<verb>.duckplyr_df` method to `<verb>.data.frame`
  and each call to `dplyr$<verb>.data.frame` to `<verb>_data_frame`;
* inserts `skip("TODO duckdb")` into dplyr's own tests from the skip lists `duckplyr_tests` and `dplyr_only_tests`
  ([`vendored-tests/`](/handbook/dplyr-alignment/vendored-tests/README.md));
* commits the result as `Sync with tidyverse/duckplyr@<sha>`, naming this repository's `HEAD`, and pushes it.

**The method names come from the installed dplyr.**
The script takes the verbs from `df_methods` in [`tools/00-funs.R`](/tools/00-funs.R), which reads the installed dplyr's namespace,
so the dplyr the rig is based on is installed before the script runs.

**Infrastructure files stay out, and the script keeps that list honest.**
The vector `forbidden` in the script names the files under `R/` that are not copied:
package infrastructure, the overwrite and restore machinery, the TPC-H code, and the development-only files.
The script stops when a file it names no longer exists, so renaming or removing one of them means updating the list,
and a new infrastructure file under `R/` is copied into dplyr until it is added there.

**The branch also carries pieces the script does not write, maintained there by hand.**

* `R/duckplyr.R` sets `dplyr_mode <- TRUE`, which the copied code reads,
  and defines no-op stubs for the recording and telemetry functions the copied code calls.
* `DESCRIPTION` carries a development version above dplyr's CRAN release, and duckplyr's extra imports.
* `NAMESPACE` stays dplyr's, and the branch is never re-documented with roxygen2.
* `.github/workflows/revdep4.yaml` differs from this repository's copy by the push trigger and the base image source below.

`src/` is dplyr's own, so the rig adds no compiled code.

## Rebasing onto a new dplyr release

The branch takes in dplyr's changes by merging a release tag of `tidyverse/dplyr`, never by a rebase or a force-push,
since the branch is published.

1. Add `https://github.com/tidyverse/dplyr` as the remote `upstream`, and fetch the release tag.
2. Merge the tag.
3. Resolve the conflicts by taking upstream's `R/` and `tests/` whole (`git checkout <tag> -- R tests`),
   which keeps the rig's own files under `R/`;
   taking upstream's `DESCRIPTION` and re-applying the version bump and the extra imports;
   and keeping the branch's own `revdep/` reports.
4. Commit the merge.
5. Install the dplyr release, and re-run `tools/90-patch-dplyr.R` to regenerate the renames, `R/zzz-duckplyr.R`, and the test skips.

## Verifying it locally

1. Build and install it into a separate library, under the R version the revdep run uses (its `r-version` input),
   since an older R misses what a newer one removed from its C API:
   `R CMD build --no-build-vignettes --no-manual`, then `R CMD INSTALL -l <lib>` on the tarball.
2. Smoke-test it: `dplyr:::stats$attempts` grows and `dplyr:::stats$fallback` stays at zero for supported verbs,
   and with `DUCKPLYR_FALLBACK_INFO=TRUE` an unsupported expression such as `paste0()` reports its fallback.
3. Run dplyr's tests against the installed rig with
   `testthat::test_dir("tests/testthat", package = "dplyr", load_package = "installed")`,
   and run the same tests against CRAN's dplyr to tell the rig's failures from the environment's.
   The rig's failures are mostly differences in error messages, call context, and snapshots.

## Checking dplyr's reverse dependencies

**The earlier route was the revdep cloud provided by Posit.**
The branch now runs its own workflow instead, described next.

**The branch runs its own copy of `revdep4.yaml`**, taken from this repository,
whose header comment explains the engine and why its sequential, one-container-per-package design replaced `revdep2.yaml`'s.

**A first push registers the workflow, because a dispatch needs a registered workflow.**
GitHub refuses to dispatch a workflow its default branch has never carried, and the fork's default branch is left alone.
So the branch's copy adds a `push` trigger limited to `f-revdep-duckplyr` and to the workflow file itself,
and gates its plan and base-image jobs, on which every other job depends, on `github.event_name == 'workflow_dispatch'`.
A push of the file makes a run with every job skipped, after which the workflow can be dispatched on `f-revdep-duckplyr`
by name or id, with `gh workflow run` or the REST dispatch endpoint.

**Dry-run first.**
The `dry-run` input stops after planning, and the log of the plan job says how many packages, check minutes, and shards
the chosen `which` and `depth` mean, and whether the set needs splitting with `part`.
The workflow file is the list of inputs.
The run of 2026-10-22 with `which = most` and `depth = 1` was
[39741480721](https://github.com/krlmlr/dplyr/actions/runs/39741480721), planned by the dry run
[39739520527](https://github.com/krlmlr/dplyr/actions/runs/39739520527).

**The base image is taken from `krlmlr/duckplyr`, because the fork's token cannot publish one.**
`GITHUB_TOKEN` is denied when the base-image job pushes a new package to the fork's GitHub container registry.
So the branch's copy sets `REVDEPX_BASE_REPO=ghcr.io/krlmlr/duckplyr/revdepx-base`, and the job reads the image from there.
The image's tag is derived from the content of the recipe it is built from, so the image published by `krlmlr/duckplyr` is the same image.
After the recipe in `cynkra/cynkratemplate` changes, the job fails until `krlmlr/duckplyr` has published the new tag,
which a `revdep4.yaml` run there does;
granting the fork's token write access to its registry package is the other way out, and an owner's setting.
The push of the universe image is denied too, which does no harm: the job also uploads it as an artifact, which the shards load.

**Reading the results.**
The `revdepx-report` artifact holds the revdepcheck-style report;
fetch it with `gh run download <run-id> --name revdepx-report -R krlmlr/dplyr`.
The collect job also commits the report into `revdep/` on the branch, so pull before pushing to it again.
A package reported as newly broken is a difference between duckplyr and dplyr to triage,
and one that failed to check is an infrastructure problem.
Broken packages never fail the run; only infrastructure failures do.

*To deepen: record the test results of the rebased rig and the triage of the newly broken packages as experiments.*
