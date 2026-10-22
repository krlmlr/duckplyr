---
status: draft
---

# The rigged dplyr

How a dplyr whose `data.frame` methods are duckplyr's own is built,
so that dplyr's reverse dependencies can be checked against duckplyr's behavior without depending on duckplyr.
The clone it is built in is [`setup/`](/handbook/dplyr-alignment/setup/README.md)'s,
and the reverse-dependency checks of duckplyr itself are [`ci/`](/handbook/ci/README.md)'s.

**[`tools/90-patch-dplyr.R`](/tools/90-patch-dplyr.R) builds it in `.sync/dplyr-revdep` and pushes it.**
Run it with `source("tools/90-patch-dplyr.R", echo = TRUE)` from the package root.
It refuses to start unless that clone is on the branch `f-revdep-duckplyr` with a clean working tree, then pulls it, and:

* renames each of dplyr's `<verb>.data.frame` methods that duckplyr implements to `<verb>_data_frame`;
* copies every file under `R/` into the fork as one file, `R/zzz-duckplyr.R`,
  renaming each `<verb>.duckplyr_df` method to `<verb>.data.frame`
  and each call to `dplyr$<verb>.data.frame` to `<verb>_data_frame`;
* inserts `skip("TODO duckdb")` into dplyr's own tests from the skip lists `duckplyr_tests` and `dplyr_only_tests`
  ([`vendored-tests/`](/handbook/dplyr-alignment/vendored-tests/README.md));
* commits the result as `Sync with tidyverse/duckplyr@<sha>`, naming this repository's `HEAD`, and pushes it to `krlmlr/dplyr`.

**Infrastructure files stay out, and the script keeps that list honest.**
The vector `forbidden` in the script names the files under `R/` that are not copied:
package infrastructure, the overwrite and restore machinery, the TPC-H code, and the development-only files.
The script stops when a file it names no longer exists, so renaming or removing one of them means updating the list,
and a new infrastructure file under `R/` is copied into dplyr until it is added there.

**What runs the checks is outside this repository.**
The script only publishes the branch.
The checks of dplyr's reverse dependencies against it are not run by any workflow here.

*To deepen: say where and how the reverse-dependency checks against `f-revdep-duckplyr` run,
how that branch takes in dplyr's own changes,
and where the fork defines `dplyr_mode`, which the copied code reads and the copy leaves out.*
