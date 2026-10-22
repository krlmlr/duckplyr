---
status: draft
---

# Cutting a patch release from a tag

How a patch release is cut from an earlier release tag instead of from the default branch,
when the default branch has moved on to changes that are not meant to ship.
The one run so far is duckplyr 1.2.2 of 2026-10-22, cut from v1.2.1, and this page describes what that run did.
The bounds the fix may need to move are [`dependencies/`](/handbook/dependencies/README.md)'s,
what the workflows named below check is [`ci/`](/handbook/ci/README.md)'s,
and the shared dispatch trick is [`dplyr-alignment/rigged-dplyr/`](/handbook/dplyr-alignment/rigged-dplyr/README.md)'s.

**What is checked here, and what is reported.**
The branches, the tag, and the commits named below were read from the repository with `git fetch origin --tags` and `git show`.
Everything about the tooling's behavior, the workflow runs, the permissions, and the open decisions was reported by
[the release session](https://claude.ai/code/session_01Api82xbBopKwrTjdceqM6g), and nothing in this repository checks it.

## Why it was done by hand

**fledge cannot release from a tag.**
`fledge::plan_release()` aborts off the default branch with "Must be on the main branch",
and releasing from a tag is not supported yet: `plan_release("last")` is a FIXME there.
So the version, the `NEWS.md` section, and the date were written by hand.

## The release branch

**The branch starts at the tag.**
`claude/release-1.2.2` branches from v1.2.1 (`b8c0aed`), and the tag v1.2.2 is its head, `bec8e70`.
The branch has to carry what the old tag lacks, in two groups, each a separate commit.

**CI and tooling are imported from the default branch as whole files, never as diffs.**
The old tag's workflows are not the ones that pass today, so these were copied over from the default branch:
all of `.github/`, the `.ccache` lines in `.gitignore` and `.Rbuildignore`, the touchstone scripts,
and `Config/gha/extra-packages` in `DESCRIPTION`.
Left out: `R/`, `man/`, `tests/`, `vignettes/`, `NEWS.md`, the README and site content, `cran-comments.md`,
and the newer `tools/04-dplyr-tests.R`, which needs the `patch-tests/` directory the old tag does not have.
Importing the package sources would carry unreleased work into the release.

**The user-facing fix is cherry-picked with `-x`.**
The fix of this run was support for duckdb 2.0.0: the load guard in [`R/zzz.R`](/R/zzz.R) rejects duckdb 3.0.0 and later
([`dependencies/`](/handbook/dependencies/README.md) owns the guard).
`git cherry-pick -x` records the original commit in the message, so the release and the default branch can be reconciled afterwards.
Snapshot fixes for duckdb 2.0 followed as plain commits.

## The release commits

* The version 1.2.2 and its `NEWS.md` section, with fledge's marker comment removed from `NEWS.md`,
  and `cran-comments.md` and its `.Rbuildignore` line deleted.
* The release workflows `winbuilder`, `release-gate`, `cran-submission`, and `cran-release`,
  and the actions `cran-lib`, `cran-submit`, `cran-release`, and `release-report` under `.github/actions/`,
  adapted, as reported, from `claude/rsqlite-cran-release` of r-dbi/RSQLite.
  They are not in [`ci/`](/handbook/ci/README.md)'s list, since the default branch does not carry them.
* `constructive` dropped, because it was archived on CRAN on 2026-09-27:
  removed from `Suggests`, `R/construct_*.R` added to `.Rbuildignore`, and the methods registered on load.
  Reverting it is tracked in [krlmlr/duckplyr#42](https://github.com/krlmlr/duckplyr/issues/42).
* The vctrs factor-hash snapshots accepted in three vendored dplyr test files.
* The dated `NEWS.md` heading and `Date:` in `DESCRIPTION`, both 2026-10-22, in a last commit.

## Running the checks

**The release PR gets no `pull_request` CI.**
A branch from an old tag conflicts with the default branch, so, as reported, `pull_request` CI never runs on the release PR.
Dispatch [`R-CMD-check.yaml`](/.github/workflows/R-CMD-check.yaml) on the branch with `-f ref=<branch>` instead.

**A workflow that exists only on a non-default branch cannot be dispatched.**
The dispatch fails with HTTP 404.
The run registered the release workflows through a one-off branch whose copies add a `push` trigger for that branch
and guard every job with `github.event_name == 'workflow_dispatch'`,
the trick [`dplyr-alignment/rigged-dplyr/`](/handbook/dplyr-alignment/rigged-dplyr/README.md) describes for `revdep4.yaml`.
The branch `claude/register-release-workflows` is that one-off branch.

**The checks that gated the submission:**

* the release gate, whose soft job and Documentation job never fail by design, so their logs are read rather than their status;
* the `rcc` `R CMD check` and its versions matrix;
* win-builder on R-devel, release, and oldrelease;
* [`revdep4.yaml`](/.github/workflows/revdep4.yaml) with `which=strong` and depth 1, which checked 4 packages, all ok.

**`revdep4.yaml` commits its report back to the checked ref.**
Dispatch it with `ref=<sha>` rather than the branch name, so the head of the release branch stays the commit that was checked.

## Submitting and tagging

**`cran-submission.yaml` tags and drafts the GitHub release in the repository it runs in.**
It was run in the fork `krlmlr/duckplyr`, so the tag v1.2.2 and the draft release live there,
and have to be moved or recreated in `tidyverse/duckplyr`.

**An auto-mode permission classifier blocked two steps.**
The push that registered the workflows and the dispatch of the submission were refused
until the maintainer added explicit permission rules for them.

## After the release

These are open, and the maintainer's to decide:

* Merging the release back into the default branch, for the `NEWS.md` section and the version.
* Whether to restore fledge's `NEWS.md` marker or to bump the default branch by hand to 1.2.2.9000.
* `fledge::post_release()` was not run.
* The release PR [krlmlr/duckplyr#41](https://github.com/krlmlr/duckplyr/pull/41) is open.

The release went out without syncing `test-rel_api.R` to duckdb-r, which
[`dplyr-alignment/sync/`](/handbook/dplyr-alignment/sync/README.md) says is meant to happen before each release.

*To deepen: record the outcome of the CRAN submission, and the resolution of the open decisions above; drain krlmlr/duckplyr#42.*
