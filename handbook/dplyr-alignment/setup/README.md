---
status: draft
---

# Setting up for a sync

The checkouts, tools, and packages the sync pipeline and the rigged dplyr need, set up once per clone of this repository.
Running the pipeline is [`sync/`](/handbook/dplyr-alignment/sync/README.md)'s.

**Two clones of dplyr live under `.sync/`.**
Both are clones of the fork [`krlmlr/dplyr`](https://github.com/krlmlr/dplyr), not of `tidyverse/dplyr`:

* `.sync/dplyr-main` tracks the fork's default branch.
  The method sources and the vendored tests are taken from it, and the scripts pull it before reading.
  That branch has had no commit since 2024-10, so a sync from it reads an old dplyr;
  whether this clone should track `tidyverse/dplyr`'s main branch or its latest release tag is not settled.
  On 2026-10-22 the fork's default branch was an ancestor of the tag `v1.2.1`, 130 commits behind it and with no commits of its own,
  and the vendored tests were taken from a detached checkout of that tag
  ([`vendored-tests/`](/handbook/dplyr-alignment/vendored-tests/README.md)).
  No process keeps the fork, or this clone, in step with `tidyverse/dplyr` yet; formalizing the sync is tracked in [krlmlr/duckplyr#37](https://github.com/krlmlr/duckplyr/issues/37).
* `.sync/dplyr-revdep` tracks the branch `f-revdep-duckplyr`, which carries the rigged dplyr
  ([`rigged-dplyr/`](/handbook/dplyr-alignment/rigged-dplyr/README.md)).
  Building it pushes to the fork, so this clone needs write access there.

```sh
cd .sync
git clone git@github.com:krlmlr/dplyr.git dplyr-main
git clone git@github.com:krlmlr/dplyr.git -b f-revdep-duckplyr dplyr-revdep --reference dplyr-main
```

`--reference` only saves the second download; any existing dplyr clone serves.
Git does not track either clone, and `.Rbuildignore` keeps `.sync/` out of the built package.

**One clone of duckdb-r lives beside this repository's parent.**
`tools/06-patch-duckdb.R` writes into `../../duckdb/duckdb-r` relative to the root of this checkout,
so a checkout at `<dir>/duckplyr` needs `duckdb/duckdb-r` cloned at `<dir>/../duckdb/duckdb-r`:

```sh
mkdir -p ../../duckdb
git -C ../../duckdb clone git@github.com:duckdb/duckdb-r.git
```

Only that script needs it, but `tools/99-sync.R` runs it before the overwrite step, so a sync without the clone stops there.

**The R packages are the development dependencies.**
`pak::pak(dependencies = "Config/Needs/development")` installs what `DESCRIPTION` declares for development,
which brings in most of what the scripts call.
`rex`, which only `tools/90-patch-dplyr.R` uses, is declared nowhere and is installed by hand.
Declaring `rex` and `constructive` as development dependencies is tracked in [krlmlr/duckplyr#38](https://github.com/krlmlr/duckplyr/issues/38).
`constructive` is not on CRAN, so it is installed from <https://cynkra.r-universe.dev> first.
Then `pak::local_install_dev_deps(upgrade = FALSE)` installs the rest without upgrading what is present.

**Two command-line tools must be on the path.**
The generators apply patch files with `patch`, and `tools/04-dplyr-tests.R` formats the vendored tests with `air`.

**The dplyr functions must carry their source references.**
`tools/02-duckplyr_df-methods.R` stops when they do not, since it reads each method's source as written.
Loading `.sync/dplyr-main` with `pkgload::load_all()`, as the scripts do, keeps them;
the comment at that check names the alternative, installing dplyr from source with `--with-keep.source`.

[`tools/clone.sh`](/tools/clone.sh) and [`tools/orbstack.sh`](/tools/orbstack.sh) script a fresh machine with these steps,
most of them commented out, and are a record of one maintainer's setup rather than a supported path.

*To deepen: verify the steps on a fresh clone.*
