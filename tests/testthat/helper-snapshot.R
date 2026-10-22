# Snapshot transform that scrubs plan details that differ between duckdb
# versions.
#
# duckdb >= 2.0.0 qualifies temporary tables as `"temp".main.<name>` and
# prints numeric constants with an explicit cast, e.g. `CAST(1.0 AS DOUBLE)`.
# Scrubbing both keeps these snapshots stable across duckdb 1.x and 2.x.
scrub_plan <- function(x) {
  x <- gsub('"temp"\\.main\\.', "", x)
  gsub("CAST\\(([^()]+) AS DOUBLE\\)", "\\1", x)
}
