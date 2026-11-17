# Glossary

The tree's recurring terms of art, one line each, every entry linking the leaf that owns the concept.
A term earns a line once a second leaf uses it, added by the change that reaches for it,
one line, so the register stays greppable and diffs per term.
The terms of the documentation system itself, leaf, scope sentence, deepen line, backreference, and the rest,
are defined once in the source's glossary,
[`cynkra/handbook-tools`](https://github.com/cynkra/handbook-tools/blob/main/handbook/meta/glossary/README.md),
and are not repeated here; this page holds this repository's own.

* **fallback**: running a verb through dplyr where DuckDB cannot ([`verbs/`](/handbook/verbs/README.md)).
* **helper clones**: the dplyr and duckdb-r checkouts a sync reads and writes
  ([`dplyr-alignment/setup/`](/handbook/dplyr-alignment/setup/README.md)).
* **patch file**: a diff recording a manual edit to a generated file
  ([`dplyr-alignment/patches/`](/handbook/dplyr-alignment/patches/README.md)).
* **rigged dplyr**: a dplyr fork with duckplyr's methods as its own
  ([`dplyr-alignment/rigged-dplyr/`](/handbook/dplyr-alignment/rigged-dplyr/README.md)).
* **skip list**: a list in `tools/00-funs.R` of vendored tests to skip
  ([`dplyr-alignment/vendored-tests/`](/handbook/dplyr-alignment/vendored-tests/README.md)).
* **sync pipeline**: the scripts that regenerate everything derived from dplyr
  ([`dplyr-alignment/sync/`](/handbook/dplyr-alignment/sync/README.md)).
* **vendored test**: a dplyr test file copied into duckplyr's suite
  ([`dplyr-alignment/vendored-tests/`](/handbook/dplyr-alignment/vendored-tests/README.md)).
