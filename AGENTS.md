# AGENTS.md

Orienting doc for any AI coding agent landing in this repository.
Format: [agents.md](https://agents.md/).

_Everything this repository documents lives in [`handbook/`](/handbook/README.md), the single source of truth.
This page only routes there._

## What this repository is

duckplyr, the R package that runs dplyr verbs on data frames through DuckDB and falls back to dplyr where it cannot.
Much of `R/` and `tests/testthat/` is generated from dplyr by the scripts under `tools/`,
so read [`handbook/layout/`](/handbook/layout/README.md) before editing a file whose first line says it is generated.

## The first five minutes

- where a fact lives, and how the tree grows: [`handbook/meta/handbook/`](/handbook/meta/handbook/README.md)
- how a sentence is written here, before you write one: [`handbook/meta/authoring/`](/handbook/meta/authoring/README.md)
- what this repository decides for itself, and the rules it adopts beyond the shared ones:
  [`handbook/meta/local/`](/handbook/meta/local/README.md)
- the vocabulary this repository uses: [`handbook/meta/glossary/`](/handbook/meta/glossary/README.md)
- which files are generated, and by what: [`handbook/layout/`](/handbook/layout/README.md)
- how a manual edit to a generated method or vendored test survives regeneration:
  [`handbook/dplyr-alignment/patches/`](/handbook/dplyr-alignment/patches/README.md)
- how to run the tests: [`handbook/testing/`](/handbook/testing/README.md)

## Behaviour

- Every document outside `handbook/` either derives from it or backreferences it, and this page's italic line is its own.
  In Claude Code the prose rules load on their own when you touch a file carrying prose;
  run `/docs:check` after touching documentation.
- Never run the sync pipeline's generators to completion without reading what a full run does to uncommitted edits first
  ([`handbook/dplyr-alignment/sync/`](/handbook/dplyr-alignment/sync/README.md)): they check files out of git's index.
- Never edit `NEWS.md`, `README.md`, `man/`, or `NAMESPACE` by hand:
  [`handbook/meta/local/`](/handbook/meta/local/README.md) says what generates them.

---

_The shared pages under `handbook/meta/` point to their home, [`cynkra/handbook-tools`](https://github.com/cynkra/handbook-tools);
the rule file and the skills are carried from there unchanged,
and `.handbook-source` names the files and the state of the source this handbook was last checked against._
