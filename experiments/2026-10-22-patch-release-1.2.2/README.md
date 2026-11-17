# The duckplyr 1.2.2 patch release, cut from v1.2.1

*Measures: what cutting a patch release from an older release tag took, and which steps failed or were blocked.*

*Held on: 2026-10-22 to 2026-10-26, in the fork `krlmlr/duckplyr`, duckplyr 1.2.2 cut from the tag `v1.2.1`, duckdb 2.0.0.*

*Supports: [`releases/`](/handbook/releases/README.md), whose procedure generalizes this run.*

## Method

The release was prepared in [a Claude Code session](https://claude.ai/code/session_01Api82xbBopKwrTjdceqM6g).
The branches, the tag, and the commits below were read from the repository with `git fetch origin --tags` and `git show`.
What is said about the workflow runs and the permissions was reported by that session,
and nothing in this repository checks it.

## Findings

**The branch and the tag.**
`claude/release-1.2.2` branches from `v1.2.1` at
[`b8c0aed`](https://github.com/krlmlr/duckplyr/commit/b8c0aed),
and the tag `v1.2.2` is its head,
[`bec8e70`](https://github.com/krlmlr/duckplyr/commit/bec8e70).
The user-facing fix was the support for duckdb 2.0.0, cherry-picked with `-x`, followed by snapshot fixes for duckdb 2.0.
The release workflows `winbuilder`, `release-gate`, `cran-submission`, and `cran-release`,
and the actions `cran-lib`, `cran-submit`, `cran-release`, and `release-report` under `.github/actions/`,
were adapted from the branch `claude/rsqlite-cran-release` of r-dbi/RSQLite.
`cran-comments.md` and its `.Rbuildignore` line were deleted.
`constructive` was dropped, since it was archived on CRAN on 2026-09-27.
The vctrs factor-hash snapshots were accepted in three vendored dplyr test files,
the snapshots of `dplyr-all-equal`, `dplyr-bind-rows`, and `dplyr-case-when` under `tests/testthat/_snaps/`.

**`pull_request` CI did not run on the release pull request**, since the branch from the old tag conflicted with the default branch.
`R-CMD-check.yaml` was dispatched on the branch instead.

**The release workflows were registered through a one-off branch**, `claude/register-release-workflows`,
since a workflow the default branch has never carried cannot be dispatched (HTTP 404).

**The checks that gated the submission all passed**:
the release gate, `rcc` with its versions matrix, win-builder on R-devel, release, and oldrelease,
and `revdep4.yaml` with `which=strong` and depth 1, which checked 4 packages, all ok.

**An auto-mode permission classifier blocked two steps.**
The push that registered the workflows and the dispatch of the submission were refused
until the maintainer added explicit permission rules for them.

**`cran-submission.yaml` ran in the fork**, so the tag `v1.2.2` and the GitHub release v1.2.2 were created in `krlmlr/duckplyr`.
CRAN published duckplyr 1.2.2 on 2026-10-22, and the fork's GitHub release was published on 2026-10-26.

**The release was merged back** into the fork's default branch by
[krlmlr/duckplyr#41](https://github.com/krlmlr/duckplyr/pull/41),
which left it at version 1.2.2.9000 with fledge's `NEWS.md` marker in place.

**`test-rel_api.R` was not synced to duckdb-r before the release**,
although [`dplyr-alignment/sync/`](/handbook/dplyr-alignment/sync/README.md) says it is meant to be.

## Replicating

Follow [`releases/`](/handbook/releases/README.md) from the tag, in a fork, with the release workflows registered.
