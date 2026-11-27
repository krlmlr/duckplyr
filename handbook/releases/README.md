---
status: draft
---

# Cutting a patch release from a tag

How a patch release is cut from an earlier release tag instead of from the default branch,
when the default branch has moved on to changes that are not meant to ship.
The bounds the fix may need to move are [`dependencies/`](/handbook/dependencies/README.md)'s,
what the workflows named below check is [`ci/`](/handbook/ci/README.md)'s,
and the shared dispatch trick is [`dplyr-alignment/rigged-dplyr/`](/handbook/dplyr-alignment/rigged-dplyr/README.md)'s.
duckplyr 1.2.2 was cut this way from v1.2.1,
and [its record](/experiments/2026-10-22-patch-release-1.2.2/README.md) holds what that run did and what blocked it.

## Why it is done by hand

**fledge cannot release from a tag.**
`fledge::plan_release()` aborts off the default branch with "Must be on the main branch",
and releasing from a tag is not supported yet: `plan_release("last")` is a FIXME there.
So the version, the `NEWS.md` section, and the date are written by hand.

## The release branch

**The branch starts at the tag.**
The release branch branches from the earlier release tag, and its head becomes the new release tag.
It carries what the old tag lacks, in two groups, each a separate commit.

**CI and tooling are imported from the default branch as whole files, never as diffs.**
The old tag's workflows are not the ones that pass today, so these are copied over from the default branch:
all of `.github/`, the `.ccache` lines in `.gitignore` and `.Rbuildignore`, the touchstone scripts,
and `Config/gha/extra-packages` in `DESCRIPTION`.
Left out: `R/`, `man/`, `tests/`, `vignettes/`, `NEWS.md`, the README and site content,
and any tooling that needs files the old tag does not have, such as a `tools/04-dplyr-tests.R` that needs `patch-tests/`.
Importing the package sources would carry unreleased work into the release.

**The user-facing fix is cherry-picked with `-x`.**
`git cherry-pick -x` records the original commit in the message,
so the release and the default branch can be reconciled afterwards.
Snapshot fixes the fix needs follow as plain commits.
For 1.2.2 the fix was the support for duckdb 2.0.0:
the load guard in [`R/zzz.R`](/R/zzz.R) rejects duckdb 3.0.0 and later
([`dependencies/`](/handbook/dependencies/README.md) owns the guard).

## The release commits

* The version and its `NEWS.md` section, with fledge's marker comment removed from `NEWS.md`.
* Whatever keeps `R CMD check` clean against today's CRAN, such as dropping a suggested package that CRAN has archived.
  For 1.2.2 that was `constructive`: removed from `Suggests`, `R/construct_*.R` added to `.Rbuildignore`,
  and the methods registered on load.
  Reverting it is tracked in [krlmlr/duckplyr#42](https://github.com/krlmlr/duckplyr/issues/42).
* The dated `NEWS.md` heading and `Date:` in `DESCRIPTION`, in a last commit.

## Running the checks

**The release PR gets no `pull_request` CI.**
A branch from an old tag conflicts with the default branch, so `pull_request` CI does not run on the release PR.
Dispatch [`R-CMD-check.yaml`](/.github/workflows/R-CMD-check.yaml) on the branch with `-f ref=<branch>` instead.

**A workflow the default branch has never carried cannot be dispatched.**
The dispatch fails with HTTP 404.
The release workflows are on the default branch now, so a release branch whose `.github/` is imported from it can dispatch them.
A workflow that exists only on a release branch is registered through a one-off branch
whose copy adds a `push` trigger for that branch and guards every job with `github.event_name == 'workflow_dispatch'`,
the trick [`dplyr-alignment/rigged-dplyr/`](/handbook/dplyr-alignment/rigged-dplyr/README.md) describes for `revdep4.yaml`.

**The checks that gate the submission:**

* [`release-gate.yaml`](/.github/workflows/release-gate.yaml),
  whose soft job and Documentation job never fail by design, so their logs are read rather than their status;
* the `rcc` `R CMD check` and its versions matrix;
* [`winbuilder.yaml`](/.github/workflows/winbuilder.yaml) on R-devel, release, and oldrelease;
* [`revdep4.yaml`](/.github/workflows/revdep4.yaml) with `which=strong` and depth 1.

**`revdep4.yaml` commits its report back to the checked ref.**
Dispatch it with `ref=<sha>` rather than the branch name, so the head of the release branch stays the commit that was checked.

## Submitting and tagging

**[`cran-submission.yaml`](/.github/workflows/cran-submission.yaml) tags and drafts the GitHub release in the repository it runs in.**
It submits to CRAN,
and [`cran-release.yaml`](/.github/workflows/cran-release.yaml) publishes the draft once Posit's package manager serves the version.
Run in a fork, both leave the tag and the GitHub release in the fork.
The release workflows call the actions `cran-submit`, `cran-release`, and `release-report` under [`.github/actions/`](/.github/actions/),
and the scripts of the first two share the shell library in `cran-lib/`.

## After the release

**The release branch is merged back into the default branch**,
for the `NEWS.md` section, the version, and the fix,
and the default branch goes back to a development version with fledge's `NEWS.md` marker.
The generated `test-rel_api.R` is meant to be synced to duckdb-r before each release
([`dplyr-alignment/sync/`](/handbook/dplyr-alignment/sync/README.md)).

**A release cut in the fork reaches `tidyverse/duckplyr` by a fast-forward.**
A merge of `tidyverse/duckplyr`'s main into the fork's default branch is a commit
that `tidyverse/duckplyr`'s main can be fast-forwarded to.
The release tag and the GitHub release are then created in `tidyverse/duckplyr`.

## Current state

duckplyr 1.2.2 is on CRAN, and the fork's GitHub release v1.2.2 is published.
The release is merged back into the fork's default branch, which is at 1.2.2.9000.
`tidyverse/duckplyr` has not caught up yet:
its main has not been fast-forwarded, and its GitHub release v1.2.2 does not exist.
[krlmlr/duckplyr#48](https://github.com/krlmlr/duckplyr/pull/48) carries the catch-up:
a merge of `tidyverse/duckplyr`'s main into the fork's default branch, which `tidyverse/duckplyr`'s main can be fast-forwarded to.
[tidyverse/duckplyr#963](https://github.com/tidyverse/duckplyr/pull/963), the support for duckdb 2.0 proposed there,
is superseded by the release.

*To deepen: record the fast-forward of `tidyverse/duckplyr` and its GitHub release v1.2.2 once done; drain krlmlr/duckplyr#42.*
