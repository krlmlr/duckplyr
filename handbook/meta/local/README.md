# What this repository decides

The choices the shared rules ([`meta/handbook/`](/handbook/meta/handbook/README.md)) leave open, answered for this repository,
and the rules it adopts beyond the shared ones.
This is the one page under `meta/` that answers for this repository;
the shared pages beside it point to their home, [`cynkra/handbook-tools`](https://github.com/cynkra/handbook-tools),
and [`.handbook-source`](/.handbook-source) names the state of the source this handbook was last checked against.

**Intent and status.**
Intent and status both live in the [issue tracker](https://github.com/tidyverse/duckplyr/issues) and in pull requests.
There is no plan directory, so a leaf describing a limitation links the issue that will remove it.

**Evidence.**
Measurements live under [`experiments/`](/experiments/README.md), in the shared shape, and the registry there names every record.
The benchmark results the TPC-H scripts write at the root are script output rather than records,
and [`benchmarks/`](/handbook/benchmarks/README.md) says what produces them.

**What this repository does not author.**
Generated code and tests, the vendored dplyr tests, and the dplyr method sources are written by the scripts under `tools/`,
and [`layout/`](/handbook/layout/README.md) names each generator and its output.
`man/` and `NAMESPACE` are roxygen2's, `README.md` and `index.md` are rendered from `README.Rmd`,
`NEWS.md` is maintained by [fledge](https://fledge.cynkra.com),
`tests/testthat/_snaps/` is testthat's, and `.github/CODE_OF_CONDUCT.md` is third-party text.
[`.handbook-ignore`](/.handbook-ignore) exempts the Markdown among them from the orphan check, with the reason beside each pattern.

**The comment budget.**
R code is formatted by [air](https://posit-dev.github.io/air/) with the line width [`air.toml`](/air.toml) sets,
and an R comment aims for it.
Shell scripts and workflow files have no formatter, and a comment in one aims for 80 columns.

**Who the text may name.**
The handbook names roles, such as the maintainer, rather than people.
`DESCRIPTION` and `NEWS.md` name people where their formats require it, and are not the handbook's to change.

**The language of the prose and of the domain.**
Prose is US English.
R function, package, and argument names keep their spelling as code, `summarise()` included.

**Rules adopted beyond the shared ones.**

* **No em dashes**, in prose and code alike.
  A comma, a colon, a semicolon, or a parenthesis says the same thing.
  The check reports one in any tracked file, and a commit message is review's to read.
  `tools/README.md` predates the rule and is exempt in `.handbook-ignore` until it is swept; the rule binds what is written from here on.

**Documents shipped without the tree.**
The built package (its help pages, vignettes, `README.md`, and `NEWS.md`) and the pkgdown site,
which also renders `.github/CONTRIBUTING.md`, reach readers who do not have the tree, so none of them links into it.
The leaves that own their topics point at them instead:
[`translations/`](/handbook/translations/README.md) at the contributing guide and at `vignettes/limits.Rmd`,
and [`verbs/`](/handbook/verbs/README.md) at the help page that lists the unsupported verbs.
`.Rbuildignore` keeps the handbook, the experiments, the agent files, the marker, and the ignore file out of the built package.

**Enforcement.**
[`.github/workflows/handbook.yaml`](/.github/workflows/handbook.yaml) runs the check script on every pull request,
and checks the carried files against the source in a second job.
