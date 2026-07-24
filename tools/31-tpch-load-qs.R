pkgload::load_all()

tables <- c(
  "lineitem",
  "partsupp",
  "part",
  "supplier",
  "nation",
  "orders",
  "customer",
  "region"
)

# Materialize each table with `dplyr::collect()` before saving.
# `read_parquet_duckdb()` returns a lazy, DuckDB-backed `duckplyr_df`.
# qs2 can round-trip such an object, but it comes back as a materialized data
# frame that still carries the `duckplyr_df` class and explicit row names.
# The benchmark script then calls `as_duckdb_tibble()` on it, which fails with
# "Need data frame without row names to convert to relational".
# Collecting to a plain tibble up front avoids this.
data <- lapply(tables, function(t) {
  dplyr::collect(
    duckplyr::read_parquet_duckdb(
      fs::path(
        "tools/tpch/001",
        paste0(t, ".parquet")
      ),
      prudence = "lavish"
    )
  )
})

qs2::qs_save(
  rlang::set_names(data, tables),
  file = "tools/tpch/001.qs",
  compress_level = 1,
  shuffle = FALSE
)

data <- lapply(tables, function(t) {
  dplyr::collect(
    duckplyr::read_parquet_duckdb(
      fs::path(
        "tools/tpch/010",
        paste0(t, ".parquet")
      ),
      prudence = "lavish"
    )
  )
})

qs2::qs_save(
  rlang::set_names(data, tables),
  file = "tools/tpch/010.qs",
  compress_level = 1,
  shuffle = FALSE
)

data <- lapply(tables, function(t) {
  dplyr::collect(
    duckplyr::read_parquet_duckdb(
      fs::path(
        "tools/tpch/100",
        paste0(t, ".parquet")
      ),
      prudence = "lavish"
    )
  )
})

qs2::qs_save(
  rlang::set_names(data, tables),
  file = "tools/tpch/100.qs",
  compress_level = 1,
  shuffle = FALSE
)
