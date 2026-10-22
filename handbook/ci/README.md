---
status: draft
---

# Continuous integration

What the GitHub Actions workflows under [`.github/workflows/`](/.github/workflows/) check for this repository,
grouped by the question each answers, and what none of them checks.
How each workflow works is its own file's, whose header comment says why it is shaped as it is;
running the same tests locally is [`testing/`](/handbook/testing/README.md)'s.

**Most workflows come from a shared template.**
Their steps call composite actions from [`cynkra/cynkratemplate`](https://github.com/cynkra/cynkratemplate) at `@main`,
so a change in how a check runs usually lands there and reaches this repository without a change here.
The steps that run `./.github/workflows/custom/` actions are skipped, since this repository defines none.

**Does the package pass `R CMD check`?**

* [`R-CMD-check.yaml`](/.github/workflows/R-CMD-check.yaml), named `rcc`, checks every pull request to the default branch,
  pushes to the default, release, and `cran-*` branches, the merge queue, and a nightly run.
  Before the check it restyles the code, updates the snapshots, re-documents the package, and re-renders the README,
  and commits the result where it may push, so a commit may arrive on a branch after it is pushed.
  [`R-CMD-check-status.yaml`](/.github/workflows/R-CMD-check-status.yaml) reports its result as a commit status.
  [`commit-suggest.yaml`](/.github/workflows/commit-suggest.yaml) posts the formatting it would have committed on a pull request,
  and [`format-suggest.yaml`](/.github/workflows/format-suggest.yaml) suggests formatting on pull requests from forks.
* [`R-CMD-check-dev.yaml`](/.github/workflows/R-CMD-check-dev.yaml), named `rcc dev`, checks daily,
  and on `cran-*` branches and version tags, against the development version of each dependency in turn.
* [`rhub.yaml`](/.github/workflows/rhub.yaml) runs the CRAN check flavors `rcc` does not cover, on `cran-*` branches and on demand.

**Does a new duckplyr break the packages that depend on it?**
[`revdep.yaml`](/.github/workflows/revdep.yaml) runs on a push to a `revdep*` branch,
and [`revdep2.yaml`](/.github/workflows/revdep2.yaml) and [`revdep4.yaml`](/.github/workflows/revdep4.yaml) run on demand;
all three check duckplyr's CRAN reverse dependencies against the development version.
`pkg_review()` in [`R/revdep.R`](/R/revdep.R), which is not part of the built package,
clones one of them under `.sync/cran/` for a closer look.
dplyr's reverse dependencies run against duckplyr through the rigged dplyr instead,
which no workflow here checks ([`dplyr-alignment/rigged-dplyr/`](/handbook/dplyr-alignment/rigged-dplyr/README.md)).

**Is the generated code current?**
No workflow runs the sync pipeline or compares its output with the committed files,
so generated code drifts from its generators silently until the next manual sync.

**Everything else.**
[`pkgdown.yaml`](/.github/workflows/pkgdown.yaml) builds the website from `docs*` and `cran-*` branches,
as `rcc` does from the default branch;
[`fledge.yaml`](/.github/workflows/fledge.yaml) bumps the development version and `NEWS.md` daily;
[`lock.yaml`](/.github/workflows/lock.yaml) locks stale issue threads;
and [`handbook.yaml`](/.github/workflows/handbook.yaml) checks this handbook ([`meta/local/`](/handbook/meta/local/README.md)).

*To deepen: verify the triggers against recent runs, and say which `rcc` jobs a pull request from a fork skips.*
